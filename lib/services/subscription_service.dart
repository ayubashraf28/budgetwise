import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/subscription.dart';
import '../config/supabase_config.dart';

class SubscriptionPaymentResult {
  final String transactionId;
  final String monthId;
  final String monthName;
  final String categoryId;
  final String itemId;
  final String subscriptionId;
  final double amount;
  final DateTime paidAt;
  final DateTime nextDueDate;
  final bool duplicatePrevented;

  const SubscriptionPaymentResult({
    required this.transactionId,
    required this.monthId,
    required this.monthName,
    required this.categoryId,
    required this.itemId,
    required this.subscriptionId,
    required this.amount,
    required this.paidAt,
    required this.nextDueDate,
    required this.duplicatePrevented,
  });

  factory SubscriptionPaymentResult.fromRpc(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      throw Exception('Invalid date value in payment response: $value');
    }

    return SubscriptionPaymentResult(
      transactionId: json['transaction_id'] as String,
      monthId: json['month_id'] as String,
      monthName: (json['month_name'] as String?) ?? 'Unknown month',
      categoryId: json['category_id'] as String,
      itemId: json['item_id'] as String,
      subscriptionId: json['subscription_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      paidAt: parseDate(json['paid_at']),
      nextDueDate: parseDate(json['next_due_date']),
      duplicatePrevented: json['duplicate_prevented'] as bool? ?? false,
    );
  }
}

class SubscriptionService {
  final SupabaseClient _client = SupabaseConfig.client;
  final String _table = 'subscriptions';
  final _uuid = const Uuid();

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
  Future<List<Subscription>> getUpcomingSubscriptions(
      {int withinDays = 7}) async {
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
    final response = await _client
        .from(_table)
        .insert({
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
        })
        .select()
        .single();

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
    if (reminderDaysBefore != null) {
      updates['reminder_days_before'] = reminderDaysBefore;
    }

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

  /// Atomically marks a subscription as paid:
  /// - creates the expense transaction
  /// - ensures month/category/item mapping
  /// - advances the subscription due date
  Future<SubscriptionPaymentResult> markSubscriptionPaidAtomic({
    required String subscriptionId,
    DateTime? paidAt,
    double? amountOverride,
    String? requestId,
  }) async {
    final paidAtDate = paidAt ?? DateTime.now();
    final effectiveRequestId = requestId ?? _uuid.v4();
    final params = <String, dynamic>{
      'p_subscription_id': subscriptionId,
      'p_paid_at': paidAtDate.toIso8601String().split('T').first,
      if (amountOverride != null) 'p_amount_override': amountOverride,
      'p_request_id': effectiveRequestId,
    };

    try {
      final response =
          await _client.rpc('mark_subscription_paid', params: params);
      Map<String, dynamic> payload;
      if (response is List && response.isNotEmpty && response.first is Map) {
        payload = Map<String, dynamic>.from(response.first as Map);
      } else if (response is Map) {
        payload = Map<String, dynamic>.from(response);
      } else {
        throw Exception('Failed to mark subscription as paid');
      }

      return SubscriptionPaymentResult.fromRpc(payload);
    } catch (error, stackTrace) {
      await logPaymentEvent(
        requestId: effectiveRequestId,
        subscriptionId: subscriptionId,
        status: 'failed',
        paidAt: paidAtDate,
        duplicatePrevented: false,
        errorMessage: error.toString(),
        details: {
          'source': 'subscription_service.mark_subscription_paid_atomic',
        },
      );
      developer.log(
        'markSubscriptionPaidAtomic failed',
        name: 'SubscriptionService',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> logPaymentEvent({
    String? requestId,
    required String subscriptionId,
    required String status,
    DateTime? paidAt,
    String? transactionId,
    bool duplicatePrevented = false,
    String? errorMessage,
    Map<String, dynamic>? details,
  }) async {
    try {
      await _client.from('subscription_payment_events').insert({
        'user_id': _userId,
        'request_id': requestId,
        'subscription_id': subscriptionId,
        'transaction_id': transactionId,
        'status': status,
        'paid_at': paidAt?.toIso8601String().split('T').first,
        'duplicate_prevented': duplicatePrevented,
        'error_message': errorMessage,
        'details': details ?? <String, dynamic>{},
      });
    } catch (_) {
      // Best effort logging only.
    }
  }
}
