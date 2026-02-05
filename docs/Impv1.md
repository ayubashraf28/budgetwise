# BudgetWise v1 Implementation Plan

## Current Application State

### Tech Stack
- **Framework:** Flutter (Dart)
- **State Management:** Riverpod 2.x (StateNotifier + AsyncNotifier patterns)
- **Routing:** GoRouter with ShellRoute for bottom navigation
- **Backend:** Supabase (PostgreSQL with Row-Level Security)
- **Auth:** Supabase Auth (email/password)
- **UI:** Dark theme, LucideIcons, custom design system (AppColors, AppTypography, AppSpacing, AppSizing)

### Architecture
```
lib/
  config/       -> Theme, constants, routes, Supabase config
  models/       -> Category, Item, Transaction, IncomeSource, UserProfile
  providers/    -> Riverpod providers (auth, profile, category, item, transaction, income, calculation)
  services/     -> Supabase CRUD services (auth, profile, category, item, transaction, income, month)
  screens/      -> UI screens (auth, home, expenses, income, transactions, settings, onboarding)
  widgets/      -> Reusable widgets (budget cards, progress bars, form fields)
  utils/        -> Validators (email, password, name)
```

### Data Flow
```
Supabase DB -> Services (CRUD) -> Providers (state + business logic) -> UI (screens/widgets)
```

### What's Working
- User authentication (login, register, sign out)
- Monthly budget creation and management
- Categories with items (full CRUD in services/providers)
- Income sources (full CRUD in services/providers)
- Transactions (expense and income, full CRUD)
- Home screen with balance card, quick stats, category list
- Category detail screen with items and progress tracking
- Expenses overview and income overview screens
- Transaction form (add/edit expense and income)
- Settings screen (skeleton with sign out)
- Onboarding flow
- Production APK build configuration

### What's Missing / Needs Improvement
1. Login error messages too generic for wrong credentials
2. Home screen padding issues (Income/Expenses cards)
3. Category detail screen header overflow
4. No discoverable UI for editing/deleting categories and items
5. No way to create new categories/items inline from transaction form
6. Currency hardcoded to GBP (pound symbol) across all screens

---

## Feature 1: Login Screen Error Handling

### Problem
When a user enters a wrong email (even a single letter mismatch) and presses login, Supabase returns a generic "Invalid login credentials" error. The current error message says "The email or password you entered is incorrect" but doesn't guide the user to check their email specifically or suggest signing up if they don't have an account.

### Root Cause Analysis
Supabase intentionally returns the same error (`invalid login credentials`) for **both** wrong email and wrong password. This is a security best practice to prevent email enumeration attacks. We **cannot** distinguish between "email doesn't exist" and "wrong password" at the API level.

### Current Code
**File:** `lib/screens/auth/login_screen.dart`

```dart
// Current _getErrorMessage (line 65-85)
String _getErrorMessage(String error) {
    final errorLower = error.toLowerCase();
    if (errorLower.contains('invalid login credentials') ||
        errorLower.contains('invalid email or password')) {
      return 'The email or password you entered is incorrect';  // <- Too generic
    }
    // ... other cases
}
```

### Implementation Steps

#### Step 1: Add credential error tracking state
```dart
// Add to _LoginScreenState class
bool _isCredentialError = false;
```

#### Step 2: Improve error message text
Update `_getErrorMessage()` for the invalid credentials case:
```dart
if (errorLower.contains('invalid login credentials') ||
    errorLower.contains('invalid email or password')) {
  return 'The email or password you entered is incorrect. Please check your email address exists and your password is correct.';
}
```

#### Step 3: Track credential errors in catch block
```dart
catch (e) {
  setState(() {
    _errorMessage = _getErrorMessage(e.toString());
    _isCredentialError = e.toString().toLowerCase().contains('invalid login credentials') ||
        e.toString().toLowerCase().contains('invalid email or password');
  });
}
```

