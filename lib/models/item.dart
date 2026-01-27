import 'package:flutter/foundation.dart';

@immutable
class Item {
  final String id;
  final String categoryId;
  final String userId;
  final String name;
  final double projected;
  final double actual; // Calculated from transactions
  final bool isRecurring;
  final int sortOrder;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Item({
    required this.id,
    required this.categoryId,
    required this.userId,
    required this.name,
    this.projected = 0,
    this.actual = 0,
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
      name: json['name'] as String,
      projected: (json['projected'] as num?)?.toDouble() ?? 0,
      actual: (json['actual'] as num?)?.toDouble() ?? 0,
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
      'name': name,
      'projected': projected,
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
    String? name,
    double? projected,
    double? actual,
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
      name: name ?? this.name,
      projected: projected ?? this.projected,
      actual: actual ?? this.actual,
      isRecurring: isRecurring ?? this.isRecurring,
      sortOrder: sortOrder ?? this.sortOrder,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Difference (positive = under budget)
  double get difference => projected - actual;

  /// Whether item is over budget
  bool get isOverBudget => actual > projected && projected > 0;

  /// Whether item is on track (at or under budget)
  bool get isOnTrack => actual <= projected;

  /// Progress percentage (can exceed 100%)
  double get progressPercentage {
    if (projected <= 0) return actual > 0 ? 100 : 0;
    return (actual / projected) * 100;
  }

  /// Remaining budget (can be negative)
  double get remaining => projected - actual;

  /// Status string for display
  String get status {
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
