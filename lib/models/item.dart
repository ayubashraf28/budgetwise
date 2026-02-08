import 'package:flutter/foundation.dart';

@immutable
class Item {
  final String id;
  final String categoryId;
  final String userId;
  final String? subscriptionId;
  final String name;
  final double projected;
  final double actual; // Calculated from transactions
  final bool isArchived;
  final bool isBudgeted;
  final bool isRecurring;
  final int sortOrder;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Item({
    required this.id,
    required this.categoryId,
    required this.userId,
    this.subscriptionId,
    required this.name,
    this.projected = 0,
    this.actual = 0,
    this.isArchived = false,
    this.isBudgeted = true,
    this.isRecurring = false,
    this.sortOrder = 0,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      userId: json['user_id'] as String,
      subscriptionId: json['subscription_id'] as String?,
      name: json['name'] as String,
      projected: (json['projected'] as num?)?.toDouble() ?? 0,
      actual: (json['actual'] as num?)?.toDouble() ?? 0,
      isArchived: json['is_archived'] as bool? ?? false,
      isBudgeted: json['is_budgeted'] as bool? ?? true,
      isRecurring: json['is_recurring'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'user_id': userId,
      'subscription_id': subscriptionId,
      'name': name,
      'projected': projected,
      'is_archived': isArchived,
      'is_budgeted': isBudgeted,
      'is_recurring': isRecurring,
      'sort_order': sortOrder,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Item copyWith({
    String? id,
    String? categoryId,
    String? userId,
    String? subscriptionId,
    String? name,
    double? projected,
    double? actual,
    bool? isArchived,
    bool? isBudgeted,
    bool? isRecurring,
    int? sortOrder,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      userId: userId ?? this.userId,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      name: name ?? this.name,
      projected: projected ?? this.projected,
      actual: actual ?? this.actual,
      isArchived: isArchived ?? this.isArchived,
      isBudgeted: isBudgeted ?? this.isBudgeted,
      isRecurring: isRecurring ?? this.isRecurring,
      sortOrder: sortOrder ?? this.sortOrder,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Whether this item has an active budget
  bool get hasBudget => isBudgeted && projected > 0;

  /// Difference (positive = under budget)
  double get difference => projected - actual;

  /// Whether item is over budget (only applies to budgeted items)
  bool get isOverBudget => isBudgeted && actual > projected && projected > 0;

  /// Whether item is on track (at or under budget)
  bool get isOnTrack => !isBudgeted || actual <= projected;

  /// Progress percentage (can exceed 100%)
  double get progressPercentage {
    if (!isBudgeted) return 0;
    if (projected <= 0) return actual > 0 ? 100 : 0;
    return (actual / projected) * 100;
  }

  /// Remaining budget (can be negative)
  double get remaining => projected - actual;

  /// Status string for display
  String get status {
    if (!isBudgeted) return 'Spending only';
    if (projected <= 0) return 'No budget';
    if (actual == 0) return 'Not started';
    if (isOverBudget) return 'Over budget';
    if (actual == projected) return 'On budget';
    return 'Under budget';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Item && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Item(id: $id, name: $name, projected: $projected, actual: $actual)';
}