#### Step 4: Add sign-up hint in error card
Inside the animated error card Column, after the error message Text widget:
```dart
if (_isCredentialError) ...[
  const SizedBox(height: 4),
  Text(
    "If you don't have an account, sign up below.",
    style: TextStyle(
      color: AppColors.error.withValues(alpha: 0.7),
      fontSize: 12,
      fontStyle: FontStyle.italic,
    ),
  ),
],
```

#### Step 5: Highlight email and password fields with red border
Wrap each `AppTextField` with a conditional red border container when `_isCredentialError` is true. Change the prefix icon color to red to draw attention to the fields.

#### Step 6: Reset credential error state
Reset `_isCredentialError = false` in:
- `_handleLogin()` loading state (line 38-41)
- Error dismiss X button handler (line 191-195)

### Files Modified
| File | Changes |
|------|---------|
| `lib/screens/auth/login_screen.dart` | Add `_isCredentialError` state, improve error message, add sign-up hint, highlight fields |

---

## Feature 2: UI Fixes

### 2A: Home Screen - Income/Expenses Cards Padding

#### Problem
The Quick Stats cards (Income and Expenses) use `Transform.translate(offset: Offset(0, -AppSpacing.md))` to visually overlap with the header gradient. `Transform.translate` moves the visual rendering but does **NOT** affect the layout box. This creates:
- No proper padding above the cards
- Phantom empty space below the cards (the layout box stays in its original position)
- Compounded with 24px top padding on the Categories section title below

#### Current Code
**File:** `lib/screens/home/home_screen.dart`

```dart
// Lines 33-42 - Quick Stats with Transform hack
SliverToBoxAdapter(
  child: Transform.translate(
    offset: const Offset(0, -AppSpacing.md),  // <- Causes phantom space
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: _buildQuickStats(context, ref, summary),
    ),
  ),
),

// Lines 44-58 - Categories title with extra top padding
const SliverToBoxAdapter(
  child: Padding(
    padding: EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.lg,  // <- 24px compounds with phantom space
      AppSpacing.md,
      AppSpacing.sm,
    ),
```

#### Implementation Steps

**Step 1:** Remove `Transform.translate` wrapper, use proper padding:
```dart
SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.sm,   // 8px proper gap above cards
      AppSpacing.md,
      0,
    ),
    child: _buildQuickStats(context, ref, summary),
  ),
),
```

**Step 2:** Reduce Categories section top padding from `AppSpacing.lg` (24px) to `AppSpacing.md` (16px):
```dart
padding: EdgeInsets.fromLTRB(
  AppSpacing.md,
  AppSpacing.md,   // was AppSpacing.lg
  AppSpacing.md,
  AppSpacing.sm,
),
```

### 2B: Category Detail Screen - Header Overflow

#### Problem
The `SliverAppBar` has `expandedHeight: 200` but the content inside the `FlexibleSpaceBar` requires more space:
- SafeArea status bar: ~44px
- kToolbarHeight top padding: ~56px
- Bottom padding (AppSpacing.md): 16px
- Icon row (Container 48px): 48px
- Spacer(): variable (can be 0)
- Summary card (amount 32px + progress bar 12px + gaps + status text): ~84px
- **Total minimum needed: ~248px** vs **200px available = OVERFLOW**

#### Current Code
**File:** `lib/screens/expenses/category_detail_screen.dart`

```dart
SliverAppBar(
  expandedHeight: 200,  // <- Too small
  // ...
  child: Column(
    // ...
    const Spacer(),  // <- Unstable, can't guarantee space
    _buildSummaryCard(category),
  ),
),
```

#### Implementation Steps

**Step 1:** Increase `expandedHeight` from 200 to 280:
```dart
expandedHeight: 280,
```

**Step 2:** Replace `Spacer()` with a fixed `SizedBox` for predictable layout:
```dart
const SizedBox(height: AppSpacing.md),  // was Spacer()
```

### Files Modified
| File | Changes |
|------|---------|
| `lib/screens/home/home_screen.dart` | Remove Transform.translate, use proper padding, reduce Categories section top padding |
| `lib/screens/expenses/category_detail_screen.dart` | Increase expandedHeight to 280, replace Spacer with SizedBox |

---

