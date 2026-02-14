import 'package:budgetwise/models/category.dart';
import 'package:budgetwise/models/item.dart';
import 'package:budgetwise/models/month.dart';
import 'package:budgetwise/models/transaction.dart';
import 'package:budgetwise/providers/auth_provider.dart';
import 'package:budgetwise/providers/category_provider.dart';
import 'package:budgetwise/providers/month_provider.dart';
import 'package:budgetwise/providers/transaction_provider.dart';
import 'package:budgetwise/services/category_service.dart';
import 'package:budgetwise/services/month_service.dart';
import 'package:budgetwise/services/transaction_service.dart';
import 'package:budgetwise/utils/errors/app_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

  test('addExpense uses selected IDs when transaction month is active month',
      () async {
    final activeMonth = _month(id: 'month-active', year: 2026, month: 1);
    final monthService = _FakeMonthService(activeMonth);
    final txService = _FakeTransactionService();
    final categoryService = _FakeCategoryService(
      sourceCategory: null,
      targetCategories: const <Category>[],
    );

    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith((ref) => _fakeUser()),
        activeMonthProvider.overrideWith((ref) async => activeMonth),
        monthServiceProvider.overrideWithValue(monthService),
        transactionServiceProvider.overrideWithValue(txService),
        categoryServiceProvider.overrideWithValue(categoryService),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(transactionNotifierProvider.notifier);
    await notifier.addExpense(
      categoryId: 'cat-1',
      itemId: 'item-1',
      accountId: 'account-1',
      amount: 42,
      date: DateTime.utc(2026, 1, 15),
      note: 'Groceries',
    );

    final call = txService.lastExpenseCall;
    expect(call, isNotNull);
    expect(call!.monthId, activeMonth.id);
    expect(call.categoryId, 'cat-1');
    expect(call.itemId, 'item-1');
  });

  test('addExpense resolves category/item IDs for different target month',
      () async {
    final activeMonth = _month(id: 'month-active', year: 2026, month: 1);
    final targetMonth = _month(id: 'month-target', year: 2026, month: 2);
    final sourceCategory = Category(
      id: 'cat-source',
      userId: 'user-1',
      monthId: activeMonth.id,
      name: 'Food',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      items: [
        Item(
          id: 'item-source',
          categoryId: 'cat-source',
          userId: 'user-1',
          name: 'Groceries',
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      ],
    );
    final targetCategory = Category(
      id: 'cat-target',
      userId: 'user-1',
      monthId: targetMonth.id,
      name: 'Food',
      createdAt: DateTime.utc(2026, 2, 1),
      updatedAt: DateTime.utc(2026, 2, 1),
      items: [
        Item(
          id: 'item-target',
          categoryId: 'cat-target',
          userId: 'user-1',
          name: 'Groceries',
          createdAt: DateTime.utc(2026, 2, 1),
          updatedAt: DateTime.utc(2026, 2, 1),
        ),
      ],
    );

    final monthService = _FakeMonthService(targetMonth);
    final txService = _FakeTransactionService();
    final categoryService = _FakeCategoryService(
      sourceCategory: sourceCategory,
      targetCategories: [targetCategory],
    );

    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith((ref) => _fakeUser()),
        activeMonthProvider.overrideWith((ref) async => activeMonth),
        monthServiceProvider.overrideWithValue(monthService),
        transactionServiceProvider.overrideWithValue(txService),
        categoryServiceProvider.overrideWithValue(categoryService),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(transactionNotifierProvider.notifier);
    await notifier.addExpense(
      categoryId: 'cat-source',
      itemId: 'item-source',
      accountId: 'account-1',
      amount: 15.5,
      date: DateTime.utc(2026, 2, 2),
      note: 'Moved month test',
    );

    final call = txService.lastExpenseCall;
    expect(call, isNotNull);
    expect(call!.monthId, targetMonth.id);
    expect(call.categoryId, 'cat-target');
    expect(call.itemId, 'item-target');
  });

  test('addIncome throws validation when user is missing', () async {
    final monthService =
        _FakeMonthService(_month(id: 'month-1', year: 2026, month: 1));
    final txService = _FakeTransactionService();
    final categoryService = _FakeCategoryService(
      sourceCategory: null,
      targetCategories: const <Category>[],
    );

    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith((ref) => null),
        monthServiceProvider.overrideWithValue(monthService),
        transactionServiceProvider.overrideWithValue(txService),
        categoryServiceProvider.overrideWithValue(categoryService),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(transactionNotifierProvider.notifier);
    await expectLater(
      () => notifier.addIncome(
        incomeSourceId: 'income-1',
        accountId: 'account-1',
        amount: 100,
        date: DateTime.utc(2026, 1, 3),
      ),
      throwsA(
        isA<AppError>().having(
          (error) => error.code,
          'code',
          AppErrorCode.validation,
        ),
      ),
    );
  });
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

Month _month({
  required String id,
  required int year,
  required int month,
}) {
  return Month(
    id: id,
    userId: 'user-1',
    name: '$month/$year',
    startDate: DateTime.utc(year, month, 1),
    endDate: DateTime.utc(year, month + 1, 0),
    createdAt: DateTime.utc(year, month, 1),
    updatedAt: DateTime.utc(year, month, 1),
  );
}

class _ExpenseCall {
  final String monthId;
  final String categoryId;
  final String itemId;
  final String accountId;
  final double amount;
  final DateTime date;
  final String? note;

  const _ExpenseCall({
    required this.monthId,
    required this.categoryId,
    required this.itemId,
    required this.accountId,
    required this.amount,
    required this.date,
    required this.note,
  });
}

class _FakeTransactionService extends TransactionService {
  _ExpenseCall? lastExpenseCall;

  @override
  Future<List<Transaction>> getTransactionsForMonth(String monthId) async {
    return const <Transaction>[];
  }

  @override
  Future<Transaction> createExpense({
    required String monthId,
    required String categoryId,
    required String itemId,
    String? subscriptionId,
    required String accountId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    lastExpenseCall = _ExpenseCall(
      monthId: monthId,
      categoryId: categoryId,
      itemId: itemId,
      accountId: accountId,
      amount: amount,
      date: date,
      note: note,
    );
    return _transaction(
      id: 'tx-expense',
      monthId: monthId,
      type: TransactionType.expense,
      amount: amount,
      categoryId: categoryId,
      itemId: itemId,
      accountId: accountId,
      date: date,
      note: note,
    );
  }

  @override
  Future<Transaction> createIncome({
    required String monthId,
    required String incomeSourceId,
    required String accountId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    return _transaction(
      id: 'tx-income',
      monthId: monthId,
      type: TransactionType.income,
      amount: amount,
      incomeSourceId: incomeSourceId,
      accountId: accountId,
      date: date,
      note: note,
    );
  }
}

class _FakeMonthService extends MonthService {
  _FakeMonthService(this._targetMonth);

  final Month _targetMonth;

  @override
  Future<Month> getMonthForDate(DateTime date) async {
    return _targetMonth;
  }
}

class _FakeCategoryService extends CategoryService {
  _FakeCategoryService({
    required this.sourceCategory,
    required this.targetCategories,
  });

  final Category? sourceCategory;
  final List<Category> targetCategories;

  @override
  Future<Category?> getCategoryById(String categoryId) async {
    return sourceCategory;
  }

  @override
  Future<List<Category>> getCategoriesForMonth(String monthId) async {
    return targetCategories;
  }
}

Transaction _transaction({
  required String id,
  required String monthId,
  required TransactionType type,
  required double amount,
  String? categoryId,
  String? itemId,
  String? incomeSourceId,
  String? accountId,
  required DateTime date,
  String? note,
}) {
  return Transaction(
    id: id,
    userId: 'user-1',
    monthId: monthId,
    categoryId: categoryId,
    itemId: itemId,
    incomeSourceId: incomeSourceId,
    accountId: accountId,
    type: type,
    amount: amount,
    date: date,
    note: note,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
}
