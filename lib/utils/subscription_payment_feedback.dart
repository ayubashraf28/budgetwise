class SubscriptionPaymentFeedback {
  final String message;
  final bool showViewMonthAction;

  const SubscriptionPaymentFeedback({
    required this.message,
    required this.showViewMonthAction,
  });
}

SubscriptionPaymentFeedback buildSubscriptionPaymentFeedback({
  required String subscriptionName,
  required String paidMonthName,
  required bool isDifferentMonth,
  required bool duplicatePrevented,
}) {
  if (duplicatePrevented) {
    return SubscriptionPaymentFeedback(
      message: 'Payment already recorded in $paidMonthName',
      showViewMonthAction: false,
    );
  }

  if (isDifferentMonth) {
    return SubscriptionPaymentFeedback(
      message: '$subscriptionName paid. Recorded in $paidMonthName',
      showViewMonthAction: true,
    );
  }

  return SubscriptionPaymentFeedback(
    message: '$subscriptionName marked as paid',
    showViewMonthAction: false,
  );
}