## Feature 3: Category & Item Edit/Delete

### Problem
Categories can be edited (long-press) and deleted (swipe) on the expenses overview screen, but these gestures are **not discoverable**. On the category detail screen, there is **no way** to edit or delete the category itself. Items can be edited (tap) and deleted (swipe) but again, swipe-to-delete is not obvious.

### Existing Infrastructure (Already Built)
| Component | Location | Status |
|-----------|----------|--------|
| `CategoryFormSheet` (create + edit mode) | `lib/screens/expenses/category_form_sheet.dart` | Exists, supports `category?` param |
| `ItemFormSheet` (create + edit mode) | `lib/screens/expenses/item_form_sheet.dart` | Exists, supports `item?` param |
| `categoryNotifierProvider.updateCategory()` | `lib/providers/category_provider.dart` | Exists |
| `categoryNotifierProvider.deleteCategory()` | `lib/providers/category_provider.dart` | Exists |
| `itemNotifierProvider(id).updateItem()` | `lib/providers/item_provider.dart` | Exists |
| `itemNotifierProvider(id).deleteItem()` | `lib/providers/item_provider.dart` | Exists |
| Delete confirmation dialog | `category_detail_screen.dart` line 471 | Exists for items |

### Implementation Steps

#### Step 1: Add PopupMenuButton to Category Detail SliverAppBar

Add `actions` parameter to the SliverAppBar in `category_detail_screen.dart`:

```dart
SliverAppBar(
  expandedHeight: 280,
  pinned: true,
  leading: IconButton(...),
  actions: [
    PopupMenuButton<String>(
      icon: const Icon(LucideIcons.moreVertical, color: Colors.white),
      color: AppColors.surface,
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _showEditCategorySheet(context, ref, category);
          case 'delete':
            _showDeleteCategoryConfirmation(context, ref, category);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'edit', child: Row(children: [
          Icon(LucideIcons.pencil, size: 18), SizedBox(width: 8), Text('Edit Category')
        ])),
        PopupMenuItem(value: 'delete', child: Row(children: [
          Icon(LucideIcons.trash2, size: 18, color: AppColors.error),
          SizedBox(width: 8),
          Text('Delete Category', style: TextStyle(color: AppColors.error))
        ])),
      ],
    ),
  ],
  backgroundColor: category.colorValue,
  // ...
),
```

#### Step 2: Add helper methods

```dart
void _showEditCategorySheet(BuildContext context, WidgetRef ref, Category category) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CategoryFormSheet(category: category),
  );
}

Future<void> _showDeleteCategoryConfirmation(
  BuildContext context, WidgetRef ref, Category category,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Delete Category?'),
      content: Text('This will permanently delete "${category.name}" and all its items and transactions.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    await ref.read(categoryNotifierProvider.notifier).deleteCategory(category.id);
    if (context.mounted) {
      Navigator.of(context).pop();  // Navigate back after deletion
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${category.name} deleted')),
      );
    }
  }
}
```

#### Step 3: Add explicit Edit/Delete buttons on item cards

In `_buildItemCard()`, add a row of action buttons at the bottom of each item card:

```dart
// After the progress bar section in the item card Column
const SizedBox(height: AppSpacing.sm),
Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    InkWell(
      onTap: () => _showEditSheet(context, ref, category, item),
      child: Row(children: [
        Icon(LucideIcons.pencil, size: 14, color: AppColors.textSecondary),
        SizedBox(width: 4),
        Text('Edit', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ]),
    ),
    const SizedBox(width: AppSpacing.md),
    InkWell(
      onTap: () async {
        final confirmed = await _showDeleteConfirmation(context, item);
        if (confirmed && context.mounted) {
          ref.read(itemNotifierProvider(categoryId).notifier).deleteItem(item.id);
        }
      },
      child: Row(children: [
        Icon(LucideIcons.trash2, size: 14, color: AppColors.error),
        SizedBox(width: 4),
        Text('Delete', style: TextStyle(color: AppColors.error, fontSize: 12)),
      ]),
    ),
  ],
),
```

