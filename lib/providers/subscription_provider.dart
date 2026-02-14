import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/subscription.dart';
import '../services/subscription_service.dart';
import '../utils/errors/app_error.dart';
import 'account_provider.dart';
import 'auth_provider.dart';
import 'category_provider.dart';
import 'item_provider.dart';
import 'month_provider.dart';
import 'transaction_provider.dart';

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
final activeSubscriptionsProvider =
    FutureProvider<List<Subscription>>((ref) async {
  final service = ref.read(subscriptionServiceProvider);
  return service.getActiveSubscriptions();
});

/// Subscriptions due within the next 7 days (for home page "Upcoming Payments")
final upcomingSubscriptionsProvider =
    FutureProvider<List<Subscription>>((ref) async {
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
  final Set<String> _inFlightPaymentSubscriptionIds = <String>{};

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
    String? defaultAccountId,
    int reminderDaysBefore = 2,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw const AppError.unauthenticated();

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
      defaultAccountId: defaultAccountId,
      reminderDaysBefore: reminderDaysBefore,
    );

    await _syncSubscriptionItems();
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
    String? defaultAccountId,
    bool clearDefaultAccountId = false,
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
      defaultAccountId: defaultAccountId,
      clearDefaultAccountId: clearDefaultAccountId,
      isActive: isActive,
      reminderDaysBefore: reminderDaysBefore,
    );

    await _syncSubscriptionItems();
    _invalidateAll();
    return sub;
  }

  Future<void> deleteSubscription(String subscriptionId) async {
    await _service.deleteSubscription(subscriptionId);
    _invalidateAll();
  }

  Future<SubscriptionPaymentResult> markAsPaid(
    String subscriptionId, {
    String? accountId,
  }) async {
    if (_inFlightPaymentSubscriptionIds.contains(subscriptionId)) {
      await _service.logPaymentEvent(
        subscriptionId: subscriptionId,
        status: 'duplicate_blocked_client',
        paidAt: DateTime.now(),
        duplicatePrevented: true,
        details: {
          'reason': 'mark_as_paid_already_in_flight',
        },
      );
      throw StateError('Payment is already being processed');
    }

    _inFlightPaymentSubscriptionIds.add(subscriptionId);
    try {
      final result = await _service.markSubscriptionPaidAtomic(
        subscriptionId: subscriptionId,
        paidAt: DateTime.now(),
        accountId: accountId,
      );

      _invalidateAll();
      return result;
    } finally {
      _inFlightPaymentSubscriptionIds.remove(subscriptionId);
    }
  }

  void _invalidateAll() {
    ref.invalidateSelf();
    ref.invalidate(subscriptionsProvider);
    ref.invalidate(activeSubscriptionsProvider);
    ref.invalidate(upcomingSubscriptionsProvider);
    ref.invalidate(transactionsProvider);
    ref.invalidate(categoriesProvider);
    ref.invalidate(accountBalancesProvider);
    ref.invalidate(allAccountBalancesProvider);
    ref.invalidate(netWorthProvider);
  }

  /// Sync subscription items in the current month's Subscriptions category.
  Future<void> _syncSubscriptionItems() async {
    try {
      final monthService = ref.read(monthServiceProvider);
      final categoryService = ref.read(categoryServiceProvider);
      final itemService = ref.read(itemServiceProvider);

      final now = DateTime.now();
      final currentMonth = await monthService.getMonthForDate(now);
      final subsCat =
          await categoryService.ensureSubscriptionsCategory(currentMonth.id);
      final activeSubs = await _service.getActiveSubscriptions();
      await itemService.repairSubscriptionItemsForCategory(
        subscriptionsCategoryId: subsCat.id,
        activeSubscriptions: activeSubs,
      );
    } catch (_) {
      // Sync failed - not critical, will retry on next app startup
    }
  }
}

final subscriptionNotifierProvider =
    AsyncNotifierProvider<SubscriptionNotifier, List<Subscription>>(
        () => SubscriptionNotifier());
