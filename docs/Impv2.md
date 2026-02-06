# BudgetWise v2 Implementation Plan — Item Detail Page

## Overview

**Goal:** When a user taps an item inside a category (e.g., "Mosque" under "Charity"), they should land on a dedicated Item Detail page that shows **only the transactions for that specific item**, along with a budget summary (actual vs projected).

**Why:** Currently users can see category-level detail but cannot drill into individual items. This makes it hard to understand where money is going within a category.

---

## Prerequisites — Read Before You Code

Before writing a single line of code, read and understand these files:

| File | Why |
|------|-----|
| `CLAUDE.md` (project root) | Engineering rules and guardrails — **you MUST follow these** |
| `lib/screens/expenses/category_detail_screen.dart` | Your **reference implementation** — the Item Detail page mirrors this structure |
| `lib/providers/category_provider.dart` (lines 53-77) | Shows how `categoryByIdProvider` calculates actuals from transactions — you must follow this exact pattern |
| `lib/providers/transaction_provider.dart` (lines 32-36) | `transactionsByItemProvider` already exists — **do NOT recreate it** |
| `lib/providers/item_provider.dart` | `itemByIdProvider` exists but is **broken** (doesn't calculate actuals) — you must fix it |
| `lib/config/routes.dart` | Understand the route nesting before adding new routes |
| `lib/models/item.dart` | Item model with computed getters (`isOverBudget`, `progressPercentage`, `status`, `remaining`) |

---

## Files to Modify (4 files)

### File 1: `lib/providers/item_provider.dart`
### File 2: `lib/config/routes.dart`
### File 3: `lib/screens/expenses/item_detail_screen.dart` (NEW)
### File 4: `lib/screens/expenses/category_detail_screen.dart`

---

## Step-by-Step Implementation

---

### STEP 1: Fix `itemByIdProvider` to Calculate Actuals

**File:** `lib/providers/item_provider.dart`

**Problem:** The current `itemByIdProvider` (lines 21-25) fetches an item from the database, but the `actual` field comes back as `0` because **actuals are NEVER stored in the database** — they are calculated at runtime by summing transactions. (See `CLAUDE.md` Section 3.)

**What to do:**

1. Add these imports at the top of the file:
```dart
import '../models/transaction.dart';
import '../services/transaction_service.dart';
```

2. Add a private transaction service provider (same pattern as `category_provider.dart`):
```dart
/// Transaction service provider (for calculating actuals)
final _txServiceProvider = Provider<TransactionService>((ref) {
  return TransactionService();
});
```

3. Replace the existing `itemByIdProvider` with this version that calculates actuals:

```dart
/// Get a single item by ID (with calculated actual from transactions)
final itemByIdProvider =
    FutureProvider.family<Item?, String>((ref, itemId) async {
  final service = ref.read(itemServiceProvider);
  final transactionService = ref.read(_txServiceProvider);

  final item = await service.getItemById(itemId);
  if (item == null) return null;

  // Fetch transactions for this item and calculate actual
  final transactions = await transactionService.getTransactionsForItem(itemId);
  final actual = transactions
      .where((tx) => tx.type == TransactionType.expense)
      .fold<double>(0.0, (sum, tx) => sum + tx.amount);

  return item.copyWith(actual: actual);
});
```

**Why this matters:** Without this fix, the Item Detail page would show `£0 / £50` even when there are transactions. This is the **#1 bug source** in this codebase.

---

### STEP 2: Add the Route

**File:** `lib/config/routes.dart`

1. Add the import at the top (after the existing `category_detail_screen.dart` import on line 13):
```dart
import '../screens/expenses/item_detail_screen.dart';
```

2. Inside the `category/:id` route (currently at line 144), add a nested child route. The existing code looks like:

```dart
GoRoute(
  path: 'category/:id',
  name: 'category',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return CategoryDetailScreen(categoryId: id);
  },
),
```

Change it to:

```dart
GoRoute(
  path: 'category/:id',
  name: 'category',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return CategoryDetailScreen(categoryId: id);
  },
  routes: [
    GoRoute(
      path: 'item/:itemId',
      name: 'item-detail',
      builder: (context, state) {
        final categoryId = state.pathParameters['id']!;
        final itemId = state.pathParameters['itemId']!;
        return ItemDetailScreen(
          categoryId: categoryId,
          itemId: itemId,
        );
      },
    ),
  ],
),
```

**Result:** The full URL path will be `/budget/category/<categoryId>/item/<itemId>`

---

### STEP 3: Create the Item Detail Screen (NEW FILE)

**File:** `lib/screens/expenses/item_detail_screen.dart`

This is the largest step. The screen mirrors `CategoryDetailScreen` in structure.

#### 3.1 — Screen Structure

```
ItemDetailScreen (ConsumerWidget)
├── SliverAppBar (colored header using parent category's color)
│   ├── Back button
│   ├── Menu (Edit Item / Delete Item)
│   └── FlexibleSpaceBar
│       ├── Item name + status badge
│       └── Summary card (actual/projected, progress bar, remaining text)
├── SliverToBoxAdapter: "Transactions" section title with count
├── SliverList: Transaction cards grouped by date
│   └── Each card: amount, note, date, swipe-to-delete
├── Empty state (if no transactions)
└── FloatingActionButton: "Add Transaction"
```

#### 3.2 — Full Code

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../models/item.dart';
import '../../models/transaction.dart';
import '../../providers/providers.dart';
import '../../widgets/budget/budget_widgets.dart';
import '../transactions/transaction_form_sheet.dart';
import 'item_form_sheet.dart';

class ItemDetailScreen extends ConsumerWidget {
  final String categoryId;
  final String itemId;

  const ItemDetailScreen({
    super.key,
    required this.categoryId,
    required this.itemId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(itemByIdProvider(itemId));
    final transactionsAsync = ref.watch(transactionsByItemProvider(itemId));
    final categoryAsync = ref.watch(categoryByIdProvider(categoryId));
    final currencySymbol = ref.watch(currencySymbolProvider);

    return itemAsync.when(
      data: (item) {
        if (item == null) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: const Center(child: Text('Item not found')),
          );
        }

        final category = categoryAsync.value;
        final categoryColor = category?.colorValue ?? AppColors.primary;
        final transactions = transactionsAsync.value ?? [];

        return _buildScreen(
          context, ref, item, transactions, categoryColor, currencySymbol,
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildScreen(
    BuildContext context,
    WidgetRef ref,
    Item item,
    List<Transaction> transactions,
    Color categoryColor,
    String currencySymbol,
  ) {
    // Group transactions by date (newest first)
    final grouped = <DateTime, List<Transaction>>{};
    for (final tx in transactions) {
      final key = DateTime(tx.date.year, tx.date.month, tx.date.day);
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(itemByIdProvider(itemId));
          ref.invalidate(transactionsByItemProvider(itemId));
        },
        child: CustomScrollView(
          slivers: [
            // ── HEADER ──
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              leading: IconButton(
                icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(LucideIcons.moreVertical, color: Colors.white),
                  color: AppColors.surface,
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditItemSheet(context, ref, item);
                      case 'delete':
                        _showDeleteItemConfirmation(context, ref, item);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(LucideIcons.pencil, size: 18),
                          SizedBox(width: 8),
                          Text('Edit Item'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(LucideIcons.trash2, size: 18, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Delete Item', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              backgroundColor: categoryColor,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: categoryColor,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, kToolbarHeight, AppSpacing.md, AppSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Item name + status badge
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              _buildStatusBadge(item),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          // Budget summary
                          _buildSummaryCard(item, currencySymbol),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── TRANSACTIONS TITLE ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Transactions', style: AppTypography.h3),
                    Text(
                      '${transactions.length} ${transactions.length == 1 ? 'transaction' : 'transactions'}',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
            ),

            // ── TRANSACTIONS LIST or EMPTY STATE ──
            if (transactions.isEmpty)
              SliverToBoxAdapter(child: _buildEmptyState(context, ref))
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final date = sortedDates[index];
                      final dayTransactions = grouped[date]!;
                      return _buildDateGroup(
                        context, ref, date, dayTransactions, currencySymbol,
                      );
                    },
                    childCount: sortedDates.length,
                  ),
                ),
              ),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      // ── FAB: Add Transaction ──
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransactionSheet(context, ref),
        backgroundColor: categoryColor,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text('Add Transaction', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // ── Summary Card (actual / projected / progress) ──
  Widget _buildSummaryCard(Item item, String currencySymbol) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$currencySymbol${item.actual.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              ' / $currencySymbol${item.projected.toStringAsFixed(0)}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 18, fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        BudgetProgressBar(
          projected: item.projected,
          actual: item.actual,
          color: Colors.white,
          backgroundColor: Colors.white.withValues(alpha: 0.3),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          item.isOverBudget
              ? '$currencySymbol${(item.actual - item.projected).toStringAsFixed(0)} over budget'
              : '$currencySymbol${item.remaining.toStringAsFixed(0)} remaining',
          style: TextStyle(
            color: item.isOverBudget
                ? Colors.red.shade200
                : Colors.white.withValues(alpha: 0.8),
            fontSize: 14, fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Status Badge ──
  Widget _buildStatusBadge(Item item) {
    final label = item.status;
    final Color color;
    switch (label) {
      case 'Over budget':
        color = AppColors.error;
      case 'On budget':
      case 'Under budget':
        color = AppColors.success;
      default:
        color = AppColors.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppSizing.radiusFull),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ── Date Group (date header + transactions for that day) ──
  Widget _buildDateGroup(
    BuildContext context,
    WidgetRef ref,
    DateTime date,
    List<Transaction> transactions,
    String currencySymbol,
  ) {
    final dateLabel = DateFormat('EEEE, d MMM yyyy').format(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
          child: Text(dateLabel, style: AppTypography.bodySmall),
        ),
        ...transactions.map((tx) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: _buildTransactionCard(context, ref, tx, currencySymbol),
        )),
      ],
    );
  }

  // ── Single Transaction Card ──
  Widget _buildTransactionCard(
    BuildContext context,
    WidgetRef ref,
    Transaction tx,
    String currencySymbol,
  ) {
    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        ),
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      confirmDismiss: (direction) => _confirmDeleteTransaction(context, tx),
      onDismissed: (_) {
        ref.read(transactionNotifierProvider.notifier).deleteTransaction(tx.id);
        ref.invalidate(itemByIdProvider(itemId));
        ref.invalidate(transactionsByItemProvider(itemId));
        ref.invalidate(categoryByIdProvider(categoryId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction deleted')),
        );
      },
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$currencySymbol${tx.amount.toStringAsFixed(2)}',
                    style: AppTypography.labelLarge,
                  ),
                  if (tx.note != null && tx.note!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        tx.note!,
                        style: AppTypography.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            // Edit button
            IconButton(
              icon: const Icon(LucideIcons.pencil, size: 16, color: AppColors.textSecondary),
              onPressed: () => _showEditTransactionSheet(context, ref, tx),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty State ──
  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.receipt,
            size: 48,
            color: AppColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text('No transactions yet', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Add a transaction to start tracking spending for this item',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: () => _showAddTransactionSheet(context, ref),
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('Add Transaction'),
          ),
        ],
      ),
    );
  }

  // ── Actions ──

  void _showAddTransactionSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TransactionFormSheet(),
    ).then((_) {
      // Refresh data after form closes
      ref.invalidate(transactionsByItemProvider(itemId));
      ref.invalidate(itemByIdProvider(itemId));
      ref.invalidate(categoryByIdProvider(categoryId));
      ref.invalidate(categoriesProvider);
    });
  }

  void _showEditTransactionSheet(BuildContext context, WidgetRef ref, Transaction tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionFormSheet(transaction: tx),
    ).then((_) {
      ref.invalidate(transactionsByItemProvider(itemId));
      ref.invalidate(itemByIdProvider(itemId));
      ref.invalidate(categoryByIdProvider(categoryId));
      ref.invalidate(categoriesProvider);
    });
  }

  void _showEditItemSheet(BuildContext context, WidgetRef ref, Item item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ItemFormSheet(categoryId: categoryId, item: item),
    ).then((_) {
      ref.invalidate(itemByIdProvider(itemId));
      ref.invalidate(categoryByIdProvider(categoryId));
    });
  }

  Future<void> _showDeleteItemConfirmation(
    BuildContext context, WidgetRef ref, Item item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Item?'),
        content: Text(
          'This will delete "${item.name}" and all its transactions. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(itemNotifierProvider(categoryId).notifier).deleteItem(item.id);
      if (context.mounted) {
        Navigator.of(context).pop(); // Go back to category detail
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.name} deleted')),
        );
      }
    }
  }

  Future<bool> _confirmDeleteTransaction(BuildContext context, Transaction tx) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Transaction?'),
        content: Text(
          'Delete this ${tx.amount.toStringAsFixed(2)} transaction? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }
}
```

#### 3.3 — Key Points About This Code

- **Two providers watched:** `itemByIdProvider(itemId)` for the item data + `transactionsByItemProvider(itemId)` for the transaction list
- **Parent category color** comes from `categoryByIdProvider(categoryId)` — needed for the header gradient
- **Currency** comes from `currencySymbolProvider` — NEVER hardcode a currency symbol
- **Transactions grouped by date** — same pattern as the main TransactionsScreen
- **After mutations (add/edit/delete transaction):** invalidate `transactionsByItemProvider`, `itemByIdProvider`, `categoryByIdProvider`, and `categoriesProvider`

---

### STEP 4: Make Item Cards Tappable in CategoryDetailScreen

**File:** `lib/screens/expenses/category_detail_screen.dart`

1. Add the GoRouter import at the top:
```dart
import 'package:go_router/go_router.dart';
```

2. In the `_buildItemCard` method, wrap the existing `Container` (the card body, currently the `child` of the `Dismissible` widget) with a `GestureDetector` that navigates to the item detail:

Find this line (around line 319):
```dart
child: Container(
  padding: AppSpacing.cardPadding,
  decoration: BoxDecoration(
```

Wrap the entire Container with:
```dart
child: GestureDetector(
  onTap: () {
    context.push('/budget/category/${category.id}/item/${item.id}');
  },
  child: Container(
    padding: AppSpacing.cardPadding,
    decoration: BoxDecoration(
    // ... rest of existing code unchanged ...
  ),
),
```

**Important:** The `GestureDetector` wraps the `Container` that is the `child` of the `Dismissible`. Do NOT wrap the `Dismissible` itself — that would break swipe-to-delete.

---

## Guardrails — What Can Go Wrong

### CRITICAL: Actuals Showing as Zero

**Risk:** If you skip Step 1 (fixing `itemByIdProvider`), the Item Detail header will show `£0 / £50` even when transactions exist.

**Why:** The `actual` field is NEVER stored in the database. It must be calculated by summing transactions at runtime. See `CLAUDE.md` Section 3.

**How to verify:** After implementing, open an item that has transactions. The actual amount in the header MUST match the sum of the visible transactions.

### CRITICAL: Provider Invalidation After Mutations

**Risk:** User deletes a transaction but the header still shows the old actual amount.

**Why:** You forgot to invalidate the `itemByIdProvider` after mutation.

**Rule:** After ANY transaction mutation (add/edit/delete), invalidate ALL of these:
```dart
ref.invalidate(transactionsByItemProvider(itemId));   // Transaction list
ref.invalidate(itemByIdProvider(itemId));              // Item actual recalculation
ref.invalidate(categoryByIdProvider(categoryId));      // Parent category totals
ref.invalidate(categoriesProvider);                    // Global category list
```

Missing even one of these will cause stale data somewhere in the app.

### IMPORTANT: Route Nesting

**Risk:** The item detail page renders without bottom navigation.

**Why:** If you place the route outside the `ShellRoute`, it won't have the `AppShell` wrapper.

**Rule:** The item route MUST be nested under `/budget/category/:id/item/:itemId` — inside the existing shell route tree. Follow Step 2 exactly.

### IMPORTANT: Don't Recreate Existing Providers

**Risk:** Creating a duplicate `transactionsByItemProvider` or modifying the transaction service.

**Why:** `transactionsByItemProvider` already exists at `transaction_provider.dart:32-36` and works correctly. The `TransactionService.getTransactionsForItem()` method already exists and works.

**Rule:** Use what already exists. Do NOT create new providers or service methods for fetching item transactions.

### IMPORTANT: Currency Symbols

**Risk:** Hardcoding `£` or `$` in the new screen.

**Rule:** Always use `ref.watch(currencySymbolProvider)`. See `CLAUDE.md` Section 6.3.

### MODERATE: Navigation from Item Cards

**Risk:** Tapping the Edit/Delete buttons on an item card in CategoryDetailScreen navigates to item detail instead.

**Why:** Tap events bubble up from the Edit/Delete buttons to the parent `GestureDetector`.

**Solution:** The existing code already has `GestureDetector(behavior: HitTestBehavior.opaque, onTap: () {})` wrapping the action buttons row (line 366-369). This consumes taps and prevents bubbling. **Do NOT remove this.**

### MODERATE: Back Navigation

**Risk:** Using `context.go()` instead of `context.push()` for navigation, which replaces the route stack.

**Rule:** Use `context.push()` from CategoryDetailScreen to ItemDetailScreen. Use `Navigator.of(context).pop()` for the back button. This preserves the navigation stack so the user can go back.

---

## Testing Checklist

After implementation, verify each of these scenarios:

- [ ] **Navigate:** From CategoryDetailScreen, tap an item card → Item Detail opens
- [ ] **Header data:** Actual amount matches the sum of displayed transactions
- [ ] **Transactions:** Only transactions for this specific item are shown (not the whole category)
- [ ] **Empty state:** Item with no transactions shows empty state message
- [ ] **Add transaction:** Tap FAB → form opens → save → transaction appears in list, actual updates
- [ ] **Edit transaction:** Tap edit icon → form opens with pre-filled data → save → list and actual update
- [ ] **Delete transaction (swipe):** Swipe left → confirmation → transaction removed, actual updates
- [ ] **Edit item:** Menu → Edit Item → form opens → save → header updates
- [ ] **Delete item:** Menu → Delete Item → confirmation → navigates back to category
- [ ] **Back navigation:** Back arrow returns to CategoryDetailScreen
- [ ] **Pull to refresh:** Pull down refreshes transaction list and actual amounts
- [ ] **Currency:** Correct currency symbol shown (not hardcoded)
- [ ] **Over budget:** If actual > projected, shows "over budget" state with red styling
- [ ] **Category color:** Header uses the parent category's color
- [ ] **Bottom nav:** Bottom navigation bar is visible on this screen

---

## What NOT to Do

1. **Do NOT add new database columns** — no schema changes needed for this feature
2. **Do NOT create new service methods** — `getTransactionsForItem()` already exists
3. **Do NOT create new providers** — `transactionsByItemProvider` already exists
4. **Do NOT modify the Transaction model** — it already has all needed fields
5. **Do NOT use `Navigator.push()`** — use GoRouter (`context.push()`)
6. **Do NOT hardcode colors** — use `AppColors.*` and `AppTheme.*`
7. **Do NOT hardcode currency** — use `currencySymbolProvider`
8. **Do NOT use `ref.invalidate()` when you need data ready before the next line** — use `await ref.refresh(provider.future)` instead
9. **Do NOT remove the existing `GestureDetector` wrapper on action buttons** in CategoryDetailScreen — it prevents tap event bubbling
10. **Do NOT modify `transaction_provider.dart`** — it already has everything needed

---

## Summary of Changes

| File | Action | Lines Changed |
|------|--------|---------------|
| `lib/providers/item_provider.dart` | Modify `itemByIdProvider` to calculate actuals | ~15 lines |
| `lib/config/routes.dart` | Add nested item route + import | ~12 lines |
| `lib/screens/expenses/item_detail_screen.dart` | **NEW FILE** — full item detail screen | ~350 lines |
| `lib/screens/expenses/category_detail_screen.dart` | Add `GestureDetector` + GoRouter import | ~5 lines |

**Total new/modified code: ~380 lines across 4 files**

---

*Created: 2026-02-06*
*Feature: Item Detail Page with Transaction History*
*Follows: CLAUDE.md engineering guidelines*
