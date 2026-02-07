import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/item.dart';
import '../services/item_service.dart';
import 'auth_provider.dart';
import 'category_provider.dart';

/// Item service provider
final itemServiceProvider = Provider<ItemService>((ref) {
  return ItemService();
});

/// Items for a specific category
final itemsByCategoryProvider =
    FutureProvider.family<List<Item>, String>((ref, categoryId) async {
  final service = ref.read(itemServiceProvider);
  return service.getItemsForCategory(categoryId);
});

/// Get a single item by ID
final itemByIdProvider =
    FutureProvider.family<Item?, String>((ref, itemId) async {
  final service = ref.read(itemServiceProvider);
  return service.getItemById(itemId);
});

/// Item notifier for a specific category
class ItemNotifier extends FamilyAsyncNotifier<List<Item>, String> {
  @override
  Future<List<Item>> build(String categoryId) async {
    final service = ref.read(itemServiceProvider);
    return service.getItemsForCategory(categoryId);
  }

  ItemService get _service => ref.read(itemServiceProvider);

  /// Add a new item to the category
  Future<Item> addItem({
    required String name,
    double projected = 0,
    bool isBudgeted = true,
    bool isRecurring = false,
    String? notes,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw Exception('Not authenticated');

    final item = await _service.createItem(
      categoryId: arg,
      name: name,
      projected: projected,
      isBudgeted: isBudgeted,
      isRecurring: isRecurring,
      notes: notes,
    );

    ref.invalidateSelf();
    ref.invalidate(itemsByCategoryProvider(arg));
    ref.invalidate(categoriesProvider);
    return item;
  }

  /// Update an item
  Future<Item> updateItem({
    required String itemId,
    String? name,
    double? projected,
    bool? isBudgeted,
    bool? isRecurring,
    String? notes,
  }) async {
    final item = await _service.updateItem(
      itemId: itemId,
      name: name,
      projected: projected,
      isBudgeted: isBudgeted,
      isRecurring: isRecurring,
      notes: notes,
    );

    ref.invalidateSelf();
    ref.invalidate(itemsByCategoryProvider(arg));
    ref.invalidate(itemByIdProvider(itemId));
    ref.invalidate(categoriesProvider);
    return item;
  }

  /// Delete an item
  Future<void> deleteItem(String itemId) async {
    await _service.deleteItem(itemId);

    ref.invalidateSelf();
    ref.invalidate(itemsByCategoryProvider(arg));
    ref.invalidate(categoriesProvider);
  }

  /// Reorder items within the category
  Future<void> reorderItems(List<String> itemIds) async {
    await _service.reorderItems(itemIds);

    ref.invalidateSelf();
    ref.invalidate(itemsByCategoryProvider(arg));
  }

  /// Move an item to a different category
  Future<Item> moveToCategory(String itemId, String newCategoryId) async {
    final item = await _service.moveItemToCategory(
      itemId: itemId,
      newCategoryId: newCategoryId,
    );

    ref.invalidateSelf();
    ref.invalidate(itemsByCategoryProvider(arg));
    ref.invalidate(itemsByCategoryProvider(newCategoryId));
    ref.invalidate(categoriesProvider);
    return item;
  }
}

final itemNotifierProvider =
    AsyncNotifierProvider.family<ItemNotifier, List<Item>, String>(
        () => ItemNotifier());