#### Step 4: Add import for CategoryFormSheet
```dart
import 'category_form_sheet.dart';  // Already imported? Verify and add if missing
```

### Files Modified
| File | Changes |
|------|---------|
| `lib/screens/expenses/category_detail_screen.dart` | Add PopupMenuButton to SliverAppBar, add edit/delete methods, add item action buttons |

---

## Feature 4: Add New Category/Item from Transaction Form

### Problem
When adding a transaction, the user must select a category and item from dropdowns. If the category or item they need doesn't exist, they have to close the form, navigate to create it elsewhere, then come back. This is a poor UX.

### Current Code
**File:** `lib/screens/transactions/transaction_form_sheet.dart`

```dart
// Current: Simple label + dropdown, no creation option
_buildLabel('Category'),
const SizedBox(height: AppSpacing.sm),
_buildCategoryDropdown(categories),  // DropdownButtonFormField<String>

_buildLabel('Item'),
const SizedBox(height: AppSpacing.sm),
_buildItemDropdown(items),  // DropdownButtonFormField<String>

_buildLabel('Income Source'),
const SizedBox(height: AppSpacing.sm),
_buildIncomeSourceDropdown(incomeSources),  // DropdownButtonFormField<String>
```

### Implementation Steps

#### Step 1: Add imports to transaction_form_sheet.dart
```dart
import '../expenses/category_form_sheet.dart';
import '../expenses/item_form_sheet.dart';
import '../income/income_form_sheet.dart';
```

#### Step 2: Replace label with label + "+ New" button for Category
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    _buildLabel('Category'),
    InkWell(
      onTap: () => _handleAddCategory(context),
      borderRadius: BorderRadius.circular(AppSizing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.plus, size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
            Text('New', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    ),
  ],
),
```

#### Step 3: Same pattern for Item (show "+ New" only when category is selected)
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    _buildLabel('Item'),
    if (_selectedCategoryId != null)
      InkWell(
        onTap: () => _handleAddItem(context),
        // ... same style as above
      ),
  ],
),
```

#### Step 4: Same pattern for Income Source
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    _buildLabel('Income Source'),
    InkWell(
      onTap: () => _handleAddIncomeSource(context),
      // ... same style as above
    ),
  ],
),
```

#### Step 5: Implement handler methods
```dart
Future<void> _handleAddCategory(BuildContext context) async {
  final newCategoryId = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const CategoryFormSheet(),
  );
  ref.invalidate(categoriesProvider);
  if (newCategoryId != null) {
    setState(() {
      _selectedCategoryId = newCategoryId;
      _selectedItemId = null;
    });
  }
}

Future<void> _handleAddItem(BuildContext context) async {
  if (_selectedCategoryId == null) return;
  final newItemId = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ItemFormSheet(categoryId: _selectedCategoryId!),
  );
  ref.invalidate(categoriesProvider);
  if (newItemId != null) {
    setState(() {
      _selectedItemId = newItemId;
    });
  }
}

