import 'package:flutter/foundation.dart';

import 'account.dart';

/// Transaction type enum
enum TransactionType {
  expense,
  income;

  String get value => name;

  static TransactionType fromString(String value) {
    return TransactionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TransactionType.expense,
    );
  }
}

@immutable
class Transaction {
  final String id;
  final String userId;
  final String monthId;
  final String? categoryId;
  final String? itemId;
  final String? subscriptionId;
  final String? incomeSourceId;
  final String? accountId;
  final TransactionType type;
  final double amount;
  final DateTime date;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Populated by joins (not stored in DB)
  final String? categoryName;
  final String? categoryColor;
  final String? itemName;
  final String? subscriptionName;
  final String? incomeSourceName;
  final String? accountName;
  final AccountType? accountType;

  const Transaction({
    required this.id,
    required this.userId,
    required this.monthId,
    this.categoryId,
    this.itemId,
    this.subscriptionId,
    this.incomeSourceId,
    this.accountId,
    required this.type,
    required this.amount,
    required this.date,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.categoryName,
    this.categoryColor,
    this.itemName,
    this.subscriptionName,
    this.incomeSourceName,
    this.accountName,
    this.accountType,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    // Handle nested category data from joins
    String? categoryName;
    String? categoryColor;
    if (json['categories'] != null) {
      categoryName = json['categories']['name'] as String?;
      categoryColor = json['categories']['color'] as String?;
    }

    // Handle nested item data
    String? itemName;
    if (json['items'] != null) {
      itemName = json['items']['name'] as String?;
    }

    // Handle nested income source data
    String? incomeSourceName;
    if (json['income_sources'] != null) {
      incomeSourceName = json['income_sources']['name'] as String?;
    }

    // Handle nested subscription data
    String? subscriptionName;
    if (json['subscriptions'] != null) {
      subscriptionName = json['subscriptions']['name'] as String?;
    }

    // Handle nested account data
    String? accountName;
    AccountType? accountType;
    if (json['accounts'] != null) {
      accountName = json['accounts']['name'] as String?;
      final accountTypeValue = json['accounts']['type'] as String?;
      if (accountTypeValue != null) {
        accountType = AccountType.fromString(accountTypeValue);
      }
    }

    return Transaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      monthId: json['month_id'] as String,
      categoryId: json['category_id'] as String?,
      itemId: json['item_id'] as String?,
      subscriptionId: json['subscription_id'] as String?,
      incomeSourceId: json['income_source_id'] as String?,
      accountId: json['account_id'] as String?,
      type: TransactionType.fromString(json['type'] as String),
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      categoryName: categoryName ?? json['category_name'] as String?,
      categoryColor: categoryColor ?? json['category_color'] as String?,
      itemName: itemName ?? json['item_name'] as String?,
      subscriptionName:
          subscriptionName ?? json['subscription_name'] as String?,
      incomeSourceName:
          incomeSourceName ?? json['income_source_name'] as String?,
      accountName: accountName ?? json['account_name'] as String?,
      accountType: accountType ??
          (json['account_type'] != null
              ? AccountType.fromString(json['account_type'] as String)
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'month_id': monthId,
      'category_id': categoryId,
      'item_id': itemId,
      'subscription_id': subscriptionId,
      'income_source_id': incomeSourceId,
      'account_id': accountId,
      'type': type.value,
      'amount': amount,
      'date': _formatDate(date),
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Transaction copyWith({
    String? id,
    String? userId,
    String? monthId,
    String? categoryId,
    String? itemId,
    String? subscriptionId,
    String? incomeSourceId,
    String? accountId,
    TransactionType? type,
    double? amount,
    DateTime? date,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? categoryName,
    String? categoryColor,
    String? itemName,
    String? subscriptionName,
    String? incomeSourceName,
    String? accountName,
    AccountType? accountType,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      monthId: monthId ?? this.monthId,
      categoryId: categoryId ?? this.categoryId,
      itemId: itemId ?? this.itemId,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      incomeSourceId: incomeSourceId ?? this.incomeSourceId,
      accountId: accountId ?? this.accountId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryName: categoryName ?? this.categoryName,
      categoryColor: categoryColor ?? this.categoryColor,
      itemName: itemName ?? this.itemName,
      subscriptionName: subscriptionName ?? this.subscriptionName,
      incomeSourceName: incomeSourceName ?? this.incomeSourceName,
      accountName: accountName ?? this.accountName,
      accountType: accountType ?? this.accountType,
    );
  }

  /// Is this an expense?
  bool get isExpense => type == TransactionType.expense;

  /// Is this income?
  bool get isIncome => type == TransactionType.income;

  /// Display name for UI
  String get displayName {
    if (isIncome && incomeSourceName != null) return incomeSourceName!;
    if (itemName != null) return itemName!;
    if (categoryName != null) return categoryName!;
    return isIncome ? 'Income' : 'Expense';
  }

  /// Formatted amount with sign
  String formattedAmount(String currencySymbol) {
    final sign = isIncome ? '+' : '-';
    return '$sign$currencySymbol${amount.toStringAsFixed(2)}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Transaction(id: $id, type: $type, amount: $amount, date: $date)';
}
