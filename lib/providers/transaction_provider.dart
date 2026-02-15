import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../models/item.dart';
import '../models/transaction.dart';
import '../services/category_service.dart';
import '../services/month_service.dart';
import '../services/transaction_service.dart';
import '../utils/errors/app_error.dart';
import 'account_provider.dart';
import 'auth_provider.dart';
import 'category_provider.dart';
import 'income_provider.dart';
import 'month_provider.dart';
import 'notification_provider.dart';

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

/// Transactions for a specific month (parameterized).
/// Used by the budget screen to fetch transactions independently of activeMonthProvider.
final transactionsForMonthProvider =
    FutureProvider.family<List<Transaction>, String>((ref, monthId) async {
  final service = ref.read(transactionServiceProvider);
  return service.getTransactionsForMonth(monthId);
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
  MonthService get _monthService => ref.read(monthServiceProvider);
  CategoryService get _categoryService => ref.read(categoryServiceProvider);

  /// Add an expense transaction.
  /// Month is derived from the transaction date, NOT the active month.
  Future<Transaction> addExpense({
    required String categoryId,
    required String itemId,
    required String accountId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      throw const AppError.validation(technicalMessage: 'Provider not ready');
    }

    final transactionService = _service;
    final monthService = _monthService;
    final categoryService = _categoryService;
    final activeMonth = ref.read(activeMonthProvider).valueOrNull ??
        await ref.read(activeMonthProvider.future);

    // Derive month from transaction date
    final targetMonth = await monthService.getMonthForDate(date);

    // Resolve category/item IDs for the target month
    String resolvedCategoryId = categoryId;
    String resolvedItemId = itemId;

    if (activeMonth != null && activeMonth.id != targetMonth.id) {
      // Transaction date is in a different month than active — resolve IDs by name
      final resolved = await _resolveIdsForMonth(
        categoryService: categoryService,
        sourceCategoryId: categoryId,
        sourceItemId: itemId,
        targetMonthId: targetMonth.id,
      );
      resolvedCategoryId = resolved['categoryId']!;
      resolvedItemId = resolved['itemId']!;
    }

    final tx = await transactionService.createExpense(
      monthId: targetMonth.id,
      categoryId: resolvedCategoryId,
      itemId: resolvedItemId,
      accountId: accountId,
      amount: amount,
      date: date,
      note: note,
    );
    await _createBudgetAlertBestEffort(
      categoryId: resolvedCategoryId,
      monthId: targetMonth.id,
    );

    _invalidateAll();
    return tx;
  }

  Future<void> _createBudgetAlertBestEffort({
    required String categoryId,
    required String monthId,
  }) async {
    try {
      await ref.read(notificationServiceProvider).checkAndCreateBudgetAlert(
            categoryId: categoryId,
            monthId: monthId,
          );
    } catch (_) {
      // Non-blocking side effect.
    }
  }

  /// Add an income transaction.
  /// Month is derived from the transaction date, NOT the active month.
  Future<Transaction> addIncome({
    required String incomeSourceId,
    required String accountId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      throw const AppError.validation(technicalMessage: 'Provider not ready');
    }

    final transactionService = _service;
    final monthService = _monthService;

    // Derive month from transaction date
    final targetMonth = await monthService.getMonthForDate(date);

    final tx = await transactionService.createIncome(
      monthId: targetMonth.id,
      incomeSourceId: incomeSourceId,
      accountId: accountId,
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
    String? accountId,
    double? amount,
    DateTime? date,
    String? note,
  }) async {
    final tx = await _service.updateTransaction(
      transactionId: transactionId,
      categoryId: categoryId,
      itemId: itemId,
      incomeSourceId: incomeSourceId,
      accountId: accountId,
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
    ref.invalidate(transactionsForMonthProvider);
    ref.invalidate(categoriesProvider);
    ref.invalidate(categoriesForMonthProvider);
    ref.invalidate(incomeSourcesProvider);
    ref.invalidate(incomeSourcesForMonthProvider);
    ref.invalidate(accountBalancesProvider);
    ref.invalidate(allAccountBalancesProvider);
    ref.invalidate(netWorthProvider);
  }

  /// Resolves category/item IDs from one month to another by matching names.
  /// Used when the transaction date is in a different month than the active month.
  Future<Map<String, String>> _resolveIdsForMonth({
    required CategoryService categoryService,
    required String sourceCategoryId,
    required String sourceItemId,
    required String targetMonthId,
  }) async {
    // Get the source category to know its name
    final sourceCategory =
        await categoryService.getCategoryById(sourceCategoryId);
    if (sourceCategory == null) {
      return {'categoryId': sourceCategoryId, 'itemId': sourceItemId};
    }

    // Find the matching category in the target month by name
    final targetCategories =
        await categoryService.getCategoriesForMonth(targetMonthId);
    final targetCategory = targetCategories.cast<Category?>().firstWhere(
          (c) => c!.name.toLowerCase() == sourceCategory.name.toLowerCase(),
          orElse: () => null,
        );

    if (targetCategory == null) {
      // No matching category in target month — fall back to source IDs
      return {'categoryId': sourceCategoryId, 'itemId': sourceItemId};
    }

    // Find matching item by name
    final sourceItem = sourceCategory.items?.cast<Item?>().firstWhere(
          (i) => i!.id == sourceItemId,
          orElse: () => null,
        );

    if (sourceItem == null || targetCategory.items == null) {
      return {'categoryId': targetCategory.id, 'itemId': sourceItemId};
    }

    final targetItem = targetCategory.items!.cast<Item?>().firstWhere(
          (i) => i!.name.toLowerCase() == sourceItem.name.toLowerCase(),
          orElse: () => null,
        );

    return {
      'categoryId': targetCategory.id,
      'itemId': targetItem?.id ?? sourceItemId,
    };
  }
}

final transactionNotifierProvider =
    AsyncNotifierProvider<TransactionNotifier, List<Transaction>>(
        () => TransactionNotifier());