Future<void> _handleAddIncomeSource(BuildContext context) async {
  final newSourceId = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const IncomeFormSheet(),
  );
  ref.invalidate(incomeSourcesProvider);
  if (newSourceId != null) {
    setState(() {
      _selectedIncomeSourceId = newSourceId;
    });
  }
}
```

#### Step 6: Modify form sheets to return new entity ID

Each form sheet currently calls `Navigator.of(context).pop()` after successful creation. Change the **ADD path only** (not edit) to return the new ID:

**category_form_sheet.dart** (line 354-362):
```dart
// In _handleSubmit, ADD path:
final newCategory = await notifier.addCategory(name: name, icon: _selectedIcon, color: _selectedColor);
if (mounted) {
  Navigator.of(context).pop(newCategory.id);  // Return ID instead of void pop
  // ...snackbar
}
```

**item_form_sheet.dart** (line 242-249):
```dart
// In _handleSubmit, ADD path:
final newItem = await notifier.addItem(name: name, projected: projected, isRecurring: _isRecurring, notes: ...);
if (mounted) {
  Navigator.of(context).pop(newItem.id);  // Return ID
}
```

**income_form_sheet.dart** (line 265-272):
```dart
// In _handleSubmit, ADD path:
final newSource = await notifier.addIncomeSource(name: name, projected: projected, isRecurring: _isRecurring, notes: ...);
if (mounted) {
  Navigator.of(context).pop(newSource.id);  // Return ID
}
```

### Files Modified
| File | Changes |
|------|---------|
| `lib/screens/transactions/transaction_form_sheet.dart` | Add imports, replace labels with label + "+ New" button, add handler methods |
| `lib/screens/expenses/category_form_sheet.dart` | Return `category.id` from `Navigator.pop()` in ADD path |
| `lib/screens/expenses/item_form_sheet.dart` | Return `item.id` from `Navigator.pop()` in ADD path |
| `lib/screens/income/income_form_sheet.dart` | Return `source.id` from `Navigator.pop()` in ADD path |

---

## Feature 5: Currency Settings

### Problem
The currency is hardcoded to GBP (`\u00A3` = pound symbol) across the entire app. The settings screen shows "GBP" but tapping it shows a "coming soon" snackbar. The infrastructure partially exists but is not wired up.

### Existing Infrastructure
| Component | Location | Status |
|-----------|----------|--------|
| `UserProfile.currency` field | `lib/models/user_profile.dart` line 8 | Exists (default: 'GBP') |
| `profiles.currency` column | Supabase DB | Exists (TEXT, default 'GBP') |
| `AppConstants.currencySymbols` map | `lib/config/constants.dart` line 14-20 | Exists (GBP, USD, EUR, JPY, INR) |
| `profileNotifierProvider.updateProfile(currency:)` | `lib/providers/profile_provider.dart` line 31 | Exists |
| `BalanceCard.currencySymbol` param | `lib/widgets/budget/balance_card.dart` | Exists (default '\u00A3') |
| `QuickStatCard.currencySymbol` param | `lib/widgets/budget/quick_stat_card.dart` | Exists (default '\u00A3') |
| Settings screen Currency tile | `lib/screens/settings/settings_screen.dart` line 62-76 | Shows "GBP", snackbar on tap |

### Hardcoded Currency Locations (All Need Updating)
| File | Line(s) | Hardcoded Value |
|------|---------|-----------------|
| `transaction_form_sheet.dart` | 137 | `prefixText: '\u00A3 '` |
| `item_form_sheet.dart` | 127 | `prefixText: '\u00A3 '` |
| `income_form_sheet.dart` | 130, 157 | `prefixText: '\u00A3 '` |
| `category_detail_screen.dart` | 210, 218, 239, 240, 311, 345 | `\u00A3` in amounts |
| `expenses_overview_screen.dart` | 163, 183 | `\u00A3` in summary |
| `income_screen.dart` | 152, 172, 231 | `\u00A3` in summary |
| `category_list_item.dart` | 89 | `\u00A3` in amount display |
| `transaction_list_item.dart` | 82 | `formattedAmount('\u00A3')` |

### Implementation Steps

#### Step 1: Create currency providers
**File:** `lib/providers/profile_provider.dart` (add after line 75)

```dart
import '../config/constants.dart';

/// Provider for the current currency code (e.g., 'GBP', 'USD')
final currencyProvider = Provider<String>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  return profile?.currency ?? AppConstants.defaultCurrency;
});

