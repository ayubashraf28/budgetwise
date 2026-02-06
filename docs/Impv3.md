# BudgetWise v3 Implementation Plan — Home Redesign + Subscriptions

## Overview

**Goal:** Transform the home page from a basic layout into a premium fintech-grade experience, and add a complete Subscriptions feature with upcoming payments tracking.

**What changes:**
1. New `subscriptions` table + full backend stack (Model → Service → Provider)
2. New 5th bottom nav tab for Subscriptions
3. Subscriptions management screen with add/edit/delete
4. Complete home page UI redesign with premium styling
5. Upcoming Payments section on home (from subscription due dates)

**Reference:** Dark premium fintech app with gradient balance card, user greeting, notification icons, upcoming payment cards, and subscription list.

---

## Prerequisites — Read Before You Code

| File | Why |
|------|-----|
| `CLAUDE.md` (project root) | **MANDATORY** — all engineering rules and guardrails |
| `lib/config/theme.dart` | Design system — AppColors, AppTypography, AppSpacing, AppSizing |
| `lib/config/constants.dart` | App constants, currency symbols, limits |
| `lib/screens/home/home_screen.dart` | Current home page you'll be replacing |
| `lib/widgets/navigation/app_shell.dart` | Current bottom nav (4 tabs + center FAB) |
| `lib/widgets/budget/budget_widgets.dart` | Existing budget widgets to reuse |
| `lib/providers/profile_provider.dart` | User profile provider (for display name) |
| `lib/providers/calculation_provider.dart` | Monthly summary calculations |
| `supabase_schema.sql` | Existing database schema |

---

## Implementation Stages

This is divided into 4 stages. **Complete each stage fully before moving to the next.** After each stage, run `flutter analyze` to verify no errors.

---

# STAGE 1: Subscriptions Backend

> Follow CLAUDE.md Section 11 order: Schema → Model → Service → Provider → Export

---

### Step 1.1: Database Schema

**File:** `supabase_schema.sql`

Add this new table at the end of the file (before the helper functions section, or after it):

```sql
-- -----------------------------------------------------
-- 7b. SUBSCRIPTIONS TABLE
-- Recurring payments and subscriptions tracked by user
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    currency TEXT DEFAULT 'GBP',
    icon TEXT DEFAULT 'credit-card',
    color TEXT DEFAULT '#6366f1',
    billing_cycle TEXT NOT NULL DEFAULT 'monthly'
        CHECK (billing_cycle IN ('weekly', 'monthly', 'quarterly', 'yearly', 'custom')),
    next_due_date DATE NOT NULL,
    is_auto_renew BOOLEAN DEFAULT TRUE,
    custom_cycle_days INTEGER,
    category_name TEXT,
    notes TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    reminder_days_before INTEGER DEFAULT 2,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view own subscriptions"
    ON public.subscriptions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own subscriptions"
    ON public.subscriptions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own subscriptions"
    ON public.subscriptions FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own subscriptions"
    ON public.subscriptions FOR DELETE
    USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON public.subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_due_date ON public.subscriptions(next_due_date);
CREATE INDEX IF NOT EXISTS idx_subscriptions_active ON public.subscriptions(user_id, is_active);

-- Updated_at trigger
DROP TRIGGER IF EXISTS update_subscriptions_updated_at ON public.subscriptions;
CREATE TRIGGER update_subscriptions_updated_at
    BEFORE UPDATE ON public.subscriptions
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
```

**Run this SQL in Supabase SQL Editor** after adding it to the schema file.

**Key design decisions:**
- `billing_cycle`: enum-like text field — weekly, monthly, quarterly, yearly, or custom
- `next_due_date`: the user's next payment date (manually set OR auto-calculated)
- `is_auto_renew`: if true, the app auto-advances `next_due_date` after it passes
- `custom_cycle_days`: only used when `billing_cycle = 'custom'` (e.g., every 45 days)
- `reminder_days_before`: how many days before due date to show in "Upcoming"
- `category_name`: optional text label (e.g., "Entertainment", "Utilities") — NOT a foreign key to categories table (subscriptions are month-independent)
- `is_active`: soft delete / pause subscriptions without removing them

---

### Step 1.2: Subscription Model

**NEW FILE:** `lib/models/subscription.dart`

