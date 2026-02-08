import 'package:budgetwise/models/subscription.dart';
import 'package:budgetwise/providers/subscription_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Subscription _sub({
  required String id,
  required double amount,
  required BillingCycle cycle,
  int? customCycleDays,
  bool isActive = true,
}) {
  final now = DateTime.now();
  return Subscription(
    id: id,
    userId: 'user-1',
    name: 'Sub-$id',
    amount: amount,
    billingCycle: cycle,
    customCycleDays: customCycleDays,
    nextDueDate: now,
    isActive: isActive,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('totalSubscriptionCostProvider normalizes mixed billing cycles',
      () async {
    final subscriptions = <Subscription>[
      _sub(id: 'w', amount: 10, cycle: BillingCycle.weekly),
      _sub(id: 'm', amount: 30, cycle: BillingCycle.monthly),
      _sub(id: 'q', amount: 90, cycle: BillingCycle.quarterly),
      _sub(id: 'y', amount: 120, cycle: BillingCycle.yearly),
      _sub(
          id: 'c', amount: 60, cycle: BillingCycle.custom, customCycleDays: 60),
    ];

    final container = ProviderContainer(
      overrides: [
        activeSubscriptionsProvider.overrideWith((ref) async => subscriptions),
      ],
    );
    addTearDown(container.dispose);

    await container.read(activeSubscriptionsProvider.future);

    final monthlyTotal = container.read(totalSubscriptionCostProvider);
    const expected = (10 * 4.33) + 30 + (90 / 3) + (120 / 12) + (60 * 30 / 60);
    expect(monthlyTotal, closeTo(expected, 0.001));
  });

  test('dueSoonCountProvider returns upcoming subscriptions count', () async {
    final upcoming = <Subscription>[
      _sub(id: '1', amount: 10, cycle: BillingCycle.monthly),
      _sub(id: '2', amount: 10, cycle: BillingCycle.monthly),
      _sub(id: '3', amount: 10, cycle: BillingCycle.monthly),
    ];

    final container = ProviderContainer(
      overrides: [
        upcomingSubscriptionsProvider.overrideWith((ref) async => upcoming),
      ],
    );
    addTearDown(container.dispose);

    await container.read(upcomingSubscriptionsProvider.future);

    expect(container.read(dueSoonCountProvider), 3);
  });
}
