import 'package:budgetwise/config/theme.dart';
import 'package:budgetwise/models/account.dart';
import 'package:budgetwise/providers/providers.dart';
import 'package:budgetwise/screens/subscriptions/subscription_form_sheet.dart';
import 'package:budgetwise/screens/transactions/transaction_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 1, 1);
  final accounts = <Account>[
    Account(
      id: 'acc-1',
      userId: 'user-1',
      name:
          'Primary Everyday Spending Account With A Very Long Name For Layout Testing',
      type: AccountType.debit,
      currency: 'USD',
      createdAt: now,
      updatedAt: now,
    ),
  ];

  Widget testHarness({
    required Widget child,
    required List<Override> overrides,
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: MediaQuery(
          data: const MediaQueryData(size: Size(800, 1600)),
          child: Scaffold(
            body: SizedBox.expand(child: child),
          ),
        ),
      ),
    );
  }

  testWidgets('Subscription form sheet renders without dropdown layout errors',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      testHarness(
        child: const SubscriptionFormSheet(),
        overrides: [
          currencyProvider.overrideWith((ref) => 'USD'),
          allAccountsProvider.overrideWith((ref) async => accounts),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add Subscription'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Transaction form sheet renders without dropdown layout errors',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      testHarness(
        child: const TransactionFormSheet(),
        overrides: [
          currencyProvider.overrideWith((ref) => 'USD'),
          allAccountsProvider.overrideWith((ref) async => accounts),
          categoriesProvider.overrideWith((ref) async => []),
          incomeSourcesProvider.overrideWith((ref) async => []),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SAVE'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
