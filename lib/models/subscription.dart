import 'package:flutter/material.dart';

enum BillingCycle { weekly, monthly, quarterly, yearly, custom }

@immutable
class Subscription {
  final String id;
  final String userId;
  final String name;
  final double amount;
  final String currency;
  final String icon;
  final String color;
  final BillingCycle billingCycle;
  final DateTime nextDueDate;
  final bool isAutoRenew;
  final int? customCycleDays;
  final String? categoryName;
  final String? notes;
  final String? defaultAccountId;
  final bool isActive;
  final int reminderDaysBefore;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Subscription({
    required this.id,
    required this.userId,
    required this.name,
    this.amount = 0,
    this.currency = 'GBP',
    this.icon = 'credit-card',
    this.color = '#6366f1',
    this.billingCycle = BillingCycle.monthly,
    required this.nextDueDate,
    this.isAutoRenew = true,
    this.customCycleDays,
    this.categoryName,
    this.notes,
    this.defaultAccountId,
    this.isActive = true,
    this.reminderDaysBefore = 2,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'GBP',
      icon: json['icon'] as String? ?? 'credit-card',
      color: json['color'] as String? ?? '#6366f1',
      billingCycle: _parseBillingCycle(json['billing_cycle'] as String?),
      nextDueDate: DateTime.parse(json['next_due_date'] as String),
      isAutoRenew: json['is_auto_renew'] as bool? ?? true,
      customCycleDays: json['custom_cycle_days'] as int?,
      categoryName: json['category_name'] as String?,
      notes: json['notes'] as String?,
      defaultAccountId: json['default_account_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      reminderDaysBefore: json['reminder_days_before'] as int? ?? 2,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'amount': amount,
      'currency': currency,
      'icon': icon,
      'color': color,
      'billing_cycle': billingCycle.name,
      'next_due_date': nextDueDate.toIso8601String().split('T').first,
      'is_auto_renew': isAutoRenew,
      'custom_cycle_days': customCycleDays,
      'category_name': categoryName,
      'notes': notes,
      'default_account_id': defaultAccountId,
      'is_active': isActive,
      'reminder_days_before': reminderDaysBefore,
    };
  }

  Subscription copyWith({
    String? id,
    String? userId,
    String? name,
    double? amount,
    String? currency,
    String? icon,
    String? color,
    BillingCycle? billingCycle,
    DateTime? nextDueDate,
    bool? isAutoRenew,
    int? customCycleDays,
    String? categoryName,
    String? notes,
    String? defaultAccountId,
    bool clearDefaultAccountId = false,
    bool? isActive,
    int? reminderDaysBefore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      billingCycle: billingCycle ?? this.billingCycle,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      isAutoRenew: isAutoRenew ?? this.isAutoRenew,
      customCycleDays: customCycleDays ?? this.customCycleDays,
      categoryName: categoryName ?? this.categoryName,
      notes: notes ?? this.notes,
      defaultAccountId: clearDefaultAccountId
          ? null
          : defaultAccountId ?? this.defaultAccountId,
      isActive: isActive ?? this.isActive,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ── Computed Properties ──

  /// Color as Flutter Color value
  Color get colorValue {
    try {
      final hex = color.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return const Color(0xFF6366F1); // Default indigo
    }
  }

  /// Days until next payment
  int get daysUntilDue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);
    return due.difference(today).inDays;
  }

  /// Whether payment is due today
  bool get isDueToday => daysUntilDue == 0;

  /// Whether payment is overdue
  bool get isOverdue => daysUntilDue < 0;

  /// Whether this subscription should show in "Upcoming" section
  bool get isUpcoming =>
      daysUntilDue >= 0 && daysUntilDue <= reminderDaysBefore;

  /// Whether due within the next 7 days (for home page display)
  bool get isDueSoon => daysUntilDue >= 0 && daysUntilDue <= 7;

  /// Human-readable billing cycle
  String get billingCycleLabel {
    switch (billingCycle) {
      case BillingCycle.weekly:
        return 'Weekly';
      case BillingCycle.monthly:
        return 'Monthly';
      case BillingCycle.quarterly:
        return 'Quarterly';
      case BillingCycle.yearly:
        return 'Yearly';
      case BillingCycle.custom:
        return customCycleDays != null
            ? 'Every $customCycleDays days'
            : 'Custom';
    }
  }

  /// Calculate the next due date after the current one passes
  DateTime get calculatedNextDueDate {
    if (!isAutoRenew) return nextDueDate;

    switch (billingCycle) {
      case BillingCycle.weekly:
        return nextDueDate.add(const Duration(days: 7));
      case BillingCycle.monthly:
        return DateTime(
            nextDueDate.year, nextDueDate.month + 1, nextDueDate.day);
      case BillingCycle.quarterly:
        return DateTime(
            nextDueDate.year, nextDueDate.month + 3, nextDueDate.day);
      case BillingCycle.yearly:
        return DateTime(
            nextDueDate.year + 1, nextDueDate.month, nextDueDate.day);
      case BillingCycle.custom:
        return nextDueDate.add(Duration(days: customCycleDays ?? 30));
    }
  }

  /// Status text for display
  String get status {
    if (!isActive) return 'Paused';
    if (isOverdue) return 'Overdue';
    if (isDueToday) return 'Due today';
    if (isDueSoon) return 'Due in $daysUntilDue days';
    return 'Active';
  }

  static BillingCycle _parseBillingCycle(String? value) {
    switch (value) {
      case 'weekly':
        return BillingCycle.weekly;
      case 'quarterly':
        return BillingCycle.quarterly;
      case 'yearly':
        return BillingCycle.yearly;
      case 'custom':
        return BillingCycle.custom;
      default:
        return BillingCycle.monthly;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Subscription && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Subscription(id: $id, name: $name, amount: $amount, due: $nextDueDate)';
}
