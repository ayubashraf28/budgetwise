import 'dart:async';

import 'package:budgetwise/models/subscription.dart';
import 'package:budgetwise/providers/subscription_provider.dart';
import 'package:budgetwise/services/subscription_service.dart';
import 'package:budgetwise/utils/errors/app_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    try {
      await Supabase.initialize(
        url: 'https://example.supabase.co',
        anonKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIn0.c2lnbmF0dXJl',
      );
    } catch (_) {
      // Already initialized in this test process.
    }
  });

  test('markAsPaid blocks duplicate in-flight requests', () async {
    final fakeService = _FakeSubscriptionService();
    final container = ProviderContainer(
      overrides: [
        subscriptionServiceProvider.overrideWithValue(fakeService),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(subscriptionNotifierProvider.notifier);
    final first = notifier.markAsPaid('sub-1');

    await expectLater(
      () => notifier.markAsPaid('sub-1'),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('already being processed'),
        ),
      ),
    );

    expect(fakeService.markCallCount, 1);
    expect(fakeService.loggedEvents.length, 1);
    expect(fakeService.loggedEvents.single.status, 'duplicate_blocked_client');
    expect(fakeService.loggedEvents.single.duplicatePrevented, isTrue);

    fakeService.inFlightCompleter.complete(_paymentResult());
    await first;
  });

  test('markAsPaid clears in-flight flag after failure', () async {
    final fakeService = _FakeSubscriptionService()
      ..throwOnMark = const AppError.database(
        technicalMessage: 'mark failed',
      );
    final container = ProviderContainer(
      overrides: [
        subscriptionServiceProvider.overrideWithValue(fakeService),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(subscriptionNotifierProvider.notifier);

    await expectLater(
      () => notifier.markAsPaid('sub-1'),
      throwsA(isA<AppError>()),
    );
    await expectLater(
      () => notifier.markAsPaid('sub-1'),
      throwsA(isA<AppError>()),
    );

    expect(fakeService.markCallCount, 2);
    expect(fakeService.loggedEvents, isEmpty);
  });
}

SubscriptionPaymentResult _paymentResult() {
  final now = DateTime.utc(2026, 1, 10);
  return SubscriptionPaymentResult(
    transactionId: 'tx-1',
    monthId: 'month-1',
    monthName: 'January 2026',
    categoryId: 'cat-1',
    itemId: 'item-1',
    subscriptionId: 'sub-1',
    amount: 19.99,
    paidAt: now,
    nextDueDate: now.add(const Duration(days: 30)),
    duplicatePrevented: false,
  );
}

class _LoggedPaymentEvent {
  final String status;
  final bool duplicatePrevented;

  const _LoggedPaymentEvent({
    required this.status,
    required this.duplicatePrevented,
  });
}

class _FakeSubscriptionService extends SubscriptionService {
  final Completer<SubscriptionPaymentResult> inFlightCompleter =
      Completer<SubscriptionPaymentResult>();
  final List<_LoggedPaymentEvent> loggedEvents = <_LoggedPaymentEvent>[];

  int markCallCount = 0;
  Object? throwOnMark;

  @override
  Future<List<Subscription>> getSubscriptions() async => const <Subscription>[];

  @override
  Future<SubscriptionPaymentResult> markSubscriptionPaidAtomic({
    required String subscriptionId,
    DateTime? paidAt,
    double? amountOverride,
    String? requestId,
    String? accountId,
  }) async {
    markCallCount += 1;
    if (throwOnMark != null) {
      throw throwOnMark!;
    }
    return inFlightCompleter.future;
  }

  @override
  Future<void> logPaymentEvent({
    String? requestId,
    required String subscriptionId,
    required String status,
    DateTime? paidAt,
    String? transactionId,
    bool duplicatePrevented = false,
    String? errorMessage,
    Map<String, dynamic>? details,
  }) async {
    loggedEvents.add(
      _LoggedPaymentEvent(
        status: status,
        duplicatePrevented: duplicatePrevented,
      ),
    );
  }
}
