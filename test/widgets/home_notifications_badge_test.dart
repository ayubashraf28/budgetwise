import 'package:budgetwise/config/theme.dart';
import 'package:budgetwise/models/month.dart';
import 'package:budgetwise/models/monthly_summary.dart';
import 'package:budgetwise/models/user_profile.dart';
import 'package:budgetwise/providers/providers.dart';
import 'package:budgetwise/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
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

  testWidgets('home bell shows unread badge and opens notifications',
      (tester) async {
    final now = DateTime.utc(2026, 1, 15);
    final month = Month(
      id: 'month-1',
      userId: 'user-1',
      name: 'January 2026',
      startDate: DateTime.utc(2026, 1, 1),
      endDate: DateTime.utc(2026, 1, 31),
      createdAt: now,
      updatedAt: now,
    );
    final profile = UserProfile(
      id: 'profile-1',
      userId: 'user-1',
      displayName: 'User',
      createdAt: now,
      updatedAt: now,
    );
    final summary = MonthlySummary.empty(month.id, month.name);

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(
          path: '/notifications',
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('Notifications Screen'))),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('Settings Screen'))),
        ),
        GoRoute(
          path: '/settings/profile',
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('Profile Screen'))),
        ),
        GoRoute(
          path: '/settings/accounts',
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('Accounts Screen'))),
        ),
        GoRoute(
          path: '/subscriptions',
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('Subscriptions Screen'))),
        ),
        GoRoute(
          path: '/transactions',
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('Transactions Screen'))),
        ),
        GoRoute(
          path: '/income',
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('Income Screen'))),
        ),
        GoRoute(
          path: '/expenses',
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('Expenses Screen'))),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ensureMonthSetupProvider.overrideWith((ref) async {}),
          activeMonthProvider.overrideWith((ref) async => month),
          userProfileProvider.overrideWith((ref) async => profile),
          monthlySummaryProvider.overrideWith((ref) => summary),
          totalActualIncomeProvider.overrideWith((ref) => 0),
          totalActualExpensesProvider.overrideWith((ref) => 0),
          currencySymbolProvider.overrideWith((ref) => '\u00A3'),
          accountsProvider.overrideWith((ref) async => const []),
          allAccountBalancesProvider.overrideWith((ref) async => const {}),
          netWorthProvider.overrideWith((ref) async => 0),
          transactionsProvider.overrideWith((ref) async => const []),
          upcomingSubscriptionsProvider.overrideWith((ref) async => const []),
          hideSensitiveAmountsProvider.overrideWith((ref) => false),
          uiSectionExpandedProvider.overrideWith((ref, section) => true),
          isSimpleBudgetModeProvider.overrideWith((ref) => false),
          unreadNotificationCountProvider.overrideWith((ref) => 101),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('99+'), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.bell));
    await tester.pumpAndSettle();

    expect(find.text('Notifications Screen'), findsOneWidget);
  });
}
