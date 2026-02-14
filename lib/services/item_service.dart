import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/item.dart';
import '../models/subscription.dart';

class ItemService {
  final _client = SupabaseConfig.client;
  static const _table = 'items';
  final _uuid = const Uuid();

  String get _userId => _client.auth.currentUser!.id;

  /// Get all items for a category
  Future<List<Item>> getItemsForCategory(
    String categoryId, {
    bool includeArchived = false,
  }) async {
    var query = _client
        .from(_table)
        .select()
        .eq('user_id', _userId)
        .eq('category_id', categoryId);
    if (!includeArchived) {
      query = query.eq('is_archived', false);
    }
    final response = await query.order('sort_order', ascending: true);

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

  /// Ensure a category has at least one non-archived item.
  Future<Item> ensureDefaultItemForCategory({
    required String categoryId,
    required String categoryName,
    bool isBudgeted = true,
    double projected = 0,
  }) async {
    final existing = await getItemsForCategory(categoryId);
    if (existing.isNotEmpty) return existing.first;

    return createItem(
      categoryId: categoryId,
      name: categoryName,
      projected: projected,
      isBudgeted: isBudgeted,
    );
  }

  /// Create a new item
  Future<Item> createItem({
    required String categoryId,
    required String name,
    String? subscriptionId,
    double projected = 0,
    bool isArchived = false,
    bool isBudgeted = true,
    bool isRecurring = false,
    int? sortOrder,
    String? notes,
  }) async {
    // Get next sort order if not provided
    if (sortOrder == null) {
      final existing = await getItemsForCategory(
        categoryId,
        includeArchived: true,
      );
      sortOrder = existing.isEmpty
          ? 0
          : existing.map((i) => i.sortOrder).reduce((a, b) => a > b ? a : b) +
              1;
    }

    final now = DateTime.now();
    final item = Item(
      id: _uuid.v4(),
      categoryId: categoryId,
      userId: _userId,
      subscriptionId: subscriptionId,
      name: name,
      projected: projected,
      isArchived: isArchived,
      isBudgeted: isBudgeted,
      isRecurring: isRecurring,
      sortOrder: sortOrder,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );

    final response =
        await _client.from(_table).insert(item.toJson()).select().single();

    return Item.fromJson(response);
  }

  /// Update an item
  Future<Item> updateItem({
    required String itemId,
    String? name,
    String? subscriptionId,
    double? projected,
    bool? isArchived,
    bool? isBudgeted,
    bool? isRecurring,
    int? sortOrder,
    String? notes,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (subscriptionId != null) updates['subscription_id'] = subscriptionId;
    if (projected != null) updates['projected'] = projected;
    if (isArchived != null) updates['is_archived'] = isArchived;
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

  /// Gets an item in a category linked to a specific subscription.
  Future<Item?> getItemForSubscription({
    required String categoryId,
    required String subscriptionId,
  }) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('user_id', _userId)
        .eq('category_id', categoryId)
        .eq('subscription_id', subscriptionId)
        .order('created_at')
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return Item.fromJson(response);
  }

  /// Deterministically gets/creates the budget item mapped to this subscription.
  /// Matching priority:
  /// 1) exact `subscription_id` link,
  /// 2) legacy fallback: same-name unlinked item in the same category,
  /// 3) create a new linked item.
  Future<Item> getOrCreateSubscriptionItem({
    required String subscriptionsCategoryId,
    required Subscription subscription,
  }) async {
    final monthlyCost = _normalizeToMonthly(subscription);
    final normalizedName = subscription.name.trim();

    final linked = await getItemForSubscription(
      categoryId: subscriptionsCategoryId,
      subscriptionId: subscription.id,
    );
    if (linked != null) {
      final needsUpdate = linked.name != normalizedName ||
          (linked.projected - monthlyCost).abs() > 0.01 ||
          linked.isArchived ||
          !linked.isBudgeted ||
          !linked.isRecurring;

      if (!needsUpdate) return linked;
      return updateItem(
        itemId: linked.id,
        name: normalizedName,
        projected: monthlyCost,
        isArchived: false,
        isBudgeted: true,
        isRecurring: true,
      );
    }

    final existingItems = await getItemsForCategory(
      subscriptionsCategoryId,
      includeArchived: true,
    );
    final legacyByName = existingItems.cast<Item?>().firstWhere(
          (item) =>
              item!.subscriptionId == null &&
              item.name.trim().toLowerCase() == normalizedName.toLowerCase(),
          orElse: () => null,
        );

    if (legacyByName != null) {
      return updateItem(
        itemId: legacyByName.id,
        name: normalizedName,
        subscriptionId: subscription.id,
        projected: monthlyCost,
        isArchived: false,
        isBudgeted: true,
        isRecurring: true,
      );
    }

    try {
      return await createItem(
        categoryId: subscriptionsCategoryId,
        name: normalizedName,
        subscriptionId: subscription.id,
        projected: monthlyCost,
        isArchived: false,
        isBudgeted: true,
        isRecurring: true,
      );
    } on PostgrestException catch (e) {
      // Another request may have created the link concurrently.
      if (e.code == '23505') {
        final retry = await getItemForSubscription(
          categoryId: subscriptionsCategoryId,
          subscriptionId: subscription.id,
        );
        if (retry != null) return retry;
      }
      rethrow;
    }
  }

  /// Delete an item
  Future<void> deleteItem(String itemId) async {
    await _client.from(_table).delete().eq('id', itemId).eq('user_id', _userId);
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

  /// Ensure each active subscription has a corresponding item under the
  /// Subscriptions category. Creates missing items, updates projected amounts
  /// if they changed. Does NOT remove items for deleted subscriptions
  /// (they may have historical transactions).
  Future<void> ensureSubscriptionItems(
    String subscriptionsCategoryId,
    List<Subscription> activeSubscriptions,
  ) async {
    for (final sub in activeSubscriptions) {
      await getOrCreateSubscriptionItem(
        subscriptionsCategoryId: subscriptionsCategoryId,
        subscription: sub,
      );
    }
  }

  /// Repairs subscription items for a month:
  /// - ensures active subscriptions are linked by `subscription_id`
  /// - archives stale/unlinked rows with no transaction history
  /// - archives linked rows for inactive/deleted subscriptions when safe
  Future<void> repairSubscriptionItemsForCategory({
    required String subscriptionsCategoryId,
    required List<Subscription> activeSubscriptions,
  }) async {
    await ensureSubscriptionItems(subscriptionsCategoryId, activeSubscriptions);

    final allItems = await getItemsForCategory(
      subscriptionsCategoryId,
      includeArchived: true,
    );
    final activeIds = activeSubscriptions.map((s) => s.id).toSet();

    for (final item in allItems) {
      if (item.subscriptionId != null) {
        if (activeIds.contains(item.subscriptionId)) {
          if (item.isArchived || !item.isBudgeted || !item.isRecurring) {
            await updateItem(
              itemId: item.id,
              isArchived: false,
              isBudgeted: true,
              isRecurring: true,
            );
          }
        } else {
          await _archiveItemIfNoHistory(item);
        }
      } else {
        await _archiveItemIfNoHistory(item);
      }
    }
  }

  Future<void> _archiveItemIfNoHistory(Item item) async {
    final hasHistory = await _itemHasTransactions(item.id);
    if (hasHistory) return;

    if (!item.isArchived || item.isBudgeted || item.isRecurring) {
      await updateItem(
        itemId: item.id,
        isArchived: true,
        isBudgeted: false,
        isRecurring: false,
      );
    }
  }

  Future<bool> _itemHasTransactions(String itemId) async {
    final response = await _client
        .from('transactions')
        .select('id')
        .eq('user_id', _userId)
        .eq('item_id', itemId)
        .limit(1);
    return (response as List).isNotEmpty;
  }

  /// Normalize a subscription's amount to a monthly cost.
  double _normalizeToMonthly(Subscription sub) {
    switch (sub.billingCycle) {
      case BillingCycle.weekly:
        return sub.amount * 4.33;
      case BillingCycle.monthly:
        return sub.amount;
      case BillingCycle.quarterly:
        return sub.amount / 3;
      case BillingCycle.yearly:
        return sub.amount / 12;
      case BillingCycle.custom:
        final days = sub.customCycleDays ?? 30;
        return sub.amount * 30 / days;
    }
  }
}
