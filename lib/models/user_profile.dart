import 'package:flutter/foundation.dart';

@immutable
class UserProfile {
  final String id;
  final String userId;
  final String? displayName;
  final String currency;
  final String locale;
  final bool onboardingCompleted;
  final bool notificationsEnabled;
  final bool subscriptionRemindersEnabled;
  final bool budgetAlertsEnabled;
  final bool monthlyRemindersEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.userId,
    this.displayName,
    this.currency = 'GBP',
    this.locale = 'en_GB',
    this.onboardingCompleted = false,
    this.notificationsEnabled = true,
    this.subscriptionRemindersEnabled = true,
    this.budgetAlertsEnabled = true,
    this.monthlyRemindersEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String?,
      currency: json['currency'] as String? ?? 'GBP',
      locale: json['locale'] as String? ?? 'en_GB',
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      subscriptionRemindersEnabled:
          json['subscription_reminders_enabled'] as bool? ?? true,
      budgetAlertsEnabled: json['budget_alerts_enabled'] as bool? ?? true,
      monthlyRemindersEnabled:
          json['monthly_reminders_enabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'display_name': displayName,
      'currency': currency,
      'locale': locale,
      'onboarding_completed': onboardingCompleted,
      'notifications_enabled': notificationsEnabled,
      'subscription_reminders_enabled': subscriptionRemindersEnabled,
      'budget_alerts_enabled': budgetAlertsEnabled,
      'monthly_reminders_enabled': monthlyRemindersEnabled,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? userId,
    String? displayName,
    String? currency,
    String? locale,
    bool? onboardingCompleted,
    bool? notificationsEnabled,
    bool? subscriptionRemindersEnabled,
    bool? budgetAlertsEnabled,
    bool? monthlyRemindersEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      currency: currency ?? this.currency,
      locale: locale ?? this.locale,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      subscriptionRemindersEnabled:
          subscriptionRemindersEnabled ?? this.subscriptionRemindersEnabled,
      budgetAlertsEnabled: budgetAlertsEnabled ?? this.budgetAlertsEnabled,
      monthlyRemindersEnabled:
          monthlyRemindersEnabled ?? this.monthlyRemindersEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'UserProfile(id: $id, displayName: $displayName)';
}
