import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/providers.dart';
import '../screens/accounts/account_detail_screen.dart';
import '../screens/analysis/analysis_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/budget/budget_overview_screen.dart';
import '../screens/categories/categories_screen.dart';
import '../screens/expenses/category_detail_screen.dart';
import '../screens/expenses/expense_categories_screen.dart';
import '../screens/expenses/expense_overview_screen.dart';
import '../screens/expenses/item_detail_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/income/income_screen.dart';
import '../screens/manage/manage_screen.dart';
import '../screens/notifications/notification_center_screen.dart';
import '../screens/onboarding/notification_permission_screen.dart';
import '../screens/onboarding/setup_complete_screen.dart';
import '../screens/onboarding/template_selection_screen.dart';
import '../screens/onboarding/welcome_screen.dart';
import '../screens/settings/accounts_screen.dart';
import '../screens/settings/profile_screen.dart';
import '../screens/settings/settings_about_page.dart';
import '../screens/settings/settings_account_page.dart';
import '../screens/settings/settings_appearance_page.dart';
import '../screens/settings/settings_budget_page.dart';
import '../screens/settings/settings_notifications_page.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/settings_support_page.dart';
import '../screens/subscriptions/subscriptions_screen.dart';
import '../screens/transactions/transactions_screen.dart';
import '../widgets/navigation/app_shell.dart';
import 'crash_reporter.dart';
import 'route_transitions.dart';

