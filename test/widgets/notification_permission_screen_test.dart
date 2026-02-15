import 'package:budgetwise/config/theme.dart';
import 'package:budgetwise/models/user_profile.dart';
import 'package:budgetwise/providers/notification_provider.dart';
import 'package:budgetwise/providers/profile_provider.dart';
import 'package:budgetwise/screens/onboarding/notification_permission_screen.dart';
import 'package:budgetwise/services/notification_service.dart';
import 'package:budgetwise/services/profile_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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

  testWidgets('skip sets notification preferences off and navigates home',
      (tester) async {
    final fakeProfileService = _FakeProfileService();
    final fakeNotificationService = _FakeNotificationService(granted: true);

    await _pumpScreen(
      tester,
      fakeProfileService: fakeProfileService,
      fakeNotificationService: fakeNotificationService,
    );

    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();

    expect(find.text('Home Screen'), findsOneWidget);
    expect(fakeProfileService.updateCallCount, 1);
    expect(fakeProfileService.current.notificationsEnabled, isFalse);
    expect(fakeProfileService.current.subscriptionRemindersEnabled, isFalse);
    expect(fakeProfileService.current.budgetAlertsEnabled, isFalse);
    expect(fakeProfileService.current.monthlyRemindersEnabled, isFalse);
  });

  testWidgets('enable requests permission, saves enabled prefs, navigates home',
      (tester) async {
    final fakeProfileService = _FakeProfileService();
    final fakeNotificationService = _FakeNotificationService(granted: true);

    await _pumpScreen(
      tester,
      fakeProfileService: fakeProfileService,
      fakeNotificationService: fakeNotificationService,
    );

    await tester.tap(find.text('Enable Notifications'));
    await tester.pumpAndSettle();

    expect(find.text('Home Screen'), findsOneWidget);
    expect(fakeNotificationService.requestCallCount, 1);
    expect(fakeProfileService.updateCallCount, 1);
    expect(fakeProfileService.current.notificationsEnabled, isTrue);
    expect(fakeProfileService.current.subscriptionRemindersEnabled, isTrue);
    expect(fakeProfileService.current.budgetAlertsEnabled, isTrue);
    expect(fakeProfileService.current.monthlyRemindersEnabled, isTrue);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _FakeProfileService fakeProfileService,
  required _FakeNotificationService fakeNotificationService,
}) async {
  final router = GoRouter(
    initialLocation: '/onboarding/notifications',
    routes: [
      GoRoute(
        path: '/onboarding/notifications',
        builder: (_, __) => const NotificationPermissionScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const Scaffold(
          body: Center(child: Text('Home Screen')),
        ),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profileServiceProvider.overrideWithValue(fakeProfileService),
        notificationServiceProvider.overrideWithValue(fakeNotificationService),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeNotificationService extends NotificationService {
  _FakeNotificationService({required this.granted}) : super();

  final bool granted;
  int requestCallCount = 0;

  @override
  Future<bool> requestPermissionIfNeeded() async {
    requestCallCount += 1;
    return granted;
  }
}

class _FakeProfileService extends ProfileService {
  UserProfile current = UserProfile(
    id: 'profile-1',
    userId: 'user-1',
    displayName: 'User',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
  int updateCallCount = 0;

  @override
  Future<UserProfile?> getCurrentProfile() async => current;

  @override
  Future<UserProfile> updateProfile({
    String? displayName,
    String? currency,
    String? locale,
    bool? onboardingCompleted,
    bool? notificationsEnabled,
    bool? subscriptionRemindersEnabled,
    bool? budgetAlertsEnabled,
    bool? monthlyRemindersEnabled,
  }) async {
    updateCallCount += 1;
    current = current.copyWith(
      displayName: displayName,
      currency: currency,
      locale: locale,
      onboardingCompleted: onboardingCompleted,
      notificationsEnabled: notificationsEnabled,
      subscriptionRemindersEnabled: subscriptionRemindersEnabled,
      budgetAlertsEnabled: budgetAlertsEnabled,
      monthlyRemindersEnabled: monthlyRemindersEnabled,
      updatedAt: DateTime.utc(2026, 1, 2),
    );
    return current;
  }
}
