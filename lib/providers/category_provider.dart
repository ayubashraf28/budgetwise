import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../services/category_service.dart';
import 'auth_provider.dart';
import 'month_provider.dart';

/// Category service provider
final categoryServiceProvider = Provider<CategoryService>((ref) {
  return CategoryService();
});

/// Categories for the active month (with items)
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final month = ref.watch(activeMonthProvider).value;
  if (month == null) return [];

  final service = ref.read(categoryServiceProvider);
  return service.getCategoriesForMonth(month.id);
});

/// Get a single category by ID
final categoryByIdProvider =
    FutureProvider.family<Category?, String>((ref, categoryId) async {
  final service = ref.read(categoryServiceProvider);
  return service.getCategoryById(categoryId);
});

/// Categories that are over budget
final overBudgetCategoriesProvider = Provider<List<Category>>((ref) {
  final categories = ref.watch(categoriesProvider).value ?? [];
  return categories.where((c) => c.isOverBudget).toList();
});

/// Total projected expenses for active month
final totalProjectedExpensesProvider = Provider<double>((ref) {
  final categories = ref.watch(categoriesProvider).value ?? [];
  return categories.fold<double>(0.0, (sum, cat) => sum + cat.totalProjected);
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

  /// Add a new category
  Future<Category> addCategory({
    required String name,
    String icon = 'wallet',
    String color = '#6366f1',
  }) async {
    final user = ref.read(currentUserProvider);
    final month = ref.read(activeMonthProvider).value;
    if (user == null || month == null) throw Exception('Not ready');

    final category = await _service.createCategory(
      monthId: month.id,
      name: name,
      icon: icon,
      color: color,
    );

    ref.invalidateSelf();
    ref.invalidate(categoriesProvider);
    return category;
  }

  /// Update a category
  Future<Category> updateCategory({
    required String categoryId,
    String? name,
    String? icon,
    String? color,
  }) async {
    final category = await _service.updateCategory(
      categoryId: categoryId,
      name: name,
      icon: icon,
      color: color,
    );

    ref.invalidateSelf();
    ref.invalidate(categoriesProvider);
    ref.invalidate(categoryByIdProvider(categoryId));
    return category;
  }

  /// Delete a category
  Future<void> deleteCategory(String categoryId) async {
    await _service.deleteCategory(categoryId);

    ref.invalidateSelf();
    ref.invalidate(categoriesProvider);
  }

  /// Reorder categories
  Future<void> reorderCategories(List<String> categoryIds) async {
    await _service.reorderCategories(categoryIds);

    ref.invalidateSelf();
    ref.invalidate(categoriesProvider);
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
    return categories;
  }
}

final categoryNotifierProvider =
    AsyncNotifierProvider<CategoryNotifier, List<Category>>(
        () => CategoryNotifier());
