import 'package:uuid/uuid.dart';

import '../config/supabase_config.dart';
import '../models/category.dart';

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
    int? sortOrder,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (icon != null) updates['icon'] = icon;
    if (color != null) updates['color'] = color;
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

  /// Copy categories from one month to another
  Future<List<Category>> copyCategoriesFromMonth({
    required String sourceMonthId,
    required String targetMonthId,
    bool copyItems = true,
  }) async {
    final sourceCategories = await getCategoriesForMonth(sourceMonthId);
    final newCategories = <Category>[];

    for (final source in sourceCategories) {
      final newCategory = await createCategory(
        monthId: targetMonthId,
        name: source.name,
        icon: source.icon,
        color: source.color,
        sortOrder: source.sortOrder,
      );
      newCategories.add(newCategory);
    }

    return newCategories;
  }
}
