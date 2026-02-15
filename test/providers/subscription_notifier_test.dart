import 'dart:async';

import 'package:budgetwise/models/subscription.dart';
import 'package:budgetwise/providers/auth_provider.dart';
import 'package:budgetwise/providers/notification_provider.dart';
import 'package:budgetwise/providers/subscription_provider.dart';
import 'package:budgetwise/services/notification_service.dart';
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
    final fakeNotificationService = _FakeNotificationService();
    final container = ProviderContainer(
      overrides: [
        subscriptionServiceProvider.overrideWithValue(fakeService),
        notificationServiceProvider.overrideWithValue(fakeNotificationService),
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

  test('addSubscription schedules reminder', () async {
    final fakeService = _FakeSubscriptionService();
    final fakeNotificationService = _FakeNotificationService();
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith((ref) => _fakeUser()),
        subscriptionServiceProvider.overrideWithValue(fakeService),
        notificationServiceProvider.overrideWithValue(fakeNotificationService),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(subscriptionNotifierProvider.notifier);
    await notifier.addSubscription(
      name: 'Streaming',
      amount: 12.99,
      nextDueDate: DateTime.utc(2026, 2, 1),
    );

    expect(fakeService.createCallCount, 1);
    expect(fakeNotificationService.scheduledSubscriptionIds, contains('sub-1'));
  });

  test('updateSubscription reschedules reminder', () async {
    final fakeService = _FakeSubscriptionService();
    final fakeNotificationService = _FakeNotificationService();
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith((ref) => _fakeUser()),
        subscriptionServiceProvider.overrideWithValue(fakeService),
        notificationServiceProvider.overrideWithValue(fakeNotificationService),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(subscriptionNotifierProvider.notifier);
    await notifier.updateSubscription(
      subscriptionId: 'sub-1',
      amount: 24.99,
    );

    expect(fakeService.updateCallCount, 1);
    expect(fakeNotificationService.scheduledSubscriptionIds, contains('sub-1'));
  });

  test('markAsPaid clears in-flight flag after failure', () async {
    final fakeService = _FakeSubscriptionService()
      ..throwOnMark = const AppError.database(
        technicalMessage: 'mark failed',
      );
    final fakeNotificationService = _FakeNotificationService();
    final container = ProviderContainer(
      overrides: [
        subscriptionServiceProvider.overrideWithValue(fakeService),
        notificationServiceProvider.overrideWithValue(fakeNotificationService),
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

  test('markAsPaid reschedules reminder when updated subscription is available',
      () async {
    final fakeService = _FakeSubscriptionService()
      ..subscriptionById = _subscription();
    final fakeNotificationService = _FakeNotificationService();
    final container = ProviderContainer(
      overrides: [
        subscriptionServiceProvider.overrideWithValue(fakeService),
        notificationServiceProvider.overrideWithValue(fakeNotificationService),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(subscriptionNotifierProvider.notifier);
    final future = notifier.markAsPaid('sub-1');

    fakeService.inFlightCompleter.complete(_paymentResult());
    await future;

    expect(fakeNotificationService.scheduledSubscriptionIds, contains('sub-1'));
  });

  test('deleteSubscription cancels scheduled reminder', () async {
    final fakeService = _FakeSubscriptionService();
    final fakeNotificationService = _FakeNotificationService();
    final container = ProviderContainer(
      overrides: [
        subscriptionServiceProvider.overrideWithValue(fakeService),
        notificationServiceProvider.overrideWithValue(fakeNotificationService),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(subscriptionNotifierProvider.notifier);
    await notifier.deleteSubscription('sub-1');

    expect(fakeNotificationService.cancelledSubscriptionIds, contains('sub-1'));
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

User _fakeUser() {
  return User.fromJson({
    'id': 'user-1',
    'aud': 'authenticated',
    'role': 'authenticated',
    'email': 'user@example.com',
    'created_at': DateTime.utc(2026, 1, 1).toIso8601String(),
    'app_metadata': <String, dynamic>{},
    'user_metadata': <String, dynamic>{},
  })!;
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
  Subscription? subscriptionById;
  final List<String> deletedIds = <String>[];
  int createCallCount = 0;
  int updateCallCount = 0;

  @override
  Future<List<Subscription>> getSubscriptions() async => const <Subscription>[];

  @override
  Future<Subscription?> getSubscriptionById(String subscriptionId) async {
    return subscriptionById;
  }

  @override
  Future<void> deleteSubscription(String subscriptionId) async {
    deletedIds.add(subscriptionId);
  }

  @override
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
    String? defaultAccountId,
    int reminderDaysBefore = 2,
  }) async {
    createCallCount += 1;
    return _subscription().copyWith(
      name: name,
      amount: amount,
      nextDueDate: nextDueDate,
      reminderDaysBefore: reminderDaysBefore,
    );
  }

  @override
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
    updateCallCount += 1;
    return _subscription().copyWith(
      id: subscriptionId,
      name: name,
      amount: amount,
      nextDueDate: nextDueDate,
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
  }

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

class _FakeNotificationService extends NotificationService {
  _FakeNotificationService() : super();

  final List<String> scheduledSubscriptionIds = <String>[];
  final List<String> cancelledSubscriptionIds = <String>[];

  @override
  Future<void> scheduleSubscriptionReminder(Subscription subscription) async {
    scheduledSubscriptionIds.add(subscription.id);
  }

  @override
  Future<void> cancelSubscriptionReminder(String subscriptionId) async {
    cancelledSubscriptionIds.add(subscriptionId);
  }
}

Subscription _subscription() {
  final now = DateTime.utc(2026, 1, 10);
  return Subscription(
    id: 'sub-1',
    userId: 'user-1',
    name: 'Service',
    amount: 19.99,
    nextDueDate: now.add(const Duration(days: 30)),
    createdAt: now,
    updatedAt: now,
  );
}
