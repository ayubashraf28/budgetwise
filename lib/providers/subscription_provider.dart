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

