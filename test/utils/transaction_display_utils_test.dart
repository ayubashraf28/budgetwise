import 'package:budgetwise/models/transaction.dart';
import 'package:budgetwise/utils/transaction_display_utils.dart';
import 'package:flutter_test/flutter_test.dart';

Transaction _expenseTx({
  String? note,
  String? categoryName = 'Food',
  String? itemName = 'Dining Out',
}) {
  final now = DateTime(2026, 1, 1);
  return Transaction(
    id: 'tx-1',
    userId: 'user-1',
    monthId: 'month-1',
    categoryId: 'cat-1',
    itemId: 'item-1',
    accountId: 'acc-1',
    type: TransactionType.expense,
    amount: 10,
    date: now,
    note: note,
    createdAt: now,
    updatedAt: now,
    categoryName: categoryName,
    itemName: itemName,
  );
}

Transaction _incomeTx({
  String? note,
  String? incomeSourceName = 'Salary',
}) {
  final now = DateTime(2026, 1, 1);
  return Transaction(
    id: 'tx-2',
    userId: 'user-1',
    monthId: 'month-1',
    incomeSourceId: 'inc-1',
    accountId: 'acc-1',
    type: TransactionType.income,
    amount: 100,
    date: now,
    note: note,
    createdAt: now,
    updatedAt: now,
    incomeSourceName: incomeSourceName,
  );
}

void main() {
  test('simple mode uses note first', () {
    final tx = _expenseTx(note: 'Groceries at market');
    expect(
      transactionPrimaryLabel(tx, isSimpleMode: true),
      'Groceries at market',
    );
  });

  test('simple mode expense falls back to category name', () {
    final tx = _expenseTx(note: null, categoryName: 'Transport');
    expect(
      transactionPrimaryLabel(tx, isSimpleMode: true),
      'Transport',
    );
  });

  test('simple mode income falls back to source name', () {
    final tx = _incomeTx(note: null, incomeSourceName: 'Freelance');
    expect(
      transactionPrimaryLabel(tx, isSimpleMode: true),
      'Freelance',
    );
  });

  test('detailed mode preserves displayName behavior', () {
    final tx = _expenseTx(note: null, itemName: 'Takeaway');
    expect(
      transactionPrimaryLabel(tx, isSimpleMode: false),
      'Takeaway',
    );
  });
}
