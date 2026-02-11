import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../models/transaction.dart';
import '../services/category_service.dart';
import '../services/month_service.dart';
import '../services/transaction_service.dart';
import 'auth_provider.dart';
import 'month_provider.dart';

/// Category service provider
final categoryServiceProvider = Provider<CategoryService>((ref) {
  return CategoryService();
});

/// Transaction service provider (for calculating actuals)
final _transactionServiceProvider = Provider<TransactionService>((ref) {
  return TransactionService();
});

/// Categories for the active month (with items and calculated actuals)
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final month = ref.watch(activeMonthProvider).value;
  if (month == null) return [];

  final categoryService = ref.read(categoryServiceProvider);
  final transactionService = ref.read(_transactionServiceProvider);

  // Fetch categories with items
  final categories = await categoryService.getCategoriesForMonth(month.id);

  // Fetch all transactions for this month to calculate actuals
  final transactions =
      await transactionService.getTransactionsForMonth(month.id);

  // Calculate actuals for each item from transactions
  return categories.map((category) {
    final visibleItems = category.items?.where((item) => !item.isArchived);
    final updatedItems = visibleItems?.map((item) {
      // Sum transactions for this item
      final itemTransactions = transactions.where(
        (tx) => tx.itemId == item.id && tx.type == TransactionType.expense,
      );
      final actual = itemTransactions.fold<double>(
        0.0,
        (sum, tx) => sum + tx.amount,
      );
      return item.copyWith(actual: actual);
    }).toList();

    return category.copyWith(items: updatedItems);
  }).toList();
});

/// Categories for a specific month (with items and calculated actuals).
/// Parameterized version of [categoriesProvider] — used by the budget screen
/// so it can browse months independently of [activeMonthProvider].
final categoriesForMonthProvider =
    FutureProvider.family<List<Category>, String>((ref, monthId) async {
  final categoryService = ref.read(categoryServiceProvider);
  final transactionService = ref.read(_transactionServiceProvider);

  final categories = await categoryService.getCategoriesForMonth(monthId);
  final transactions =
      await transactionService.getTransactionsForMonth(monthId);

  return categories.map((category) {
    final visibleItems = category.items?.where((item) => !item.isArchived);
    final updatedItems = visibleItems?.map((item) {
      final itemTransactions = transactions.where(
        (tx) => tx.itemId == item.id && tx.type == TransactionType.expense,
      );
      final actual = itemTransactions.fold<double>(
        0.0,
        (sum, tx) => sum + tx.amount,
      );
      return item.copyWith(actual: actual);
    }).toList();

    return category.copyWith(items: updatedItems);
  }).toList();
});

/// Get a single category by ID (with calculated actuals from transactions)
final categoryByIdProvider =
    FutureProvider.family<Category?, String>((ref, categoryId) async {
  final service = ref.read(categoryServiceProvider);
  final transactionService = ref.read(_transactionServiceProvider);

  final category = await service.getCategoryById(categoryId);
  if (category == null) return null;

  // Fetch transactions for this category's month to calculate actuals
  final transactions =
      await transactionService.getTransactionsForMonth(category.monthId);

  // Calculate actuals for each item from transactions
  final visibleItems = category.items?.where((item) => !item.isArchived);
  final updatedItems = visibleItems?.map((item) {
    final itemTransactions = transactions.where(
      (tx) => tx.itemId == item.id && tx.type == TransactionType.expense,
    );
    final actual = itemTransactions.fold<double>(
      0.0,
      (sum, tx) => sum + tx.amount,
    );
    return item.copyWith(actual: actual);
  }).toList();

  return category.copyWith(items: updatedItems);
});

/// Categories that are over budget (only budgeted categories)
final overBudgetCategoriesProvider = Provider<List<Category>>((ref) {
  final categories = ref.watch(categoriesProvider).value ?? [];
  return categories.where((c) => c.isBudgeted && c.isOverBudget).toList();
});

