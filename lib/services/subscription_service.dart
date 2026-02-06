import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/subscription.dart';
import '../config/supabase_config.dart';

class SubscriptionService {
  final SupabaseClient _client = SupabaseConfig.client;
  final String _table = 'subscriptions';

  String get _userId => _client.auth.currentUser!.id;

  /// Get all subscriptions for the current user
  Future<List<Subscription>> getSubscriptions() async {
    final response = await _client
        .from(_table)
        .select()
        .eq('user_id', _userId)
        .order('next_due_date', ascending: true);

    return (response as List).map((e) => Subscription.fromJson(e)).toList();
  }

  /// Get only active subscriptions
  Future<List<Subscription>> getActiveSubscriptions() async {
    final response = await _client
        .from(_table)
        .select()
        .eq('user_id', _userId)
        .eq('is_active', true)
        .order('next_due_date', ascending: true);

    return (response as List).map((e) => Subscription.fromJson(e)).toList();
  }

  /// Get subscriptions due within N days
  Future<List<Subscription>> getUpcomingSubscriptions({int withinDays = 7}) async {
    final now = DateTime.now();
    final cutoff = now.add(Duration(days: withinDays));

    final response = await _client
        .from(_table)
        .select()
        .eq('user_id', _userId)
        .eq('is_active', true)
        .lte('next_due_date', cutoff.toIso8601String().split('T').first)
        .order('next_due_date', ascending: true);

    return (response as List).map((e) => Subscription.fromJson(e)).toList();
  }

  /// Get a single subscription by ID
  Future<Subscription?> getSubscriptionById(String subscriptionId) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('id', subscriptionId)
        .eq('user_id', _userId)
        .maybeSingle();

    if (response == null) return null;
    return Subscription.fromJson(response);
  }

  /// Create a new subscription
  Future<Subscription> createSubscription({
    required String name,
    required double amount,
    required DateTime nextDueDate,
    String billingCycle = 'monthly',
    bool isAutoRenew = true,
    int? customCycleDays,
    String? icon,
    String? color,
    String? categoryName,
    String? notes,
    int reminderDaysBefore = 2,
  }) async {
    final response = await _client.from(_table).insert({
      'user_id': _userId,
      'name': name,
      'amount': amount,
      'next_due_date': nextDueDate.toIso8601String().split('T').first,
      'billing_cycle': billingCycle,
      'is_auto_renew': isAutoRenew,
      'custom_cycle_days': customCycleDays,
      'icon': icon ?? 'credit-card',
      'color': color ?? '#6366f1',
      'category_name': categoryName,
      'notes': notes,
      'reminder_days_before': reminderDaysBefore,
    }).select().single();

    return Subscription.fromJson(response);
  }

  /// Update a subscription
  Future<Subscription> updateSubscription({
    required String subscriptionId,
    String? name,
    double? amount,
    DateTime? nextDueDate,
    String? billingCycle,
    bool? isAutoRenew,
    int? customCycleDays,
    String? icon,
    String? color,
    String? categoryName,
    String? notes,
    bool? isActive,
    int? reminderDaysBefore,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (amount != null) updates['amount'] = amount;
    if (nextDueDate != null) {
      updates['next_due_date'] = nextDueDate.toIso8601String().split('T').first;
    }
    if (billingCycle != null) updates['billing_cycle'] = billingCycle;
    if (isAutoRenew != null) updates['is_auto_renew'] = isAutoRenew;
    if (customCycleDays != null) updates['custom_cycle_days'] = customCycleDays;
    if (icon != null) updates['icon'] = icon;
    if (color != null) updates['color'] = color;
    if (categoryName != null) updates['category_name'] = categoryName;
    if (notes != null) updates['notes'] = notes;
    if (isActive != null) updates['is_active'] = isActive;
    if (reminderDaysBefore != null) updates['reminder_days_before'] = reminderDaysBefore;

    final response = await _client
        .from(_table)
        .update(updates)
        .eq('id', subscriptionId)
        .eq('user_id', _userId)
        .select()
        .single();

    return Subscription.fromJson(response);
  }

  /// Delete a subscription
  Future<void> deleteSubscription(String subscriptionId) async {
    await _client
        .from(_table)
        .delete()
        .eq('id', subscriptionId)
        .eq('user_id', _userId);
  }

  /// Advance the due date for auto-renewing subscriptions that are past due
  Future<Subscription> advanceDueDate(String subscriptionId) async {
    final sub = await getSubscriptionById(subscriptionId);
    if (sub == null) throw Exception('Subscription not found');

    final newDate = sub.calculatedNextDueDate;
    return updateSubscription(
      subscriptionId: subscriptionId,
      nextDueDate: newDate,
    );
  }
}