/// Provider for the current currency symbol (e.g., '\u00A3', '\$')
final currencySymbolProvider = Provider<String>((ref) {
  final currency = ref.watch(currencyProvider);
  return AppConstants.currencySymbols[currency] ?? '\u00A3';
});
```

These providers automatically update when the user profile changes (Riverpod dependency tracking).

#### Step 2: Create currency picker bottom sheet
**New file:** `lib/screens/settings/currency_picker_sheet.dart`

A bottom sheet that:
- Lists all 5 currencies from `AppConstants.currencySymbols`
- Shows currency symbol, code, and full name (e.g., "British Pound (GBP)")
- Highlights the currently selected currency with a checkmark
- On selection: calls `profileNotifierProvider.updateProfile(currency: code)`
- Invalidates `userProfileProvider` to trigger reactive updates across the app

```dart
class CurrencyPickerSheet extends ConsumerWidget {
  // Container with rounded top corners
  // Handle bar
  // "Select Currency" header
  // List of currency tiles:
  //   - Symbol in colored circle (primary if selected, surfaceLight if not)
  //   - Full name text (e.g., "British Pound (GBP)")
  //   - Check icon if selected
  //   - onTap: update profile currency + pop
}
```

Currency name mapping:
```dart
const names = {
  'GBP': 'British Pound (GBP)',
  'USD': 'US Dollar (USD)',
  'EUR': 'Euro (EUR)',
  'JPY': 'Japanese Yen (JPY)',
  'INR': 'Indian Rupee (INR)',
};
```

#### Step 3: Wire settings screen to currency picker
**File:** `lib/screens/settings/settings_screen.dart`

```dart
// Add import
import 'currency_picker_sheet.dart';

// In build(), read current currency:
final currentCurrency = ref.watch(currencyProvider);
final currentSymbol = ref.watch(currencySymbolProvider);

