import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/transaction.dart';
import '../services/transaction_service.dart';
import 'auth_provider.dart';
import 'month_provider.dart';
import 'category_provider.dart';
import 'income_provider.dart';

/// Transaction service provider
final transactionServiceProvider = Provider<TransactionService>((ref) {
  return TransactionService();
});

/// All transactions for the active month
final transactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final month = ref.watch(activeMonthProvider).value;
  if (month == null) return [];

  final service = ref.read(transactionServiceProvider);
  return service.getTransactionsForMonth(month.id);
});

/// Transactions for a specific category
final transactionsByCategoryProvider =
    FutureProvider.family<List<Transaction>, String>((ref, categoryId) async {
  final service = ref.read(transactionServiceProvider);
  return service.getTransactionsForCategory(categoryId);
});

/// Transactions for a specific item
final transactionsByItemProvider =
    FutureProvider.family<List<Transaction>, String>((ref, itemId) async {
  final service = ref.read(transactionServiceProvider);
  return service.getTransactionsForItem(itemId);
});

/// Transactions grouped by date
final transactionsByDateProvider =
    Provider<Map<DateTime, List<Transaction>>>((ref) {
  final transactions = ref.watch(transactionsProvider).value ?? [];
  final grouped = <DateTime, List<Transaction>>{};

  for (final tx in transactions) {
    final key = DateTime(tx.date.year, tx.date.month, tx.date.day);
    grouped.putIfAbsent(key, () => []).add(tx);
  }

  // Sort keys in descending order (newest first)
  final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
  return {for (var key in sortedKeys) key: grouped[key]!};
});

/// Only expense transactions
final expenseTransactionsProvider = Provider<List<Transaction>>((ref) {
  final transactions = ref.watch(transactionsProvider).value ?? [];
  return transactions.where((t) => t.type == TransactionType.expense).toList();
});

/// Only income transactions
final incomeTransactionsProvider = Provider<List<Transaction>>((ref) {
  final transactions = ref.watch(transactionsProvider).value ?? [];
  return transactions.where((t) => t.type == TransactionType.income).toList();
});

/// Transaction notifier for mutations
class TransactionNotifier extends AsyncNotifier<List<Transaction>> {
  @override
  Future<List<Transaction>> build() async {
    final month = ref.watch(activeMonthProvider).value;
    if (month == null) return [];

    final service = ref.read(transactionServiceProvider);
    return service.getTransactionsForMonth(month.id);
  }

  TransactionService get _service => ref.read(transactionServiceProvider);

  /// Add an expense transaction
  Future<Transaction> addExpense({
    required String categoryId,
    required String itemId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    final user = ref.read(currentUserProvider);
    final month = ref.read(activeMonthProvider).value;
    if (user == null || month == null) throw Exception('Not ready');

    final tx = await _service.createExpense(
      monthId: month.id,
      categoryId: categoryId,
      itemId: itemId,
      amount: amount,
      date: date,
      note: note,
    );

    _invalidateAll();
    return tx;
  }

  /// Add an income transaction
  Future<Transaction> addIncome({
    required String incomeSourceId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    final user = ref.read(currentUserProvider);
    final month = ref.read(activeMonthProvider).value;
    if (user == null || month == null) throw Exception('Not ready');

    final tx = await _service.createIncome(
      monthId: month.id,
      incomeSourceId: incomeSourceId,
      amount: amount,
      date: date,
      note: note,
    );

    _invalidateAll();
    return tx;
  }

  /// Update a transaction
  Future<Transaction> updateTransaction({
    required String transactionId,
    String? categoryId,
    String? itemId,
    String? incomeSourceId,
    double? amount,
    DateTime? date,
    String? note,
  }) async {
    final tx = await _service.updateTransaction(
      transactionId: transactionId,
      categoryId: categoryId,
      itemId: itemId,
      incomeSourceId: incomeSourceId,
      amount: amount,
      date: date,
      note: note,
    );

    _invalidateAll();
    return tx;
  }

  /// Delete a transaction
  Future<void> deleteTransaction(String transactionId) async {
    await _service.deleteTransaction(transactionId);
    _invalidateAll();
  }

  /// Invalidate all related providers
  void _invalidateAll() {
    ref.invalidateSelf();
    ref.invalidate(transactionsProvider);
    ref.invalidate(categoriesProvider);
    ref.invalidate(incomeSourcesProvider);
  }
}

final transactionNotifierProvider =
    AsyncNotifierProvider<TransactionNotifier, List<Transaction>>(
        () => TransactionNotifier());
