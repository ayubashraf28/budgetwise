import 'package:budgetwise/services/subscription_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SubscriptionPaymentResult.fromRpc maps all expected fields', () {
    final result = SubscriptionPaymentResult.fromRpc({
      'transaction_id': 'tx-1',
      'month_id': 'month-1',
      'month_name': 'February 2026',
      'category_id': 'cat-1',
      'item_id': 'item-1',
      'subscription_id': 'sub-1',
      'amount': 48.5,
      'paid_at': '2026-02-08',
      'next_due_date': '2026-03-08',
      'duplicate_prevented': true,
    });

    expect(result.transactionId, 'tx-1');
    expect(result.monthId, 'month-1');
    expect(result.monthName, 'February 2026');
    expect(result.categoryId, 'cat-1');
    expect(result.itemId, 'item-1');
    expect(result.subscriptionId, 'sub-1');
    expect(result.amount, 48.5);
    expect(result.paidAt, DateTime(2026, 2, 8));
    expect(result.nextDueDate, DateTime(2026, 3, 8));
    expect(result.duplicatePrevented, isTrue);
  });

  test('SubscriptionPaymentResult.fromRpc defaults duplicatePrevented to false',
      () {
    final result = SubscriptionPaymentResult.fromRpc({
      'transaction_id': 'tx-1',
      'month_id': 'month-1',
      'category_id': 'cat-1',
      'item_id': 'item-1',
      'subscription_id': 'sub-1',
      'amount': 25,
      'paid_at': '2026-02-08',
      'next_due_date': '2026-03-08',
    });

    expect(result.duplicatePrevented, isFalse);
  });
}
