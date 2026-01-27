import 'package:flutter/foundation.dart';

@immutable
class Month {
  final String id;
  final String userId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Month({
    required this.id,
    required this.userId,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Month.fromJson(Map<String, dynamic> json) {
    return Month(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      isActive: json['is_active'] as bool? ?? true,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'start_date': _formatDate(startDate),
      'end_date': _formatDate(endDate),
      'is_active': isActive,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Format date as YYYY-MM-DD for PostgreSQL
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Month copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Month(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if a date falls within this month
  bool containsDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return !dateOnly.isBefore(startDate) && !dateOnly.isAfter(endDate);
  }

  /// Get the total number of days in this month
  int get totalDays => endDate.difference(startDate).inDays + 1;

  /// Get the number of days elapsed (relative to a given date)
  int daysElapsed([DateTime? currentDate]) {
    final now = currentDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (today.isBefore(startDate)) return 0;
    if (today.isAfter(endDate)) return totalDays;
    return today.difference(startDate).inDays + 1;
  }

  /// Get progress through the month (0.0 to 1.0)
  double progress([DateTime? currentDate]) {
    return daysElapsed(currentDate) / totalDays;
  }

  /// Get days remaining in the month
  int daysRemaining([DateTime? currentDate]) {
    return totalDays - daysElapsed(currentDate);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Month && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Month(id: $id, name: $name, isActive: $isActive)';
}