String? resolveAppRedirect({
  required bool isLoggedIn,
  required String matchedLocation,
  required bool onboardingCompleted,
  required bool passwordRecoveryPending,
}) {
  final isLoggingIn = matchedLocation == '/login';
  final isRegistering = matchedLocation == '/register';
  final isResettingPassword = matchedLocation == '/reset-password';
  final isOnboarding = matchedLocation.startsWith('/onboarding');
  final isAllowedCompletedOnboardingRoute =
      matchedLocation == '/onboarding/complete' ||
          matchedLocation == '/onboarding/notifications';

  if (!isLoggedIn) {
    if (isLoggingIn || isRegistering) return null;
    return '/login';
  }

  if (passwordRecoveryPending) {
    if (isResettingPassword) return null;
    return '/reset-password';
  }

  if (isResettingPassword) {
    return onboardingCompleted ? '/home' : '/onboarding';
  }

  if (isLoggingIn || isRegistering) {
    return onboardingCompleted ? '/home' : '/onboarding';
  }

  if (!onboardingCompleted && !isOnboarding) {
    return '/onboarding';
  }

  if (onboardingCompleted &&
      isOnboarding &&
      !isAllowedCompletedOnboardingRoute) {
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

class CrashReporterRouteObserver extends NavigatorObserver {
  String? _lastRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _track(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _track(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _track(previousRoute);
    super.didPop(route, previousRoute);
  }

  void _track(Route<dynamic>? route) {
    final routeName = route?.settings.name?.trim();
    if (routeName == null || routeName.isEmpty || routeName == _lastRoute) {
      return;
    }
    _lastRoute = routeName;
    unawaited(
      CrashReporter.recordBreadcrumb(
        'bw_route_view',
        parameters: <String, Object?>{
          'route': routeName,
        },
      ),
    );
  }
}

/// Provider for the auth refresh listenable
final routerRefreshProvider = Provider<GoRouterRefreshStream>((ref) {
  final stream = Supabase.instance.client.auth.onAuthStateChange;
  return GoRouterRefreshStream(stream);
});

GoRoute _neoRoute({
  required String path,
  required String name,
  required Widget Function(BuildContext context, GoRouterState state) builder,
  NeoRouteStyle style = NeoRouteStyle.standard,
  List<RouteBase> routes = const <RouteBase>[],
}) {
  return GoRoute(
    path: path,
    name: name,
    pageBuilder: (context, state) => buildNeoPage<void>(
      state: state,
      child: builder(context, state),
      style: style,
    ),
    routes: routes,
  );
}

/// Main router provider
final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ref.watch(routerRefreshProvider);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: false,
    refreshListenable: refreshListenable,
    observers: <NavigatorObserver>[
      CrashReporterRouteObserver(),
    ],
    redirect: (context, state) async {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final matchedLocation = state.matchedLocation;

      if (!isLoggedIn) {
        return resolveAppRedirect(
          isLoggedIn: false,
          matchedLocation: matchedLocation,
          onboardingCompleted: false,
          passwordRecoveryPending: false,
        );
      }

      final passwordRecoveryPending = ref.read(passwordRecoveryPendingProvider);
      final onboardingCompleted = await resolveOnboardingCompletedForRedirect(
        cachedValue: ref.read(onboardingCompletedProvider),
        loadOnboardingCompleted: () =>
            ref.read(onboardingCompletedProvider.future),
      );

      return resolveAppRedirect(
        isLoggedIn: true,
        matchedLocation: matchedLocation,
        onboardingCompleted: onboardingCompleted,
        passwordRecoveryPending: passwordRecoveryPending,
      );
    },
    routes: [
      // Auth routes (no bottom navigation)
      _neoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      _neoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      _neoRoute(
        path: '/reset-password',
        name: 'reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),

      // Onboarding routes (no bottom navigation)
      _neoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const WelcomeScreen(),
        routes: [
          _neoRoute(
            path: 'template',
            name: 'onboarding-template',
            builder: (context, state) => const TemplateSelectionScreen(),
          ),
          _neoRoute(
            path: 'complete',
            name: 'onboarding-complete',
            builder: (context, state) => const SetupCompleteScreen(),
          ),
          _neoRoute(
            path: 'notifications',
            name: 'onboarding-notifications',
            builder: (context, state) => const NotificationPermissionScreen(),
          ),
        ],
      ),

      // Main app shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          _neoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
            style: NeoRouteStyle.none,
          ),
          _neoRoute(
            path: '/analysis',
            name: 'analysis',
            builder: (context, state) => const AnalysisScreen(),
            style: NeoRouteStyle.none,
          ),
          _neoRoute(
            path: '/categories',
            name: 'categories',
            builder: (context, state) => const CategoriesScreen(),
            style: NeoRouteStyle.none,
          ),
          _neoRoute(
            path: '/manage',
            name: 'manage',
            builder: (context, state) => const ManageScreen(),
            style: NeoRouteStyle.none,
          ),
          _neoRoute(
            path: '/income',
            name: 'income',
            builder: (context, state) => const IncomeScreen(),
          ),
          _neoRoute(
            path: '/transactions/new',
            name: 'transactions-new',
            builder: (context, state) =>
                const TransactionsScreen(openComposerOnLoad: true),
            style: NeoRouteStyle.modal,
          ),
          _neoRoute(
            path: '/transactions',
            name: 'transactions',
            builder: (context, state) => const TransactionsScreen(),
          ),
          _neoRoute(
            path: '/accounts/:id',
            name: 'account-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return AccountDetailScreen(accountId: id);
            },
          ),
          _neoRoute(
            path: '/budget',
            name: 'budget',
            builder: (context, state) => const ExpenseCategoriesScreen(),
            routes: [
              _neoRoute(
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
                  _neoRoute(
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
          _neoRoute(
            path: '/budget-overview',
            name: 'budget-overview',
            builder: (context, state) => const BudgetOverviewScreen(),
          ),
          // Expense overview screen
          _neoRoute(
            path: '/expenses',
            name: 'expenses',
            builder: (context, state) => const ExpenseOverviewScreen(),
            routes: [
              _neoRoute(
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
                  _neoRoute(
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
          _neoRoute(
            path: '/subscriptions',
            name: 'subscriptions',
            builder: (context, state) => const SubscriptionsScreen(),
          ),
          _neoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
            routes: [
              _neoRoute(
                path: 'profile',
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
              _neoRoute(
                path: 'accounts',
                name: 'accounts',
                builder: (context, state) => AccountsScreen(
                  initialAccountId: state.uri.queryParameters['accountId'],
                ),
              ),
              _neoRoute(
                path: 'account',
                name: 'settings-account',
                builder: (context, state) => const SettingsAccountPage(),
              ),
              _neoRoute(
                path: 'budget',
                name: 'settings-budget',
                builder: (context, state) => const SettingsBudgetPage(),
              ),
              _neoRoute(
                path: 'appearance',
                name: 'settings-appearance',
                builder: (context, state) => const SettingsAppearancePage(),
              ),
              _neoRoute(
                path: 'notifications-settings',
                name: 'settings-notifications',
                builder: (context, state) => const SettingsNotificationsPage(),
              ),
              _neoRoute(
                path: 'about',
                name: 'settings-about',
                builder: (context, state) => const SettingsAboutPage(),
              ),
              _neoRoute(
                path: 'support',
                name: 'settings-support',
                builder: (context, state) => const SettingsSupportPage(),
              ),
            ],
          ),
          _neoRoute(
            path: '/notifications',
            name: 'notifications',
            builder: (context, state) => const NotificationCenterScreen(),
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
