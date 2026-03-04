import 'package:budgetwise/config/theme.dart';
import 'package:budgetwise/providers/auth_provider.dart';
import 'package:budgetwise/screens/auth/reset_password_screen.dart';
import 'package:budgetwise/services/auth_service.dart';
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

  Future<void> pumpResetScreen(
    WidgetTester tester, {
    required ProviderContainer container,
  }) async {
    final router = GoRouter(
      initialLocation: '/reset-password',
      routes: [
        GoRoute(
          path: '/reset-password',
          builder: (context, state) => const ResetPasswordScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('login')),
          ),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('home')),
          ),
        ),
      ],
    );

    addTearDown(router.dispose);
    addTearDown(container.dispose);
    await tester.binding.setSurfaceSize(const Size(1200, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders invalid state when there is no recovery session',
      (tester) async {
    final service = _FakeAuthService(currentUser: null);
    final container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(service),
        currentUserProvider.overrideWith((ref) => null),
      ],
    );

    await pumpResetScreen(tester, container: container);

    expect(find.text('Invalid or expired link'), findsOneWidget);
    expect(find.text('Return to Login'), findsOneWidget);
  });

  testWidgets('mismatched passwords block submit', (tester) async {
    final service = _FakeAuthService(currentUser: _fakeUser());
    final container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(service),
        currentUserProvider.overrideWith((ref) => _fakeUser()),
      ],
    );

    await pumpResetScreen(tester, container: container);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'StrongPass1!',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'DifferentPass1!',
    );
    await tester.tap(find.text('Update Password'));
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(service.updateCalls, 0);
  });

  testWidgets(
      'successful password update clears recovery state and routes home',
      (tester) async {
    final service = _FakeAuthService(currentUser: _fakeUser());
    final container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(service),
        currentUserProvider.overrideWith((ref) => _fakeUser()),
        passwordRecoveryPendingProvider.overrideWith((ref) => true),
      ],
    );

    await pumpResetScreen(tester, container: container);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'StrongPass1!',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'StrongPass1!',
    );
    await tester.tap(find.text('Update Password'));
    await tester.pumpAndSettle();

    expect(service.updateCalls, 1);
    expect(container.read(passwordRecoveryPendingProvider), isFalse);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('cancel signs out, clears recovery state, and routes to login',
      (tester) async {
    final service = _FakeAuthService(currentUser: _fakeUser());
    late _FakeAuthNotifier notifier;
    final container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(service),
        currentUserProvider.overrideWith((ref) => _fakeUser()),
        passwordRecoveryPendingProvider.overrideWith((ref) => true),
        authNotifierProvider.overrideWith((ref) {
          notifier = _FakeAuthNotifier(service, ref);
          return notifier;
        }),
      ],
    );

    await pumpResetScreen(tester, container: container);

    await tester.tap(find.text('Cancel and return to login'));
    await tester.pumpAndSettle();

    expect(notifier.signOutCalls, 1);
    expect(container.read(passwordRecoveryPendingProvider), isFalse);
    expect(find.text('login'), findsOneWidget);
  });
}

class _FakeAuthService extends AuthService {
  _FakeAuthService({required this.currentUser});

  @override
  final User? currentUser;

  var updateCalls = 0;

  @override
  Future<UserResponse> updatePassword(String newPassword) async {
    updateCalls += 1;
    return UserResponse.fromJson({
      'id': currentUser?.id ?? 'user-1',
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': currentUser?.email ?? 'user@example.com',
      'created_at': DateTime.utc(2026, 1, 1).toIso8601String(),
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
    });
  }
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(super.authService, super.ref);

  var signOutCalls = 0;

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
    state = const AsyncValue.data(null);
  }
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