```dart
import 'package:flutter/foundation.dart';

enum BillingCycle { weekly, monthly, quarterly, yearly, custom }

@immutable
class Subscription {
  final String id;
  final String userId;
  final String name;
  final double amount;
  final String currency;
  final String icon;
  final String color;
  final BillingCycle billingCycle;
  final DateTime nextDueDate;
  final bool isAutoRenew;
  final int? customCycleDays;
  final String? categoryName;
  final String? notes;
  final bool isActive;
  final int reminderDaysBefore;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Subscription({
    required this.id,
    required this.userId,
    required this.name,
    this.amount = 0,
    this.currency = 'GBP',
    this.icon = 'credit-card',
    this.color = '#6366f1',
    this.billingCycle = BillingCycle.monthly,
    required this.nextDueDate,
    this.isAutoRenew = true,
    this.customCycleDays,
    this.categoryName,
    this.notes,
    this.isActive = true,
    this.reminderDaysBefore = 2,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'GBP',
      icon: json['icon'] as String? ?? 'credit-card',
      color: json['color'] as String? ?? '#6366f1',
      billingCycle: _parseBillingCycle(json['billing_cycle'] as String?),
      nextDueDate: DateTime.parse(json['next_due_date'] as String),
      isAutoRenew: json['is_auto_renew'] as bool? ?? true,
      customCycleDays: json['custom_cycle_days'] as int?,
      categoryName: json['category_name'] as String?,
      notes: json['notes'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      reminderDaysBefore: json['reminder_days_before'] as int? ?? 2,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'amount': amount,
      'currency': currency,
      'icon': icon,
      'color': color,
      'billing_cycle': billingCycle.name,
      'next_due_date': nextDueDate.toIso8601String().split('T').first,
      'is_auto_renew': isAutoRenew,
      'custom_cycle_days': customCycleDays,
      'category_name': categoryName,
      'notes': notes,
      'is_active': isActive,
      'reminder_days_before': reminderDaysBefore,
    };
  }

  Subscription copyWith({
    String? id,
    String? userId,
    String? name,
    double? amount,
    String? currency,
    String? icon,
    String? color,
    BillingCycle? billingCycle,
    DateTime? nextDueDate,
    bool? isAutoRenew,
    int? customCycleDays,
    String? categoryName,
    String? notes,
    bool? isActive,
    int? reminderDaysBefore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      billingCycle: billingCycle ?? this.billingCycle,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      isAutoRenew: isAutoRenew ?? this.isAutoRenew,
      customCycleDays: customCycleDays ?? this.customCycleDays,
      categoryName: categoryName ?? this.categoryName,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ── Computed Properties ──

  /// Color as Flutter Color value
  Color get colorValue {
    final hex = color.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  /// Days until next payment
  int get daysUntilDue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);
    return due.difference(today).inDays;
  }

  /// Whether payment is due today
  bool get isDueToday => daysUntilDue == 0;

  /// Whether payment is overdue
  bool get isOverdue => daysUntilDue < 0;

  /// Whether this subscription should show in "Upcoming" section
  bool get isUpcoming => daysUntilDue >= 0 && daysUntilDue <= reminderDaysBefore;

  /// Whether due within the next 7 days (for home page display)
  bool get isDueSoon => daysUntilDue >= 0 && daysUntilDue <= 7;

  /// Human-readable billing cycle
  String get billingCycleLabel {
    switch (billingCycle) {
      case BillingCycle.weekly:
        return 'Weekly';
      case BillingCycle.monthly:
        return 'Monthly';
      case BillingCycle.quarterly:
        return 'Quarterly';
      case BillingCycle.yearly:
        return 'Yearly';
      case BillingCycle.custom:
        return customCycleDays != null ? 'Every $customCycleDays days' : 'Custom';
    }
  }

  /// Calculate the next due date after the current one passes
  DateTime get calculatedNextDueDate {
    if (!isAutoRenew) return nextDueDate;

    switch (billingCycle) {
      case BillingCycle.weekly:
        return nextDueDate.add(const Duration(days: 7));
      case BillingCycle.monthly:
        return DateTime(nextDueDate.year, nextDueDate.month + 1, nextDueDate.day);
      case BillingCycle.quarterly:
        return DateTime(nextDueDate.year, nextDueDate.month + 3, nextDueDate.day);
      case BillingCycle.yearly:
        return DateTime(nextDueDate.year + 1, nextDueDate.month, nextDueDate.day);
      case BillingCycle.custom:
        return nextDueDate.add(Duration(days: customCycleDays ?? 30));
    }
  }

  /// Status text for display
  String get status {
    if (!isActive) return 'Paused';
    if (isOverdue) return 'Overdue';
    if (isDueToday) return 'Due today';
    if (isDueSoon) return 'Due in $daysUntilDue days';
    return 'Active';
  }

  static BillingCycle _parseBillingCycle(String? value) {
    switch (value) {
      case 'weekly':
        return BillingCycle.weekly;
      case 'quarterly':
        return BillingCycle.quarterly;
      case 'yearly':
        return BillingCycle.yearly;
      case 'custom':
        return BillingCycle.custom;
      default:
        return BillingCycle.monthly;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Subscription && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Subscription(id: $id, name: $name, amount: $amount, due: $nextDueDate)';
}
```

---

### Step 1.3: Subscription Service