/// Total projected expenses for active month (only budgeted categories)
final totalProjectedExpensesProvider = Provider<double>((ref) {
  final categories = ref.watch(categoriesProvider).value ?? [];
  return categories
      .where((cat) => cat.isBudgeted)
      .fold<double>(0.0, (sum, cat) => sum + cat.totalProjected);
});

/// Total actual expenses for active month
final totalActualExpensesProvider = Provider<double>((ref) {
  final categories = ref.watch(categoriesProvider).value ?? [];
  return categories.fold<double>(0.0, (sum, cat) => sum + cat.totalActual);
});

/// Expense difference (projected - actual, positive = under budget)
final expenseDifferenceProvider = Provider<double>((ref) {
  final projected = ref.watch(totalProjectedExpensesProvider);
  final actual = ref.watch(totalActualExpensesProvider);
  return projected - actual;
});

/// Whether expenses are under budget
final isUnderBudgetProvider = Provider<bool>((ref) {
  final projected = ref.watch(totalProjectedExpensesProvider);
  final actual = ref.watch(totalActualExpensesProvider);
  return actual <= projected;
});

/// Category notifier for mutations
class CategoryNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    final month = ref.watch(activeMonthProvider).value;
    if (month == null) return [];

    final service = ref.read(categoryServiceProvider);
    return service.getCategoriesForMonth(month.id);
  }

  CategoryService get _service => ref.read(categoryServiceProvider);

  /// Add a new category (syncs to all months in the year)
  Future<Category> addCategory({
    required String name,
    String icon = 'wallet',
    String color = '#6366f1',
    bool isBudgeted = true,
  }) async {
    final user = ref.read(currentUserProvider);
    final month = ref.read(activeMonthProvider).value;
    if (user == null || month == null) throw Exception('Not ready');

    final category = await _service.createCategory(
      monthId: month.id,
      name: name,
      icon: icon,
      color: color,
      isBudgeted: isBudgeted,
    );

    // Sync to all other months in the year
    final monthService = MonthService();
    final allMonths = await monthService.getAllMonths();
    final yearMonths = allMonths
        .where((m) => m.startDate.year == month.startDate.year)
        .toList();

    await _service.syncCategoryToAllMonths(
      category: category,
      allYearMonths: yearMonths,
    );

    ref.invalidateSelf();
    ref.invalidate(categoriesProvider);
    ref.invalidate(categoriesForMonthProvider);
    return category;
  }

  /// Update a category
  Future<Category> updateCategory({
    required String categoryId,
    String? name,
    String? icon,
    String? color,
    bool? isBudgeted,
  }) async {
    final category = await _service.updateCategory(
      categoryId: categoryId,
      name: name,
      icon: icon,
      color: color,
      isBudgeted: isBudgeted,
    );

    ref.invalidateSelf();
    ref.invalidate(categoriesProvider);
    ref.invalidate(categoriesForMonthProvider);
    ref.invalidate(categoryByIdProvider(categoryId));
    return category;
  }

  /// Delete a category
  Future<void> deleteCategory(String categoryId) async {
    await _service.deleteCategory(categoryId);

    ref.invalidateSelf();
    ref.invalidate(categoriesProvider);
    ref.invalidate(categoriesForMonthProvider);
  }

  /// Reorder categories
  Future<void> reorderCategories(List<String> categoryIds) async {
    await _service.reorderCategories(categoryIds);

    ref.invalidateSelf();
    ref.invalidate(categoriesProvider);
    ref.invalidate(categoriesForMonthProvider);
  }

  /// Copy categories from another month
  Future<List<Category>> copyFromMonth({
    required String sourceMonthId,
    bool copyItems = true,
  }) async {
    final month = ref.read(activeMonthProvider).value;
    if (month == null) throw Exception('No active month');

    final categories = await _service.copyCategoriesFromMonth(
      sourceMonthId: sourceMonthId,
      targetMonthId: month.id,
      copyItems: copyItems,
    );

    ref.invalidateSelf();
    ref.invalidate(categoriesProvider);
    ref.invalidate(categoriesForMonthProvider);
    return categories;
  }
}

final categoryNotifierProvider =
    AsyncNotifierProvider<CategoryNotifier, List<Category>>(
        () => CategoryNotifier());