// Update Currency tile (replace lines 62-76):
_SettingsTile(
  icon: LucideIcons.poundSterling,
  title: 'Currency',
  trailing: Text(
    '$currentSymbol $currentCurrency',  // Dynamic
    style: const TextStyle(color: AppColors.textSecondary),
  ),
  onTap: () {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const CurrencyPickerSheet(),
    );
  },
),
```

#### Step 4: Update all screens to use dynamic currency

**Pattern for ConsumerWidget/ConsumerStatefulWidget screens:**
```dart
final currencySymbol = ref.watch(currencySymbolProvider);
// Then use $currencySymbol instead of \u00A3
```

**Pattern for StatelessWidget widgets (no ref access):**
Add `currencySymbol` parameter with default `'\u00A3'`, pass from parent.

**Specific file changes:**

| File | Change |
|------|--------|
| `home_screen.dart` | Read `currencySymbolProvider`, pass to `BalanceCard(currencySymbol:)` and `QuickStatCard(currencySymbol:)` |
| `category_list_item.dart` | Add `currencySymbol` param, replace hardcoded `\u00A3` |
| `category_detail_screen.dart` | Read provider, pass to `_buildSummaryCard()`, `_buildItemCard()`, `_buildItemStatusBadge()` |
| `expenses_overview_screen.dart` | Read provider, pass to `_buildSummaryCard()`, `_buildSummaryRow()` |
| `income_screen.dart` | Read provider, pass to summary and income source item builders |
| `transaction_form_sheet.dart` | Read provider, use for `prefixText` in amount field |
| `item_form_sheet.dart` | Read provider, use for `prefixText` in budget amount field |
| `income_form_sheet.dart` | Read provider, use for `prefixText` in projected/actual fields |
| `transaction_list_item.dart` | Add `currencySymbol` param, pass to `formattedAmount()` |

#### Step 5: Update callers of modified widgets

Every place that creates a `CategoryListItem` or `TransactionListItem` must pass the `currencySymbol` parameter. Key callers:
- `home_screen.dart` line 76 (CategoryListItem in categories list)
- `expenses_overview_screen.dart` line 244 (CategoryListItem in categories list)
- `transactions_screen.dart` (TransactionListItem usage)

### Files Modified
| File | Changes |
|------|---------|
| `lib/providers/profile_provider.dart` | Add `currencyProvider` and `currencySymbolProvider` |
| **NEW** `lib/screens/settings/currency_picker_sheet.dart` | Create currency picker bottom sheet |
| `lib/screens/settings/settings_screen.dart` | Wire currency tile to picker, show dynamic currency |
| `lib/screens/home/home_screen.dart` | Pass dynamic `currencySymbol` to BalanceCard, QuickStatCard, CategoryListItem |
| `lib/screens/expenses/category_detail_screen.dart` | Use dynamic `currencySymbol` in summary, items, status badges |
| `lib/screens/expenses/expenses_overview_screen.dart` | Use dynamic `currencySymbol` in summary card and rows |
| `lib/screens/income/income_screen.dart` | Use dynamic `currencySymbol` in summary and income items |
| `lib/screens/transactions/transaction_form_sheet.dart` | Use dynamic `currencySymbol` for amount prefixText |
| `lib/screens/expenses/item_form_sheet.dart` | Use dynamic `currencySymbol` for budget amount prefixText |
| `lib/screens/income/income_form_sheet.dart` | Use dynamic `currencySymbol` for projected/actual prefixText |
| `lib/widgets/budget/category_list_item.dart` | Add `currencySymbol` parameter, use in amount display |
| `lib/widgets/budget/transaction_list_item.dart` | Add `currencySymbol` parameter, pass to `formattedAmount()` |

---

## Implementation Order

| Priority | Feature | Scope | Reason |
|----------|---------|-------|--------|
| 1 | **Feature 5: Currency Settings** | 12+ files | Creates provider infrastructure (`currencySymbolProvider`) that other features will use |
| 2 | **Feature 2: UI Fixes** | 2 files | Quick layout fixes, low risk |
| 3 | **Feature 1: Login Errors** | 1 file | Self-contained, single file |
| 4 | **Feature 3: Category Edit/Delete** | 1 file | Moderate scope, leverages existing infrastructure |
| 5 | **Feature 4: Transaction Form** | 4 files | Touches multiple form sheets, depends on understanding return patterns |

---

## Complete File Map

### Files to Modify
| File Path | Features |
|-----------|----------|
| `lib/providers/profile_provider.dart` | F5 |
| `lib/screens/auth/login_screen.dart` | F1 |
| `lib/screens/home/home_screen.dart` | F2, F5 |
| `lib/screens/settings/settings_screen.dart` | F5 |
| `lib/screens/expenses/category_detail_screen.dart` | F2, F3, F5 |
| `lib/screens/expenses/expenses_overview_screen.dart` | F5 |
| `lib/screens/expenses/category_form_sheet.dart` | F4 |
| `lib/screens/expenses/item_form_sheet.dart` | F4, F5 |
| `lib/screens/income/income_screen.dart` | F5 |
| `lib/screens/income/income_form_sheet.dart` | F4, F5 |
| `lib/screens/transactions/transaction_form_sheet.dart` | F4, F5 |
| `lib/widgets/budget/category_list_item.dart` | F5 |
| `lib/widgets/budget/transaction_list_item.dart` | F5 |

### Files to Create
| File Path | Feature |
|-----------|---------|
| `lib/screens/settings/currency_picker_sheet.dart` | F5 |

### Total: 13 files modified + 1 file created

---

## Verification Plan

After implementing all features:

1. **Static Analysis:** Run `flutter analyze` - should report no errors or warnings
2. **Build:** Run `flutter build apk --release` - should compile successfully
3. **Manual Testing Checklist:**
   - [ ] Login with wrong email -> shows descriptive error with sign-up hint
   - [ ] Login with wrong password -> shows descriptive error
   - [ ] Login with correct credentials -> navigates to home
   - [ ] Home screen cards have proper padding (no phantom space)
   - [ ] Category detail header doesn't overflow on any device
   - [ ] Category detail 3-dot menu shows Edit/Delete options
   - [ ] Edit category opens form, saves changes
   - [ ] Delete category shows confirmation, deletes and navigates back
   - [ ] Item cards show Edit/Delete buttons
   - [ ] Transaction form: "+ New" button next to Category dropdown
   - [ ] Creating new category from transaction form auto-selects it
   - [ ] Transaction form: "+ New" button next to Item dropdown (visible after category selected)
   - [ ] Creating new item from transaction form auto-selects it
   - [ ] Transaction form: "+ New" button next to Income Source dropdown
   - [ ] Settings -> Currency opens picker
   - [ ] Selecting USD changes all pound symbols to dollar signs across the app
   - [ ] Selecting EUR changes all to euro signs
   - [ ] Currency persists after app restart (saved to Supabase)
