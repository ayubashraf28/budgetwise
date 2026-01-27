import 'package:flutter/foundation.dart';

@immutable
class IncomeSource {
  final String id;
  final String userId;
  final String monthId;
  final String name;
  final double projected;
  final double actual;
  final bool isRecurring;
  final int sortOrder;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const IncomeSource({
    required this.id,
    required this.userId,
    required this.monthId,
    required this.name,
    this.projected = 0,
    this.actual = 0,
    this.isRecurring = false,
    this.sortOrder = 0,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory IncomeSource.fromJson(Map<String, dynamic> json) {
    return IncomeSource(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      monthId: json['month_id'] as String,
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
      'user_id': userId,
      'month_id': monthId,
      'name': name,
      'projected': projected,
      'actual': actual,
      'is_recurring': isRecurring,
      'sort_order': sortOrder,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  IncomeSource copyWith({
    String? id,
    String? userId,
    String? monthId,
    String? name,
    double? projected,
    double? actual,
    bool? isRecurring,
    int? sortOrder,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IncomeSource(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      monthId: monthId ?? this.monthId,
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

  /// Difference between projected and actual
  /// Positive = received less than expected
  /// Negative = received more than expected
  double get difference => projected - actual;

  /// Whether actual income exceeds projected
  bool get exceededProjection => actual > projected;

  /// Whether actual income meets or exceeds projected
  bool get metProjection => actual >= projected;

  /// Progress percentage (can exceed 100%)
  double get progressPercentage {
    if (projected <= 0) return actual > 0 ? 100 : 0;
    return (actual / projected) * 100;
  }

  /// Status indicator
  String get status {
    if (actual >= projected) return 'received';
    if (actual > 0) return 'partial';
    return 'pending';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IncomeSource && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'IncomeSource(id: $id, name: $name, projected: $projected, actual: $actual)';
}
