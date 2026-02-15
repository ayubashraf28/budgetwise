import 'package:budgetwise/config/routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveAppRedirect', () {
    test('redirects unauthenticated users away from protected route', () {
      final redirect = resolveAppRedirect(
        isLoggedIn: false,
        matchedLocation: '/home',
        onboardingCompleted: false,
      );

      expect(redirect, '/login');
    });

    test('allows unauthenticated users on login/register routes', () {
      final loginRedirect = resolveAppRedirect(
        isLoggedIn: false,
        matchedLocation: '/login',
        onboardingCompleted: false,
      );
      final registerRedirect = resolveAppRedirect(
        isLoggedIn: false,
        matchedLocation: '/register',
        onboardingCompleted: false,
      );

      expect(loginRedirect, isNull);
      expect(registerRedirect, isNull);
    });

    test('forces onboarding when signed in and onboarding incomplete', () {
      final redirect = resolveAppRedirect(
        isLoggedIn: true,
        matchedLocation: '/home',
        onboardingCompleted: false,
      );

      expect(redirect, '/onboarding');
    });

    test('blocks returning to onboarding once completed', () {
      final redirect = resolveAppRedirect(
        isLoggedIn: true,
        matchedLocation: '/onboarding/template',
        onboardingCompleted: true,
      );

      expect(redirect, '/home');
    });

    test('allows post-completion onboarding notification step', () {
      final redirect = resolveAppRedirect(
        isLoggedIn: true,
        matchedLocation: '/onboarding/notifications',
        onboardingCompleted: true,
      );

      expect(redirect, isNull);
    });

    test('allows setup complete route when onboarding already completed', () {
      final redirect = resolveAppRedirect(
        isLoggedIn: true,
        matchedLocation: '/onboarding/complete',
        onboardingCompleted: true,
      );

      expect(redirect, isNull);
    });
  });

  group('resolveOnboardingCompletedForRedirect', () {
    test('returns cached value and skips loader', () async {
      var loaderCalls = 0;

      final result = await resolveOnboardingCompletedForRedirect(
        cachedValue: const AsyncData<bool>(false),
        loadOnboardingCompleted: () async {
          loaderCalls += 1;
          return true;
        },
      );

      expect(result, isFalse);
      expect(loaderCalls, 0);
    });

    test('fails closed when loader throws', () async {
      var loaderCalls = 0;

      final result = await resolveOnboardingCompletedForRedirect(
        cachedValue: const AsyncLoading<bool>(),
        loadOnboardingCompleted: () async {
          loaderCalls += 1;
          throw Exception('network failure');
        },
      );

      expect(result, isFalse);
      expect(loaderCalls, 1);
    });

    test('fails closed when loader times out', () async {
      final result = await resolveOnboardingCompletedForRedirect(
        cachedValue: const AsyncLoading<bool>(),
        loadOnboardingCompleted: () async {
          await Future<void>.delayed(const Duration(milliseconds: 25));
          return false;
        },
        timeout: const Duration(milliseconds: 1),
      );

      expect(result, isFalse);
    });
  });
}