**NEW FILE:** `lib/services/subscription_service.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/subscription.dart';

class SubscriptionService {
  final SupabaseClient _client = Supabase.instance.client;
  final String _table = 'subscriptions';

  String get _userId => _client.auth.currentUser!.id;

  /// Get all subscriptions for the current user
  Future<List<Subscription>> getSubscriptions() async {
    final response = await _client
        .from(_table)
        .select()
        .eq('user_id', _userId)
        .order('next_due_date', ascending: true);

    return (response as List).map((e) => Subscription.fromJson(e)).toList();
  }

  /// Get only active subscriptions
  Future<List<Subscription>> getActiveSubscriptions() async {
    final response = await _client
        .from(_table)
        .select()
        .eq('user_id', _userId)
        .eq('is_active', true)
        .order('next_due_date', ascending: true);

    return (response as List).map((e) => Subscription.fromJson(e)).toList();
  }

  /// Get subscriptions due within N days
  Future<List<Subscription>> getUpcomingSubscriptions({int withinDays = 7}) async {
    final now = DateTime.now();
    final cutoff = now.add(Duration(days: withinDays));

    final response = await _client
        .from(_table)
        .select()
        .eq('user_id', _userId)
        .eq('is_active', true)
        .lte('next_due_date', cutoff.toIso8601String().split('T').first)
        .order('next_due_date', ascending: true);

    return (response as List).map((e) => Subscription.fromJson(e)).toList();
  }

  /// Get a single subscription by ID
  Future<Subscription?> getSubscriptionById(String subscriptionId) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('id', subscriptionId)
        .eq('user_id', _userId)
        .maybeSingle();

    if (response == null) return null;
    return Subscription.fromJson(response);
  }

  /// Create a new subscription
  Future<Subscription> createSubscription({
    required String name,
    required double amount,
    required DateTime nextDueDate,
    String billingCycle = 'monthly',
    bool isAutoRenew = true,
    int? customCycleDays,
    String? icon,
    String? color,
    String? categoryName,
    String? notes,
    int reminderDaysBefore = 2,
  }) async {
    final response = await _client.from(_table).insert({
      'user_id': _userId,
      'name': name,
      'amount': amount,
      'next_due_date': nextDueDate.toIso8601String().split('T').first,
      'billing_cycle': billingCycle,
      'is_auto_renew': isAutoRenew,
      'custom_cycle_days': customCycleDays,
      'icon': icon ?? 'credit-card',
      'color': color ?? '#6366f1',
      'category_name': categoryName,
      'notes': notes,
      'reminder_days_before': reminderDaysBefore,
    }).select().single();

    return Subscription.fromJson(response);
  }

  /// Update a subscription
  Future<Subscription> updateSubscription({
    required String subscriptionId,
    String? name,
    double? amount,
    DateTime? nextDueDate,
    String? billingCycle,
    bool? isAutoRenew,
    int? customCycleDays,
    String? icon,
    String? color,
    String? categoryName,
    String? notes,
    bool? isActive,
    int? reminderDaysBefore,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (amount != null) updates['amount'] = amount;
    if (nextDueDate != null) {
      updates['next_due_date'] = nextDueDate.toIso8601String().split('T').first;
    }
    if (billingCycle != null) updates['billing_cycle'] = billingCycle;
    if (isAutoRenew != null) updates['is_auto_renew'] = isAutoRenew;
    if (customCycleDays != null) updates['custom_cycle_days'] = customCycleDays;
    if (icon != null) updates['icon'] = icon;
    if (color != null) updates['color'] = color;
    if (categoryName != null) updates['category_name'] = categoryName;
    if (notes != null) updates['notes'] = notes;
    if (isActive != null) updates['is_active'] = isActive;
    if (reminderDaysBefore != null) updates['reminder_days_before'] = reminderDaysBefore;

    final response = await _client
        .from(_table)
        .update(updates)
        .eq('id', subscriptionId)
        .eq('user_id', _userId)
        .select()
        .single();

    return Subscription.fromJson(response);
  }

  /// Delete a subscription
  Future<void> deleteSubscription(String subscriptionId) async {
    await _client
        .from(_table)
        .delete()
        .eq('id', subscriptionId)
        .eq('user_id', _userId);
  }

  /// Advance the due date for auto-renewing subscriptions that are past due
  Future<Subscription> advanceDueDate(String subscriptionId) async {
    final sub = await getSubscriptionById(subscriptionId);
    if (sub == null) throw Exception('Subscription not found');

    final newDate = sub.calculatedNextDueDate;
    return updateSubscription(
      subscriptionId: subscriptionId,
      nextDueDate: newDate,
    );
  }
}
```

---

### Step 1.4: Subscription Providers

