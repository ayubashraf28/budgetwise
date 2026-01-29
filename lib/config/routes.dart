import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/income/income_screen.dart';
import '../screens/expenses/expenses_overview_screen.dart';
import '../screens/expenses/category_detail_screen.dart';
import '../screens/transactions/transactions_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/onboarding/welcome_screen.dart';
import '../screens/onboarding/template_selection_screen.dart';
import '../screens/onboarding/setup_complete_screen.dart';
import '../widgets/navigation/app_shell.dart';
import '../services/profile_service.dart';

/// A Listenable that notifies when auth state changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    notifyListeners();
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Provider for the auth refresh listenable
final routerRefreshProvider = Provider<GoRouterRefreshStream>((ref) {
  final stream = Supabase.instance.client.auth.onAuthStateChange;
  return GoRouterRefreshStream(stream);
});

/// Main router provider
final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ref.watch(routerRefreshProvider);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    refreshListenable: refreshListenable,
    redirect: (context, state) async {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final isLoggingIn = state.matchedLocation == '/login';
      final isRegistering = state.matchedLocation == '/register';
      final isOnboarding = state.matchedLocation.startsWith('/onboarding');

      // If not logged in, redirect to login (unless already there or registering)
      if (!isLoggedIn) {
        if (isLoggingIn || isRegistering) return null;
        return '/login';
      }

      // If logged in and on auth pages, check onboarding status
      if (isLoggedIn && (isLoggingIn || isRegistering)) {
        final profileService = ProfileService();
        final onboardingCompleted = await profileService.isOnboardingCompleted();

        if (!onboardingCompleted) {
          return '/onboarding';
        }
        return '/home';
      }

      // If logged in but not on onboarding, check if onboarding is needed
      if (isLoggedIn && !isOnboarding) {
        final profileService = ProfileService();
        final onboardingCompleted = await profileService.isOnboardingCompleted();

        if (!onboardingCompleted) {
          return '/onboarding';
        }
      }

      return null;
    },
    routes: [
      // Auth routes (no bottom navigation)
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Onboarding routes (no bottom navigation)
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const WelcomeScreen(),
        routes: [
          GoRoute(
            path: 'template',
            name: 'onboarding-template',
            builder: (context, state) => const TemplateSelectionScreen(),
          ),
          GoRoute(
            path: 'complete',
            name: 'onboarding-complete',
            builder: (context, state) => const SetupCompleteScreen(),
          ),
        ],
      ),

      // Main app shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/income',
            name: 'income',
            builder: (context, state) => const IncomeScreen(),
          ),
          GoRoute(
            path: '/transactions',
            name: 'transactions',
            builder: (context, state) => const TransactionsScreen(),
          ),
          GoRoute(
            path: '/budget',
            name: 'budget',
            builder: (context, state) => const ExpensesOverviewScreen(),
            routes: [
              GoRoute(
                path: 'category/:id',
                name: 'category',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return CategoryDetailScreen(categoryId: id);
                },
              ),
            ],
          ),
          // Keep /expenses as alias for backwards compatibility
          GoRoute(
            path: '/expenses',
            name: 'expenses',
            redirect: (context, state) => '/budget',
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );
});
