import 'package:uuid/uuid.dart';

import '../config/supabase_config.dart';
import '../models/item.dart';

class ItemService {
  final _client = SupabaseConfig.client;
  static const _table = 'items';
  final _uuid = const Uuid();

  String get _userId => _client.auth.currentUser!.id;

  /// Get all items for a category
  Future<List<Item>> getItemsForCategory(String categoryId) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('user_id', _userId)
        .eq('category_id', categoryId)
        .order('sort_order', ascending: true);

    return (response as List).map((e) => Item.fromJson(e)).toList();
  }

  /// Get a single item by ID
  Future<Item?> getItemById(String itemId) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('id', itemId)
        .eq('user_id', _userId)
        .maybeSingle();

    if (response == null) return null;
    return Item.fromJson(response);
  }

  /// Create a new item
  Future<Item> createItem({
    required String categoryId,
    required String name,
    double projected = 0,
    bool isBudgeted = true,
    bool isRecurring = false,
    int? sortOrder,
    String? notes,
  }) async {
    // Get next sort order if not provided
    if (sortOrder == null) {
      final existing = await getItemsForCategory(categoryId);
      sortOrder = existing.isEmpty
          ? 0
          : existing.map((i) => i.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
    }

    final now = DateTime.now();
    final item = Item(
      id: _uuid.v4(),
      categoryId: categoryId,
      userId: _userId,
      name: name,
      projected: projected,
      isBudgeted: isBudgeted,
      isRecurring: isRecurring,
      sortOrder: sortOrder,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );

    final response = await _client
        .from(_table)
        .insert(item.toJson())
        .select()
        .single();

    return Item.fromJson(response);
  }

  /// Update an item
  Future<Item> updateItem({
    required String itemId,
    String? name,
    double? projected,
    bool? isBudgeted,
    bool? isRecurring,
    int? sortOrder,
    String? notes,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (projected != null) updates['projected'] = projected;
    if (isBudgeted != null) updates['is_budgeted'] = isBudgeted;
    if (isRecurring != null) updates['is_recurring'] = isRecurring;
    if (sortOrder != null) updates['sort_order'] = sortOrder;
    if (notes != null) updates['notes'] = notes;

    if (updates.isEmpty) {
      final current = await getItemById(itemId);
      if (current == null) throw Exception('Item not found');
      return current;
    }

    final response = await _client
        .from(_table)
        .update(updates)
        .eq('id', itemId)
        .eq('user_id', _userId)
        .select()
        .single();

    return Item.fromJson(response);
  }

  /// Delete an item
  Future<void> deleteItem(String itemId) async {
    await _client
        .from(_table)
        .delete()
        .eq('id', itemId)
        .eq('user_id', _userId);
  }

  /// Reorder items within a category
  Future<void> reorderItems(List<String> itemIds) async {
    for (int i = 0; i < itemIds.length; i++) {
      await _client
          .from(_table)
          .update({'sort_order': i})
          .eq('id', itemIds[i])
          .eq('user_id', _userId);
    }
  }

  /// Move an item to a different category
  Future<Item> moveItemToCategory({
    required String itemId,
    required String newCategoryId,
  }) async {
    final response = await _client
        .from(_table)
        .update({'category_id': newCategoryId})
        .eq('id', itemId)
        .eq('user_id', _userId)
        .select()
        .single();

    return Item.fromJson(response);
  }

  /// Copy items from one category to another
  Future<List<Item>> copyItemsFromCategory({
    required String sourceCategoryId,
    required String targetCategoryId,
  }) async {
    final sourceItems = await getItemsForCategory(sourceCategoryId);
    final newItems = <Item>[];

    for (final source in sourceItems) {
      final newItem = await createItem(
        categoryId: targetCategoryId,
        name: source.name,
        projected: source.projected,
        isBudgeted: source.isBudgeted,
        isRecurring: source.isRecurring,
        sortOrder: source.sortOrder,
        notes: source.notes,
      );
      newItems.add(newItem);
    }

    return newItems;
  }
}