**NEW FILE:** `lib/providers/subscription_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/subscription.dart';
import '../services/subscription_service.dart';
import 'auth_provider.dart';

/// Subscription service provider
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

/// All subscriptions for the current user (active + inactive)
final subscriptionsProvider = FutureProvider<List<Subscription>>((ref) async {
  final service = ref.read(subscriptionServiceProvider);
  return service.getSubscriptions();
});

/// Only active subscriptions
final activeSubscriptionsProvider = FutureProvider<List<Subscription>>((ref) async {
  final service = ref.read(subscriptionServiceProvider);
  return service.getActiveSubscriptions();
});

/// Subscriptions due within the next 7 days (for home page "Upcoming Payments")
final upcomingSubscriptionsProvider = FutureProvider<List<Subscription>>((ref) async {
  final service = ref.read(subscriptionServiceProvider);
  return service.getUpcomingSubscriptions(withinDays: 7);
});

/// Total monthly subscription cost (active only)
final totalSubscriptionCostProvider = Provider<double>((ref) {
  final subs = ref.watch(activeSubscriptionsProvider).value ?? [];
  return subs.fold<double>(0.0, (sum, sub) {
    // Normalize to monthly cost for display
    switch (sub.billingCycle) {
      case BillingCycle.weekly:
        return sum + (sub.amount * 4.33); // Average weeks per month
      case BillingCycle.monthly:
        return sum + sub.amount;
      case BillingCycle.quarterly:
        return sum + (sub.amount / 3);
      case BillingCycle.yearly:
        return sum + (sub.amount / 12);
      case BillingCycle.custom:
        final days = sub.customCycleDays ?? 30;
        return sum + (sub.amount * 30 / days);
    }
  });
});

/// Count of subscriptions due soon (for notification badge)
final dueSoonCountProvider = Provider<int>((ref) {
  final subs = ref.watch(upcomingSubscriptionsProvider).value ?? [];
  return subs.length;
});

/// Subscription notifier for CRUD mutations
class SubscriptionNotifier extends AsyncNotifier<List<Subscription>> {
  @override
  Future<List<Subscription>> build() async {
    final service = ref.read(subscriptionServiceProvider);
    return service.getSubscriptions();
  }

  SubscriptionService get _service => ref.read(subscriptionServiceProvider);

  Future<Subscription> addSubscription({
    required String name,
    required double amount,
    required DateTime nextDueDate,
    String billingCycle = 'monthly',
    bool isAutoRenew = true,
    int? customCycleDays,
    String? icon,
    String? color,
    String? categoryName,
    String? notes,
    int reminderDaysBefore = 2,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw Exception('Not authenticated');

    final sub = await _service.createSubscription(
      name: name,
      amount: amount,
      nextDueDate: nextDueDate,
      billingCycle: billingCycle,
      isAutoRenew: isAutoRenew,
      customCycleDays: customCycleDays,
      icon: icon,
      color: color,
      categoryName: categoryName,
      notes: notes,
      reminderDaysBefore: reminderDaysBefore,
    );

    _invalidateAll();
    return sub;
  }

  Future<Subscription> updateSubscription({
    required String subscriptionId,
    String? name,
    double? amount,
    DateTime? nextDueDate,
    String? billingCycle,
    bool? isAutoRenew,
    int? customCycleDays,
    String? icon,
    String? color,
    String? categoryName,
    String? notes,
    bool? isActive,
    int? reminderDaysBefore,
  }) async {
    final sub = await _service.updateSubscription(
      subscriptionId: subscriptionId,
      name: name,
      amount: amount,
      nextDueDate: nextDueDate,
      billingCycle: billingCycle,
      isAutoRenew: isAutoRenew,
      customCycleDays: customCycleDays,
      icon: icon,
      color: color,
      categoryName: categoryName,
      notes: notes,
      isActive: isActive,
      reminderDaysBefore: reminderDaysBefore,
    );

    _invalidateAll();
    return sub;
  }

  Future<void> deleteSubscription(String subscriptionId) async {
    await _service.deleteSubscription(subscriptionId);
    _invalidateAll();
  }

  Future<void> markAsPaid(String subscriptionId) async {
    await _service.advanceDueDate(subscriptionId);
    _invalidateAll();
  }

  void _invalidateAll() {
    ref.invalidateSelf();
    ref.invalidate(subscriptionsProvider);
    ref.invalidate(activeSubscriptionsProvider);
    ref.invalidate(upcomingSubscriptionsProvider);
  }
}

final subscriptionNotifierProvider =
    AsyncNotifierProvider<SubscriptionNotifier, List<Subscription>>(
        () => SubscriptionNotifier());
```

---

### Step 1.5: Update Barrel Files

**File:** `lib/models/models.dart` — add at the end:
```dart
export 'subscription.dart';
```

**File:** `lib/services/services.dart` — add at the end:
```dart
export 'subscription_service.dart';
```

**File:** `lib/providers/providers.dart` — add at the end:
```dart
export 'subscription_provider.dart';
```

---

### Stage 1 Verification

After completing Stage 1:
- Run `flutter analyze` — should pass with no errors
- The app should compile and run normally (no UI changes yet)
- The `subscriptions` table should exist in Supabase with RLS policies

---

# STAGE 2: Navigation + Subscriptions UI

---

### Step 2.1: Add Subscriptions Route

**File:** `lib/config/routes.dart`

1. Add import at the top:
```dart
import '../screens/subscriptions/subscriptions_screen.dart';
```

2. Add new route inside the `ShellRoute.routes` array (after the `/settings` route):
```dart
GoRoute(
  path: '/subscriptions',
  name: 'subscriptions',
  builder: (context, state) => const SubscriptionsScreen(),
),
```

---

### Step 2.2: Update Bottom Navigation

**File:** `lib/widgets/navigation/app_shell.dart`

The current bottom nav has 4 tabs with a centered FAB using `CircularNotchedRectangle`. With 5 tabs, the layout needs restructuring. Replace the center FAB with a regular 5th nav item.

**Changes required:**

1. Remove the `floatingActionButton` and `floatingActionButtonLocation` from the `Scaffold`
2. Replace `BottomAppBar` with a standard `BottomNavigationBar` or keep `BottomAppBar` but add 5 items without the notch
3. Add the Subscriptions tab between Budget and Settings

**New tab order:**
```
Home | Transactions | Budget | Subscriptions | Settings
```

