import 'package:uuid/uuid.dart';

import '../config/supabase_config.dart';
import '../models/category.dart';
import '../models/month.dart';
import 'item_service.dart';

class CategoryService {
  final _client = SupabaseConfig.client;
  static const _table = 'categories';
  final _uuid = const Uuid();

  String get _userId => _client.auth.currentUser!.id;

  /// Get all categories for a month with their items
  Future<List<Category>> getCategoriesForMonth(String monthId) async {
    final response = await _client
        .from(_table)
        .select('*, items(*)')
        .eq('user_id', _userId)
        .eq('month_id', monthId)
        .order('sort_order', ascending: true);

    return (response as List).map((e) => Category.fromJson(e)).toList();
  }

  /// Get all categories for multiple months with their items
  Future<List<Category>> getCategoriesForMonths(List<String> monthIds) async {
    if (monthIds.isEmpty) return [];
    final response = await _client
        .from(_table)
        .select('*, items(*)')
        .eq('user_id', _userId)
        .inFilter('month_id', monthIds)
        .order('sort_order', ascending: true);
    return (response as List).map((e) => Category.fromJson(e)).toList();
  }

  /// Get a single category by ID with items
  Future<Category?> getCategoryById(String categoryId) async {
    final response = await _client
        .from(_table)
        .select('*, items(*)')
        .eq('id', categoryId)
        .eq('user_id', _userId)
        .maybeSingle();

    if (response == null) return null;
    return Category.fromJson(response);
  }

  /// Create a new category
  Future<Category> createCategory({
    required String monthId,
    required String name,
    String icon = 'wallet',
    String color = '#6366f1',
    bool isBudgeted = true,
    int? sortOrder,
  }) async {
    // Get next sort order if not provided
    if (sortOrder == null) {
      final existing = await getCategoriesForMonth(monthId);
      sortOrder = existing.isEmpty
          ? 0
          : existing.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
    }

    final now = DateTime.now();
    final category = Category(
      id: _uuid.v4(),
      userId: _userId,
      monthId: monthId,
      name: name,
      icon: icon,
      color: color,
      isBudgeted: isBudgeted,
      sortOrder: sortOrder,
      createdAt: now,
      updatedAt: now,
    );

    final response = await _client
        .from(_table)
        .insert(category.toJson())
        .select('*, items(*)')
        .single();

    return Category.fromJson(response);
  }

  /// Update a category
  Future<Category> updateCategory({
    required String categoryId,
    String? name,
    String? icon,
    String? color,
    bool? isBudgeted,
    int? sortOrder,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (icon != null) updates['icon'] = icon;
    if (color != null) updates['color'] = color;
    if (isBudgeted != null) updates['is_budgeted'] = isBudgeted;
    if (sortOrder != null) updates['sort_order'] = sortOrder;

    if (updates.isEmpty) {
      final current = await getCategoryById(categoryId);
      if (current == null) throw Exception('Category not found');
      return current;
    }

    final response = await _client
        .from(_table)
        .update(updates)
        .eq('id', categoryId)
        .eq('user_id', _userId)
        .select('*, items(*)')
        .single();

    return Category.fromJson(response);
  }

  /// Delete a category (will cascade delete items)
  Future<void> deleteCategory(String categoryId) async {
    await _client
        .from(_table)
        .delete()
        .eq('id', categoryId)
        .eq('user_id', _userId);
  }

  /// Reorder categories
  Future<void> reorderCategories(List<String> categoryIds) async {
    for (int i = 0; i < categoryIds.length; i++) {
      await _client
          .from(_table)
          .update({'sort_order': i})
          .eq('id', categoryIds[i])
          .eq('user_id', _userId);
    }
  }

  /// Copy categories from one month to another (with items if copyItems=true)
  Future<List<Category>> copyCategoriesFromMonth({
    required String sourceMonthId,
    required String targetMonthId,
    bool copyItems = true,
  }) async {
    final sourceCategories = await getCategoriesForMonth(sourceMonthId);
    final itemService = ItemService();
    final newCategories = <Category>[];

    for (final source in sourceCategories) {
      final newCategory = await createCategory(
        monthId: targetMonthId,
        name: source.name,
        icon: source.icon,
        color: source.color,
        isBudgeted: source.isBudgeted,
        sortOrder: source.sortOrder,
      );

      // Copy items from source category to new category
      if (copyItems && source.items != null && source.items!.isNotEmpty) {
        await itemService.copyItemsFromCategory(
          sourceCategoryId: source.id,
          targetCategoryId: newCategory.id,
        );
      }

      // Re-fetch to include the copied items
      final withItems = await getCategoryById(newCategory.id);
      newCategories.add(withItems ?? newCategory);
    }

    return newCategories;
  }

  /// Ensure a month has categories. If empty, copy from the most recent
  /// month that has categories (with items, budgets carry forward).
  Future<List<Category>> ensureCategoriesForMonth(String monthId) async {
    final existing = await getCategoriesForMonth(monthId);
    if (existing.isNotEmpty) return existing;

    // Find the most recent month that has categories
    final allMonths = await _client
        .from('months')
        .select()
        .eq('user_id', _userId)
        .order('start_date', ascending: false);

    for (final monthJson in allMonths) {
      final otherMonthId = monthJson['id'] as String;
      if (otherMonthId == monthId) continue;

      final otherCategories = await getCategoriesForMonth(otherMonthId);
      if (otherCategories.isNotEmpty) {
        return copyCategoriesFromMonth(
          sourceMonthId: otherMonthId,
          targetMonthId: monthId,
          copyItems: true,
        );
      }
    }

    // No months have categories — return empty (user will create from scratch)
    return [];
  }

  /// Sync a newly created category to all other months in the year.
  /// Creates the category (without items) in each month that doesn't
  /// already have a category with the same name.
  Future<void> syncCategoryToAllMonths({
    required Category category,
    required List<Month> allYearMonths,
  }) async {
    for (final month in allYearMonths) {
      if (month.id == category.monthId) continue; // Skip the source month

      // Check if this month already has a category with the same name
      final existing = await getCategoriesForMonth(month.id);
      final alreadyExists = existing.any(
        (c) => c.name.toLowerCase() == category.name.toLowerCase(),
      );

      if (!alreadyExists) {
        await createCategory(
          monthId: month.id,
          name: category.name,
          icon: category.icon,
          color: category.color,
          isBudgeted: category.isBudgeted,
          sortOrder: category.sortOrder,
        );
      }
    }
  }

  /// Ensure a "Subscriptions" category exists for the given month.
  /// Returns the existing or newly created category.
  Future<Category> ensureSubscriptionsCategory(String monthId) async {
    final existing = await getCategoriesForMonth(monthId);
    final subsCat = existing.cast<Category?>().firstWhere(
      (c) => c!.name == 'Subscriptions',
      orElse: () => null,
    );
    if (subsCat != null) return subsCat;

    return createCategory(
      monthId: monthId,
      name: 'Subscriptions',
      icon: 'repeat',
      color: '#8b5cf6',
      isBudgeted: true,
    );
  }
}
