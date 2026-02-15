import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/providers.dart';
import '../screens/analysis/analysis_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/budget/budget_overview_screen.dart';
import '../screens/categories/categories_screen.dart';
import '../screens/expenses/category_detail_screen.dart';
import '../screens/expenses/expense_categories_screen.dart';
import '../screens/expenses/expense_overview_screen.dart';
import '../screens/expenses/item_detail_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/income/income_screen.dart';
import '../screens/manage/manage_screen.dart';
import '../screens/onboarding/setup_complete_screen.dart';
import '../screens/onboarding/template_selection_screen.dart';
import '../screens/onboarding/welcome_screen.dart';
import '../screens/settings/accounts_screen.dart';
import '../screens/settings/profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/subscriptions/subscriptions_screen.dart';
import '../screens/transactions/transactions_screen.dart';
import '../widgets/navigation/app_shell.dart';

String? resolveAppRedirect({
  required bool isLoggedIn,
  required String matchedLocation,
  required bool onboardingCompleted,
}) {
  final isLoggingIn = matchedLocation == '/login';
  final isRegistering = matchedLocation == '/register';
  final isOnboarding = matchedLocation.startsWith('/onboarding');

  if (!isLoggedIn) {
    if (isLoggingIn || isRegistering) return null;
    return '/login';
  }

  if (isLoggingIn || isRegistering) {
    return onboardingCompleted ? '/home' : '/onboarding';
  }

  if (!onboardingCompleted && !isOnboarding) {
    return '/onboarding';
  }

  if (onboardingCompleted && isOnboarding) {
    return '/home';
  }

  return null;
}

Future<bool> resolveOnboardingCompletedForRedirect({
  required AsyncValue<bool> cachedValue,
  required Future<bool> Function() loadOnboardingCompleted,
  Duration timeout = const Duration(seconds: 4),
}) async {
  if (cachedValue.hasValue) {
    return cachedValue.requireValue;
  }

  if (cachedValue.hasError) {
    return true;
  }

  try {
    return await loadOnboardingCompleted().timeout(timeout);
  } catch (_) {
    // Fail closed: if we can't determine onboarding status, show onboarding
    // to prevent users landing in an unconfigured app.
    return false;
  }
}

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
    debugLogDiagnostics: false,
    refreshListenable: refreshListenable,
    redirect: (context, state) async {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final matchedLocation = state.matchedLocation;

      if (!isLoggedIn) {
        return resolveAppRedirect(
          isLoggedIn: false,
          matchedLocation: matchedLocation,
          onboardingCompleted: false,
        );
      }

      final onboardingCompleted = await resolveOnboardingCompletedForRedirect(
        cachedValue: ref.read(onboardingCompletedProvider),
        loadOnboardingCompleted: () =>
            ref.read(onboardingCompletedProvider.future),
      );

      return resolveAppRedirect(
        isLoggedIn: true,
        matchedLocation: matchedLocation,
        onboardingCompleted: onboardingCompleted,
      );
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
            path: '/analysis',
            name: 'analysis',
            builder: (context, state) => const AnalysisScreen(),
          ),
          GoRoute(
            path: '/categories',
            name: 'categories',
            builder: (context, state) => const CategoriesScreen(),
          ),
          GoRoute(
            path: '/manage',
            name: 'manage',
            builder: (context, state) => const ManageScreen(),
          ),
          GoRoute(
            path: '/income',
            name: 'income',
            builder: (context, state) => const IncomeScreen(),
          ),
          GoRoute(
            path: '/transactions/new',
            name: 'transactions-new',
            builder: (context, state) =>
                const TransactionsScreen(openComposerOnLoad: true),
          ),
          GoRoute(
            path: '/transactions',
            name: 'transactions',
            builder: (context, state) => const TransactionsScreen(),
          ),
          GoRoute(
            path: '/budget',
            name: 'budget',
            builder: (context, state) => const ExpenseCategoriesScreen(),
            routes: [
              GoRoute(
                path: 'category/:id',
                name: 'category',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  final yearMode =
                      state.uri.queryParameters['yearMode'] == 'true';
                  return CategoryDetailScreen(
                    categoryId: id,
                    yearMode: yearMode,
                    routePrefix: '/budget',
                  );
                },
                routes: [
                  GoRoute(
                    path: 'item/:itemId',
                    name: 'item-detail',
                    builder: (context, state) {
                      final categoryId = state.pathParameters['id']!;
                      final itemId = state.pathParameters['itemId']!;
                      if (ref.read(isSimpleBudgetModeProvider)) {
                        return CategoryDetailScreen(
                          categoryId: categoryId,
                          routePrefix: '/budget',
                        );
                      }
                      return ItemDetailScreen(
                        categoryId: categoryId,
                        itemId: itemId,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/budget-overview',
            name: 'budget-overview',
            builder: (context, state) => const BudgetOverviewScreen(),
          ),
          // Expense overview screen
          GoRoute(
            path: '/expenses',
            name: 'expenses',
            builder: (context, state) => const ExpenseOverviewScreen(),
            routes: [
              GoRoute(
                path: 'category/:id',
                name: 'expense-category',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  final yearMode =
                      state.uri.queryParameters['yearMode'] == 'true';
                  return CategoryDetailScreen(
                    categoryId: id,
                    yearMode: yearMode,
                    routePrefix: '/expenses',
                  );
                },
                routes: [
                  GoRoute(
                    path: 'item/:itemId',
                    name: 'expense-item-detail',
                    builder: (context, state) {
                      final categoryId = state.pathParameters['id']!;
                      final itemId = state.pathParameters['itemId']!;
                      if (ref.read(isSimpleBudgetModeProvider)) {
                        return CategoryDetailScreen(
                          categoryId: categoryId,
                          routePrefix: '/expenses',
                        );
                      }
                      return ItemDetailScreen(
                        categoryId: categoryId,
                        itemId: itemId,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/subscriptions',
            name: 'subscriptions',
            builder: (context, state) => const SubscriptionsScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'profile',
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
              GoRoute(
                path: 'accounts',
                name: 'accounts',
                builder: (context, state) => AccountsScreen(
                  initialAccountId: state.uri.queryParameters['accountId'],
                ),
              ),
            ],
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