**Icon for Subscriptions tab:** `LucideIcons.repeat` or `LucideIcons.refreshCw`

**Updated `_BottomNavBar` structure:**

```dart
class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: LucideIcons.home,
                label: 'Home',
                isSelected: location == '/home',
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.go('/home');
                },
              ),
              _NavItem(
                icon: LucideIcons.creditCard,
                label: 'Transactions',
                isSelected: location == '/transactions',
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.go('/transactions');
                },
              ),
              _NavItem(
                icon: LucideIcons.pieChart,
                label: 'Budget',
                isSelected: location.startsWith('/budget') || location.startsWith('/expenses'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.go('/budget');
                },
              ),
              _NavItem(
                icon: LucideIcons.repeat,
                label: 'Subscriptions',
                isSelected: location == '/subscriptions',
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.go('/subscriptions');
                },
              ),
              _NavItem(
                icon: LucideIcons.settings,
                label: 'Settings',
                isSelected: location == '/settings',
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.go('/settings');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Important:** Since we're removing the centered FAB, the "Add Transaction" action needs to move. It will be available from:
- The home page "Add New Transaction" button (Stage 3)
- The Transactions screen (existing FAB or button there)
- An "Add" button within the Subscriptions screen for new subscriptions

---

### Step 2.3: Create Subscriptions Screen

**NEW FILE:** `lib/screens/subscriptions/subscriptions_screen.dart`

This screen shows the user's subscriptions — active, paused, and totals.

**Structure:**
```
Scaffold
├── AppBar: "Subscriptions" title + Add button
├── Summary card: total monthly cost, active count
├── "Active" section: list of active subscriptions
├── "Paused" section: list of inactive subscriptions
└── Empty state if no subscriptions
```

**Key patterns:**
- Use `ref.watch(subscriptionsProvider)` for the list
- Use `ref.watch(totalSubscriptionCostProvider)` for the monthly total
- Use `ref.watch(currencySymbolProvider)` for currency — **NEVER hardcode**
- Handle `.when(loading, error, data)` per CLAUDE.md Section 9
- Each subscription card shows: icon, name, amount, billing cycle, next due date, status
- Swipe to delete (with confirmation dialog)
- Tap to edit (opens form sheet)
- "Mark as Paid" action button (advances due date)
- Menu (3-dot) with Edit, Pause/Resume, Delete options

**Subscription card design (per reference screenshot):**
- Rounded card with colored left accent or icon container
- Name + amount prominently displayed
- Billing cycle label (e.g., "/month")
- Next due date with "Due in X days" chip
- Use the subscription's `color` for the icon container background

---

### Step 2.4: Create Subscription Form Sheet

**NEW FILE:** `lib/screens/subscriptions/subscription_form_sheet.dart`

A modal bottom sheet for adding/editing subscriptions.

**Fields:**
- Name (required, text field)
- Amount (required, number field)
- Billing Cycle (dropdown: Weekly, Monthly, Quarterly, Yearly, Custom)
- Custom Cycle Days (number field, shown only when "Custom" selected)
- Next Due Date (date picker)
- Auto-Renew toggle (switch)
- Category Label (optional text field — e.g., "Entertainment")
- Icon picker (optional — reuse existing category icon picker pattern)
- Color picker (optional — reuse existing category color picker pattern)
- Reminder Days Before (number field, default 2)
- Notes (optional text area)

**Patterns to follow:**
- Same bottom sheet pattern as `TransactionFormSheet`, `CategoryFormSheet`
- Use `showModalBottomSheet` with `isScrollControlled: true`
- Validate before submit
- Show loading state during save
- Use `ref.read(subscriptionNotifierProvider.notifier).addSubscription(...)` for create
- Use `ref.read(subscriptionNotifierProvider.notifier).updateSubscription(...)` for edit
- After save, the notifier's `_invalidateAll()` handles provider refresh

---

### Stage 2 Verification

After completing Stage 2:
- Run `flutter analyze` — no errors
- Bottom nav shows 5 tabs
- Tapping Subscriptions tab opens the subscriptions screen
- Can add a subscription via the form sheet
- Can edit, delete, and mark subscriptions as paid
- Data persists in Supabase

---

# STAGE 3: Home Page UI Redesign

---

### Step 3.1: Rewrite Home Screen

**File:** `lib/screens/home/home_screen.dart`

This is the biggest change. The new home screen layout (inspired by the reference):

```
CustomScrollView
├── SliverToBoxAdapter: _buildGreetingHeader()
│   ├── Row: Profile circle + "WELCOME BACK\nUserName" + Search + Bell icons
│
├── SliverToBoxAdapter: _buildBalanceCard()
│   ├── Gradient container (primaryGradient)
│   │   ├── "Total Balance" label + info icon
│   │   ├── Large amount text + eye toggle (hide/show)
│   │   ├── Percentage change badge ("+12.5% this month")
│   │   └── "Add New Transaction" button (white, full width)
│
├── SliverToBoxAdapter: _buildUpcomingPayments()
│   ├── "Upcoming Payments" header + "View All →" link
│   ├── "Bills due soon" subtitle
│   └── Horizontal scroll of UpcomingPaymentCard widgets
│       (from upcomingSubscriptionsProvider)
│
├── SliverToBoxAdapter: _buildQuickStats()
│   ├── Row of 2 QuickStatCards (Income + Expenses) — EXISTING widgets
│
├── SliverToBoxAdapter: _buildSubscriptionsPreview()
│   ├── "Your Subscriptions" header + count + "Add New" button
│   └── Top 3 active subscriptions (vertical list)
│
├── SliverToBoxAdapter: "Categories" section header
├── SliverList: CategoryListItem widgets — EXISTING
└── SliverToBoxAdapter: Bottom padding
```

**Key implementation details:**

#### Greeting Header
```dart
Widget _buildGreetingHeader(WidgetRef ref) {
  final profile = ref.watch(userProfileProvider).value;
  final displayName = profile?.displayName ?? 'User';

  return Padding(
    padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
    child: SafeArea(
      bottom: false,
      child: Row(
        children: [
          // Profile avatar circle
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary,
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Greeting text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WELCOME BACK', style: AppTypography.labelMedium),
                Text(displayName, style: AppTypography.h3),
              ],
            ),
          ),
          // Search icon
          IconButton(
            icon: const Icon(LucideIcons.search, color: AppColors.textSecondary),
            onPressed: () {}, // Future: search functionality
          ),
          // Notification bell icon
          IconButton(
            icon: const Icon(LucideIcons.bell, color: AppColors.textSecondary),
            onPressed: () {}, // Future: notifications screen
          ),
        ],
      ),
    ),
  );
}
```

#### Redesigned Balance Card
```dart
Widget _buildBalanceCard(WidgetRef ref, dynamic summary, String currencySymbol) {
  // Use a StatefulWidget or useState-equivalent for the eye toggle
  final actualBalance = summary?.actualBalance ?? 0.0;

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      gradient: AppColors.primaryGradient,
      borderRadius: BorderRadius.circular(AppSizing.radiusXl),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "Total Balance" + info icon
        Row(
          children: [
            Text('Total Balance', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
            const SizedBox(width: 4),
            Icon(LucideIcons.info, size: 14, color: Colors.white.withValues(alpha: 0.5)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Amount + eye toggle
        Row(
          children: [
            Text(
              '$currencySymbol${actualBalance.toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Eye toggle icon (use a local state variable _isBalanceVisible)
            Icon(LucideIcons.eye, size: 20, color: Colors.white.withValues(alpha: 0.7)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Percentage change badge
        _buildPercentageBadge(summary),
        const SizedBox(height: AppSpacing.lg),
        // "Add New Transaction" button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showAddTransaction(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizing.radiusMd)),
            ),
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('Add New Transaction', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    ),
  );
}
```

**Note:** Since the home screen needs local state for the eye toggle, it should become a `ConsumerStatefulWidget` instead of `ConsumerWidget`.

#### Upcoming Payments Section
```dart
Widget _buildUpcomingPayments(WidgetRef ref, String currencySymbol) {
  final upcomingAsync = ref.watch(upcomingSubscriptionsProvider);

  return upcomingAsync.when(
    data: (upcoming) {
      if (upcoming.isEmpty) return const SizedBox.shrink(); // Hide section if none upcoming

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Upcoming Payments', style: AppTypography.h3),
                    Text('Bills due soon', style: AppTypography.bodySmall),
                  ],
                ),
                TextButton(
                  onPressed: () => context.push('/subscriptions'),
                  child: Text('View All →', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Horizontal scroll of cards
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: upcoming.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final sub = upcoming[index];
                return _buildUpcomingCard(sub, currencySymbol);
              },
            ),
          ),
        ],
      );
    },
    loading: () => const SizedBox.shrink(),
    error: (_, __) => const SizedBox.shrink(),
  );
}
```

#### Upcoming Payment Card (per reference screenshot)
```dart
Widget _buildUpcomingCard(Subscription sub, String currencySymbol) {
  return Container(
    width: 180,
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSizing.radiusLg),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon + menu
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: sub.colorValue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
              ),
              child: Icon(_getIcon(sub.icon), color: sub.colorValue, size: 20),
            ),
            Icon(LucideIcons.moreVertical, size: 16, color: AppColors.textMuted),
          ],
        ),
        const Spacer(),
        // Name
        Text(sub.name, style: AppTypography.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        // Amount + cycle
        Text(
          '$currencySymbol${sub.amount.toStringAsFixed(0)}',
          style: AppTypography.amountMedium,
        ),
        Text('/${sub.billingCycleLabel.toLowerCase()}', style: AppTypography.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        // Due date chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: sub.isOverdue
                ? AppColors.error.withValues(alpha: 0.15)
                : AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppSizing.radiusFull),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.calendar, size: 12,
                color: sub.isOverdue ? AppColors.error : AppColors.primary),
              const SizedBox(width: 4),
              Text(
                sub.isDueToday ? 'Due today' : 'Due in ${sub.daysUntilDue} days',
                style: TextStyle(
                  fontSize: 11,
                  color: sub.isOverdue ? AppColors.error : AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
```

#### Subscriptions Preview Section
```dart
Widget _buildSubscriptionsPreview(WidgetRef ref, String currencySymbol) {
  final subsAsync = ref.watch(activeSubscriptionsProvider);
  final activeCount = subsAsync.value?.length ?? 0;

  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your Subscriptions', style: AppTypography.h3),
                Text('$activeCount active subscriptions', style: AppTypography.bodySmall),
              ],
            ),
            TextButton.icon(
              onPressed: () => _showAddSubscription(context),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Add New'),
            ),
          ],
        ),
      ),
      // Show top 3 subscriptions
      subsAsync.when(
        data: (subs) {
          final display = subs.take(3).toList();
          return Column(
            children: display.map((sub) => _buildSubscriptionRow(sub, currencySymbol)).toList(),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    ],
  );
}
```

---

### Step 3.2: Helper Functions in Home Screen

The home screen will need these helper methods:

- `_showAddTransaction(context)` — opens `TransactionFormSheet` via `showModalBottomSheet`
- `_showAddSubscription(context)` — opens `SubscriptionFormSheet` via `showModalBottomSheet`
- `_getIcon(String iconName)` — maps icon string to `IconData` (reuse the same map from `CategoryDetailScreen`)
- `_buildPercentageBadge(summary)` — calculates and shows the month-over-month % change

**Important providers to watch on the home screen:**
```dart
final activeMonth = ref.watch(activeMonthProvider);
final summary = ref.watch(monthlySummaryProvider);
final categories = ref.watch(categoriesProvider);
final currencySymbol = ref.watch(currencySymbolProvider);
final profile = ref.watch(userProfileProvider);           // NEW — for greeting
final upcoming = ref.watch(upcomingSubscriptionsProvider); // NEW — for upcoming section
final activeSubs = ref.watch(activeSubscriptionsProvider); // NEW — for subscriptions preview
```

---

### Stage 3 Verification

After completing Stage 3:
- Home page shows greeting with user's display name
- Balance card has gradient, eye toggle, percentage badge, and "Add New Transaction" button
- Upcoming Payments section shows subscription cards due within 7 days
- If no upcoming subscriptions, the section is hidden (not shown empty)
- "Your Subscriptions" preview shows top 3 active subscriptions
- Categories section still works as before
- Tapping "View All →" navigates to subscriptions tab
- "Add New" opens subscription form sheet
- All amounts use `currencySymbolProvider` — **no hardcoded currency**

---

# STAGE 4: Theme Refinements

---

### Step 4.1: Theme Additions (if needed)

**File:** `lib/config/theme.dart`

Add any missing constants discovered during implementation. Potential additions:

```dart
// In AppColors class:
static const Color surfaceDark = Color(0xFF0F172A);   // Darker surface for cards on gradient
static const Color accentPurple = Color(0xFF8B5CF6);   // Secondary accent

