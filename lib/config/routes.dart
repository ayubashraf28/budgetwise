import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/income/income_screen.dart';
import '../screens/categories/categories_screen.dart';
import '../screens/manage/manage_screen.dart';
import '../screens/analysis/analysis_screen.dart';
import '../screens/budget/budget_overview_screen.dart';
import '../screens/expenses/expense_categories_screen.dart';
import '../screens/expenses/expense_overview_screen.dart';
import '../screens/expenses/category_detail_screen.dart';
import '../screens/expenses/item_detail_screen.dart';
import '../screens/transactions/transactions_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/profile_screen.dart';
import '../screens/settings/accounts_screen.dart';
import '../screens/subscriptions/subscriptions_screen.dart';
import '../screens/onboarding/welcome_screen.dart';
import '../screens/onboarding/template_selection_screen.dart';
import '../screens/onboarding/setup_complete_screen.dart';
import '../widgets/navigation/app_shell.dart';
import '../services/profile_service.dart';
import '../providers/providers.dart';

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
        final onboardingCompleted =
            await profileService.isOnboardingCompleted();

        if (!onboardingCompleted) {
          return '/onboarding';
        }
        return '/home';
      }

      // If logged in but not on onboarding, check if onboarding is needed
      if (isLoggedIn && !isOnboarding) {
        final profileService = ProfileService();
        final onboardingCompleted =
            await profileService.isOnboardingCompleted();

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
