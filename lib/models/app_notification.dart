import 'package:flutter/foundation.dart';

enum NotificationType {
  subscriptionReminder,
  budgetAlert,
  monthlyReminder,
}

@immutable
class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final String? subscriptionId;
  final String? categoryId;
  final String? monthId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> payload;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.subscriptionId,
    this.categoryId,
    this.monthId,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    this.updatedAt,
    this.payload = const <String, dynamic>{},
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final rawPayload = json['payload'];
    final payload = rawPayload is Map
        ? rawPayload.map((key, value) => MapEntry(key.toString(), value))
        : const <String, dynamic>{};

    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: notificationTypeFromString(json['type'] as String?),
      subscriptionId: json['subscription_id'] as String?,
      categoryId: json['category_id'] as String?,
      monthId: json['month_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      payload: payload,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': notificationTypeToString(type),
      'subscription_id': subscriptionId,
      'category_id': categoryId,
      'month_id': monthId,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'payload': payload,
    };
  }
}

String notificationTypeToString(NotificationType type) {
  switch (type) {
    case NotificationType.subscriptionReminder:
      return 'subscription_reminder';
    case NotificationType.budgetAlert:
      return 'budget_alert';
    case NotificationType.monthlyReminder:
      return 'monthly_reminder';
  }
}

NotificationType notificationTypeFromString(String? value) {
  switch (value) {
    case 'subscription_reminder':
      return NotificationType.subscriptionReminder;
    case 'budget_alert':
      return NotificationType.budgetAlert;
    case 'monthly_reminder':
      return NotificationType.monthlyReminder;
    default:
      return NotificationType.subscriptionReminder;
  }
}
