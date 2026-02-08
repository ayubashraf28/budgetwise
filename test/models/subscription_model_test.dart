import 'package:budgetwise/models/subscription.dart';
import 'package:flutter_test/flutter_test.dart';

Subscription _buildSubscription({
  BillingCycle billingCycle = BillingCycle.monthly,
  DateTime? nextDueDate,
  bool isAutoRenew = true,
  int? customCycleDays,
}) {
  final now = DateTime.now();
  return Subscription(
    id: 'sub-1',
    userId: 'user-1',
    name: 'Spotify',
    amount: 12.99,
    billingCycle: billingCycle,
    nextDueDate: nextDueDate ?? DateTime(now.year, now.month, now.day),
    isAutoRenew: isAutoRenew,
    customCycleDays: customCycleDays,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('Subscription.calculatedNextDueDate', () {
    test('advances weekly by 7 days', () {
      final sub = _buildSubscription(
        billingCycle: BillingCycle.weekly,
        nextDueDate: DateTime(2026, 2, 10),
      );

      expect(sub.calculatedNextDueDate, DateTime(2026, 2, 17));
    });

    test('advances monthly from due date anchor', () {
      final sub = _buildSubscription(
        billingCycle: BillingCycle.monthly,
        nextDueDate: DateTime(2026, 2, 10),
      );

      expect(sub.calculatedNextDueDate, DateTime(2026, 3, 10));
    });

    test('advances quarterly by 3 months', () {
      final sub = _buildSubscription(
        billingCycle: BillingCycle.quarterly,
        nextDueDate: DateTime(2026, 2, 10),
      );

      expect(sub.calculatedNextDueDate, DateTime(2026, 5, 10));
    });

    test('advances yearly by 1 year', () {
      final sub = _buildSubscription(
        billingCycle: BillingCycle.yearly,
        nextDueDate: DateTime(2026, 2, 10),
      );

      expect(sub.calculatedNextDueDate, DateTime(2027, 2, 10));
    });

    test('advances custom by customCycleDays', () {
      final sub = _buildSubscription(
        billingCycle: BillingCycle.custom,
        customCycleDays: 45,
        nextDueDate: DateTime(2026, 2, 10),
      );

      expect(sub.calculatedNextDueDate, DateTime(2026, 3, 27));
    });

    test('does not advance when auto-renew is disabled', () {
      final dueDate = DateTime(2026, 2, 10);
      final sub = _buildSubscription(
        billingCycle: BillingCycle.monthly,
        nextDueDate: dueDate,
        isAutoRenew: false,
      );

      expect(sub.calculatedNextDueDate, dueDate);
    });
  });

  group('Subscription status helpers', () {
    test('detects overdue and due today and due soon states', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final overdue = _buildSubscription(
          nextDueDate: today.subtract(const Duration(days: 1)));
      final dueToday = _buildSubscription(nextDueDate: today);
      final dueSoon =
          _buildSubscription(nextDueDate: today.add(const Duration(days: 3)));

      expect(overdue.isOverdue, isTrue);
      expect(dueToday.isDueToday, isTrue);
      expect(dueSoon.isDueSoon, isTrue);
    });
  });
}
