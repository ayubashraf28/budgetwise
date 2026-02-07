import 'package:flutter/material.dart';
import 'item.dart';

@immutable
class Category {
  final String id;
  final String userId;
  final String monthId;
  final String name;
  final String icon;
  final String color;
  final bool isBudgeted;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Items within this category (populated by joins)
  final List<Item>? items;

  const Category({
    required this.id,
    required this.userId,
    required this.monthId,
    required this.name,
    this.icon = 'wallet',
    this.color = '#6366f1',
    this.isBudgeted = true,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    this.items,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    List<Item>? itemsList;
    if (json['items'] != null) {
      itemsList = (json['items'] as List)
          .map((e) => Item.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return Category(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      monthId: json['month_id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? 'wallet',
      color: json['color'] as String? ?? '#6366f1',
      isBudgeted: json['is_budgeted'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      items: itemsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'month_id': monthId,
      'name': name,
      'icon': icon,
      'color': color,
      'is_budgeted': isBudgeted,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Category copyWith({
    String? id,
    String? userId,
    String? monthId,
    String? name,
    String? icon,
    String? color,
    bool? isBudgeted,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Item>? items,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      monthId: monthId ?? this.monthId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isBudgeted: isBudgeted ?? this.isBudgeted,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }

  /// Parse hex color string to Flutter Color
  Color get colorValue {
    try {
      final hex = color.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return const Color(0xFF6366F1); // Default indigo
    }
  }

  /// Total projected amount for all items
  double get totalProjected {
    if (items == null || items!.isEmpty) return 0;
    return items!.fold(0.0, (sum, item) => sum + item.projected);
  }

  /// Total actual amount for all items
  double get totalActual {
    if (items == null || items!.isEmpty) return 0;
    return items!.fold(0.0, (sum, item) => sum + item.actual);
  }

  /// Difference (positive = under budget)
  double get difference => totalProjected - totalActual;

  /// Whether category is over budget (only applies to budgeted categories)
  bool get isOverBudget => isBudgeted && totalActual > totalProjected && totalProjected > 0;

  /// Whether category is exactly on budget
  bool get isOnBudget => totalActual == totalProjected;

  /// Whether category is under budget
  bool get isUnderBudget => totalActual < totalProjected;

  /// Progress percentage (can exceed 100%)
  double get progressPercentage {
    if (!isBudgeted) return 0;
    if (totalProjected <= 0) return totalActual > 0 ? 100 : 0;
    return (totalActual / totalProjected) * 100;
  }

  /// Amount remaining (can be negative if over budget)
  double get remaining => totalProjected - totalActual;

  /// Number of items in this category
  int get itemCount => items?.length ?? 0;

  /// Whether this category has an active budget
  bool get hasBudget => isBudgeted && totalProjected > 0;

  /// Number of items that are over budget
  int get overBudgetItemCount {
    if (items == null) return 0;
    return items!.where((item) => item.isOverBudget).length;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Category(id: $id, name: $name, items: ${items?.length ?? 0})';
}
