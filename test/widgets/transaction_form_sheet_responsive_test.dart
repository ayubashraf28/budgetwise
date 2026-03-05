import 'package:budgetwise/config/theme.dart';
import 'package:budgetwise/models/account.dart';
import 'package:budgetwise/providers/providers.dart';
import 'package:budgetwise/screens/transactions/transaction_form_sheet.dart';
import 'package:budgetwise/widgets/common/calculator_keypad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Account _account() {
  final now = DateTime(2026, 1, 1);
  return Account(
    id: 'acc-1',
    userId: 'user-1',
    name: 'Primary Account',
    type: AccountType.debit,
    currency: 'USD',
    createdAt: now,
    updatedAt: now,
  );
}

Widget _harness({
  required MediaQueryData mediaQueryData,
}) {
  final account = _account();
  return ProviderScope(
    overrides: [
      currencyProvider.overrideWith((ref) => 'USD'),
      isSimpleBudgetModeProvider.overrideWith((ref) => false),
      allAccountsProvider.overrideWith((ref) async => [account]),
      categoriesProvider.overrideWith((ref) async => const []),
      incomeSourcesProvider.overrideWith((ref) async => const []),
    ],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: MediaQuery(
        data: mediaQueryData,
        child: const Scaffold(
          body: SizedBox.expand(
            child: TransactionFormSheet(),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Date/time section respects top safe area on notch devices',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _harness(
        mediaQueryData: const MediaQueryData(
          size: Size(360, 780),
          padding: EdgeInsets.only(top: 44, bottom: 24),
          viewPadding: EdgeInsets.only(top: 44, bottom: 24),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final dateTop = tester.getTopLeft(find.text('Date').first).dy;
    expect(dateTop, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Compact phones render transaction form without overflow',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _harness(
        mediaQueryData: const MediaQueryData(
          size: Size(360, 640),
          padding: EdgeInsets.only(top: 24, bottom: 16),
          viewPadding: EdgeInsets.only(top: 24, bottom: 16),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Compact phones keep keypad and action buttons visible',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _harness(
        mediaQueryData: const MediaQueryData(
          size: Size(360, 640),
          padding: EdgeInsets.only(top: 24, bottom: 16),
          viewPadding: EdgeInsets.only(top: 24, bottom: 16),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.byType(CalculatorKeypad), findsOneWidget);
    expect(find.text('\u00F7'), findsOneWidget);
    expect(find.text('='), findsOneWidget);
    expect(find.text('0'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
