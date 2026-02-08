import 'package:budgetwise/utils/subscription_payment_feedback.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shows duplicate message when duplicate was prevented', () {
    final feedback = buildSubscriptionPaymentFeedback(
      subscriptionName: 'Spotify',
      paidMonthName: 'February 2026',
      isDifferentMonth: true,
      duplicatePrevented: true,
    );

    expect(feedback.message, 'Payment already recorded in February 2026');
    expect(feedback.showViewMonthAction, isFalse);
  });

  test('shows cross-month message and action when month differs', () {
    final feedback = buildSubscriptionPaymentFeedback(
      subscriptionName: 'Spotify',
      paidMonthName: 'March 2026',
      isDifferentMonth: true,
      duplicatePrevented: false,
    );

    expect(feedback.message, 'Spotify paid. Recorded in March 2026');
    expect(feedback.showViewMonthAction, isTrue);
  });

  test('shows in-month success message without action', () {
    final feedback = buildSubscriptionPaymentFeedback(
      subscriptionName: 'Spotify',
      paidMonthName: 'February 2026',
      isDifferentMonth: false,
      duplicatePrevented: false,
    );

    expect(feedback.message, 'Spotify marked as paid');
    expect(feedback.showViewMonthAction, isFalse);
  });
}