// In AppTypography class:
static const TextStyle greeting = TextStyle(
  color: AppColors.textSecondary,
  fontSize: 12,
  fontWeight: FontWeight.w600,
  letterSpacing: 1.2,
);
```

**Rule from CLAUDE.md Section 6:** Only add constants that are genuinely needed and will be reused. Don't over-engineer the theme.

---

## Guardrails — What Can Go Wrong

### CRITICAL: Currency Hardcoding

**Risk:** Hardcoding `₹` or `$` anywhere in the new UI.

**Rule:** Always use `ref.watch(currencySymbolProvider)`. The reference screenshot shows ₹ (INR) but our app supports GBP, USD, EUR, JPY, INR. See CLAUDE.md Section 6.3.

### CRITICAL: Provider Invalidation for Subscriptions

**Risk:** Adding/editing/deleting a subscription but the home page still shows stale data.

**Rule:** The `SubscriptionNotifier._invalidateAll()` method must invalidate:
- `subscriptionsProvider`
- `activeSubscriptionsProvider`
- `upcomingSubscriptionsProvider`

### CRITICAL: Don't Call Supabase from UI

**Risk:** Fetching subscriptions directly in the home screen widget.

**Rule:** Per CLAUDE.md Section 2.1 — Screens read from providers, providers call services, services talk to Supabase. Never skip layers.

### IMPORTANT: RLS Policies on New Table

**Risk:** Forgetting to add RLS policies to the subscriptions table, causing data to be invisible or accessible across users.

**Rule:** Per CLAUDE.md Section 5.1 — All tables MUST have RLS enabled with user_id policies. The SQL in Step 1.1 includes these. Run it in Supabase SQL Editor.

### IMPORTANT: Bottom Nav Restructuring

**Risk:** The existing centered FAB (add transaction button) is removed when restructuring to 5 tabs. Users lose the quick-add shortcut.

**Solution:** The "Add New Transaction" button is moved into the balance card on the home page. Also ensure the Transactions screen has its own add button.

### IMPORTANT: Eye Toggle State

**Risk:** The eye toggle (hide/show balance) requires local state but `ConsumerWidget` doesn't support `setState`.

**Solution:** Change `HomeScreen` from `ConsumerWidget` to `ConsumerStatefulWidget`. This is necessary for the toggle. Use a `bool _isBalanceVisible = true` state variable.

### MODERATE: Model Has `colorValue` Getter

**Risk:** The `Subscription` model has a `colorValue` getter that parses hex colors. If a user enters an invalid hex, it could crash.

**Solution:** The `colorValue` getter should handle invalid input gracefully. The existing `Category.colorValue` getter has the same pattern — follow it exactly.

### MODERATE: Subscription Due Date Auto-Advance

**Risk:** If `isAutoRenew` is true and the due date passes, the `calculatedNextDueDate` property shows the NEXT due date, but the database isn't updated until `markAsPaid()` is called.

**Rule:** Auto-advance only happens explicitly via `markAsPaid()`. The `daysUntilDue` and `isOverdue` getters work with the stored `nextDueDate`, so overdue subscriptions correctly show negative days / "Overdue" status.

---

## What NOT to Do

1. **Do NOT hardcode currency symbols** — use `currencySymbolProvider` (CLAUDE.md Section 6.3)
2. **Do NOT call Supabase from widgets** — use Service → Provider → UI (CLAUDE.md Section 2.1)
3. **Do NOT create the subscriptions table without RLS** — add all 4 policies (CLAUDE.md Section 5.1)
4. **Do NOT forget barrel file exports** — add to `models.dart`, `services.dart`, `providers.dart` (CLAUDE.md Section 10)
5. **Do NOT use `Navigator.push()`** — use GoRouter `context.push()` / `context.go()` (CLAUDE.md Section 7)
6. **Do NOT hardcode colors** — use `AppColors.*` constants (CLAUDE.md Section 6.1)
7. **Do NOT tie subscriptions to the items/categories table** — subscriptions are standalone entities
8. **Do NOT remove the add-transaction capability** — it moves from FAB to balance card button
9. **Do NOT use `ref.invalidate()` when data must be ready immediately** — use `await ref.refresh()` (CLAUDE.md Section 4.2)
10. **Do NOT add dependencies to `pubspec.yaml`** without team approval (CLAUDE.md Section 10, rule 9)

---

## Testing Checklist

### Stage 1 (Backend):
- [ ] `flutter analyze` passes
- [ ] App compiles and runs
- [ ] `subscriptions` table exists in Supabase with RLS policies

### Stage 2 (Navigation + Subscriptions UI):
- [ ] Bottom nav shows 5 tabs: Home, Transactions, Budget, Subscriptions, Settings
- [ ] Subscriptions tab opens the subscriptions screen
- [ ] Can add a new subscription via form sheet
- [ ] Subscription appears in the list after adding
- [ ] Can edit subscription (name, amount, due date, cycle)
- [ ] Can delete subscription (with confirmation)
- [ ] Can mark subscription as paid (due date advances)
- [ ] Can pause/resume subscription (toggle `isActive`)
- [ ] Total monthly cost displays correctly
- [ ] Currency uses `currencySymbolProvider`

### Stage 3 (Home Redesign):
- [ ] Greeting shows user's display name from profile
- [ ] Balance card has gradient background
- [ ] Eye toggle hides/shows balance amount
- [ ] Percentage badge shows month progress
- [ ] "Add New Transaction" button works (opens form sheet)
- [ ] Upcoming Payments shows subscriptions due within 7 days
- [ ] Upcoming section hidden when no subscriptions are due
- [ ] "View All →" navigates to Subscriptions tab
- [ ] "Your Subscriptions" shows top 3 active subscriptions
- [ ] "Add New" opens subscription form
- [ ] Quick stats (Income/Expenses) still work
- [ ] Categories list still works and navigates correctly
- [ ] Pull-to-refresh works on all sections
- [ ] No hardcoded currency symbols anywhere

### Stage 4 (Theme):
- [ ] All new UI elements use `AppColors`, `AppTypography`, `AppSpacing` constants
- [ ] No hardcoded color values (e.g., `Color(0xFF...)`)
- [ ] Dark theme consistency maintained
- [ ] Cards have consistent border radius and spacing

---

## Summary of All Files

| File | Action | Stage |
|------|--------|-------|
| `supabase_schema.sql` | Add subscriptions table + RLS + indexes | 1 |
| `lib/models/subscription.dart` | **NEW** — Subscription model | 1 |
| `lib/services/subscription_service.dart` | **NEW** — CRUD service | 1 |
| `lib/providers/subscription_provider.dart` | **NEW** — Providers + notifier | 1 |
| `lib/models/models.dart` | Add export | 1 |
| `lib/services/services.dart` | Add export | 1 |
| `lib/providers/providers.dart` | Add export | 1 |
| `lib/config/routes.dart` | Add `/subscriptions` route | 2 |
| `lib/widgets/navigation/app_shell.dart` | Restructure to 5 tabs | 2 |
| `lib/screens/subscriptions/subscriptions_screen.dart` | **NEW** — Main subscriptions screen | 2 |
| `lib/screens/subscriptions/subscription_form_sheet.dart` | **NEW** — Add/edit form | 2 |
| `lib/screens/home/home_screen.dart` | **FULL REWRITE** — Premium redesign | 3 |
| `lib/config/theme.dart` | Add new constants if needed | 4 |

**Total: 13 files (5 new, 8 modified)**

---

*Created: 2026-02-06*
*Feature: Home Page Redesign + Subscriptions + Upcoming Payments*
*Follows: CLAUDE.md engineering guidelines*
