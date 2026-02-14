import 'package:budgetwise/config/theme.dart';
import 'package:budgetwise/models/account.dart';
import 'package:budgetwise/models/category.dart';
import 'package:budgetwise/models/item.dart';
import 'package:budgetwise/providers/providers.dart';
import 'package:budgetwise/screens/transactions/transaction_form_sheet.dart';
import 'package:budgetwise/services/item_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeItemService implements ItemService {
  FakeItemService({required this.itemToReturn});

  final Item itemToReturn;
  bool ensureCalled = false;

  @override
  Future<Item> ensureDefaultItemForCategory({
    required String categoryId,
    required String categoryName,
    bool isBudgeted = true,
    double projected = 0,
  }) async {
    ensureCalled = true;
    return itemToReturn;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Account _account() {
  final now = DateTime(2026, 1, 1);
  return Account(
    id: 'acc-1',
    userId: 'user-1',
    name: 'Primary',
    type: AccountType.debit,
    currency: 'USD',
    createdAt: now,
    updatedAt: now,
  );
}

Item _item() {
  final now = DateTime(2026, 1, 1);
  return Item(
    id: 'item-1',
    categoryId: 'cat-1',
    userId: 'user-1',
    name: 'Groceries',
    createdAt: now,
    updatedAt: now,
  );
}

Category _category({required List<Item> items}) {
  final now = DateTime(2026, 1, 1);
  return Category(
    id: 'cat-1',
    userId: 'user-1',
    monthId: 'month-1',
    name: 'Food',
    createdAt: now,
    updatedAt: now,
    items: items,
  );
}

Widget _harness({
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

void main() {
  testWidgets(
      'simple mode category picker skips item picker when category has items',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final fakeItemService = FakeItemService(itemToReturn: _item());
    final account = _account();
    final category = _category(items: [_item()]);

    await tester.pumpWidget(
      _harness(
        child: const TransactionFormSheet(),
        overrides: [
          currencyProvider.overrideWith((ref) => 'USD'),
          isSimpleBudgetModeProvider.overrideWith((ref) => true),
          itemServiceProvider.overrideWith((ref) => fakeItemService),
          allAccountsProvider.overrideWith((ref) async => [account]),
          accountsProvider.overrideWith((ref) async => [account]),
          categoriesProvider.overrideWith((ref) async => [category]),
          categoryByIdProvider.overrideWith(
            (ref, categoryId) async =>
                categoryId == category.id ? category : null,
          ),
          incomeSourcesProvider.overrideWith((ref) async => []),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Category').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food').last);
    await tester.pumpAndSettle();

    expect(find.text('Select Item'), findsNothing);
    expect(fakeItemService.ensureCalled, isFalse);
  });

  testWidgets(
      'simple mode creates default item when category has no visible items',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final fakeItemService = FakeItemService(itemToReturn: _item());
    final account = _account();
    final category = _category(items: []);

    await tester.pumpWidget(
      _harness(
        child: const TransactionFormSheet(),
        overrides: [
          currencyProvider.overrideWith((ref) => 'USD'),
          isSimpleBudgetModeProvider.overrideWith((ref) => true),
          itemServiceProvider.overrideWith((ref) => fakeItemService),
          allAccountsProvider.overrideWith((ref) async => [account]),
          accountsProvider.overrideWith((ref) async => [account]),
          categoriesProvider.overrideWith((ref) async => [category]),
          categoryByIdProvider.overrideWith(
            (ref, categoryId) async =>
                categoryId == category.id ? category : null,
          ),
          incomeSourcesProvider.overrideWith((ref) async => []),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Category').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food').last);
    await tester.pumpAndSettle();

    expect(find.text('Select Item'), findsNothing);
    expect(fakeItemService.ensureCalled, isTrue);
  });
}
