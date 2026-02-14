import 'package:budgetwise/models/category.dart';
import 'package:budgetwise/models/income_source.dart';
import 'package:budgetwise/models/item.dart';
import 'package:budgetwise/models/transaction.dart';
import 'package:budgetwise/utils/actual_calculation_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('withCategoryActuals calculates item actuals from expense transactions',
      () {
    final now = DateTime(2026, 2, 14);
    final itemA = Item(
      id: 'item-a',
      categoryId: 'cat-1',
      userId: 'user-1',
      name: 'Groceries',
      createdAt: now,
      updatedAt: now,
    );
    final itemB = Item(
      id: 'item-b',
      categoryId: 'cat-1',
      userId: 'user-1',
      name: 'Dining',
      createdAt: now,
      updatedAt: now,
    );
    final category = Category(
      id: 'cat-1',
      userId: 'user-1',
      monthId: 'month-1',
      name: 'Food',
      items: [itemA, itemB],
      createdAt: now,
      updatedAt: now,
    );
    final transactions = <Transaction>[
      Transaction(
        id: 'tx-1',
        userId: 'user-1',
        monthId: 'month-1',
        categoryId: 'cat-1',
        itemId: 'item-a',
        accountId: 'acc-1',
        type: TransactionType.expense,
        amount: 20,
        date: now,
        createdAt: now,
        updatedAt: now,
      ),
      Transaction(
        id: 'tx-2',
        userId: 'user-1',
        monthId: 'month-1',
        categoryId: 'cat-1',
        itemId: 'item-a',
        accountId: 'acc-1',
        type: TransactionType.expense,
        amount: 5,
        date: now,
        createdAt: now,
        updatedAt: now,
      ),
      Transaction(
        id: 'tx-3',
        userId: 'user-1',
        monthId: 'month-1',
        categoryId: 'cat-1',
        itemId: 'item-b',
        accountId: 'acc-1',
        type: TransactionType.income,
        amount: 500,
        date: now,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final calculated = withCategoryActuals([category], transactions).first;

    expect(calculated.items, isNotNull);
    expect(calculated.items![0].actual, 25);
    expect(calculated.items![1].actual, 0);
  });

  test('withIncomeSourceActuals calculates source actuals from income only',
      () {
    final now = DateTime(2026, 2, 14);
    final source = IncomeSource(
      id: 'inc-1',
      userId: 'user-1',
      monthId: 'month-1',
      name: 'Salary',
      createdAt: now,
      updatedAt: now,
    );
    final transactions = <Transaction>[
      Transaction(
        id: 'tx-1',
        userId: 'user-1',
        monthId: 'month-1',
        incomeSourceId: 'inc-1',
        accountId: 'acc-1',
        type: TransactionType.income,
        amount: 1000,
        date: now,
        createdAt: now,
        updatedAt: now,
      ),
      Transaction(
        id: 'tx-2',
        userId: 'user-1',
        monthId: 'month-1',
        incomeSourceId: 'inc-1',
        accountId: 'acc-1',
        type: TransactionType.expense,
        amount: 200,
        date: now,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final calculated = withIncomeSourceActuals([source], transactions).first;
    expect(calculated.actual, 1000);
  });
}
