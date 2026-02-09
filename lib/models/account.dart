import 'package:flutter/foundation.dart';

enum AccountType {
  cash,
  debit,
  credit,
  savings,
  other;

  String get value => name;

  static AccountType fromString(String? value) {
    return AccountType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AccountType.cash,
    );
  }
}

@immutable
class Account {
  final String id;
  final String userId;
  final String name;
  final AccountType type;
  final String currency;
  final double openingBalance;
  final double? creditLimit;
  final bool includeInNetWorth;
  final bool isArchived;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Account({
    required this.id,
    required this.userId,
    required this.name,
    this.type = AccountType.cash,
    this.currency = 'GBP',
    this.openingBalance = 0,
    this.creditLimit,
    this.includeInNetWorth = true,
    this.isArchived = false,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      type: AccountType.fromString(json['type'] as String?),
      currency: json['currency'] as String? ?? 'GBP',
      openingBalance: (json['opening_balance'] as num?)?.toDouble() ?? 0,
      creditLimit: (json['credit_limit'] as num?)?.toDouble(),
      includeInNetWorth: json['include_in_net_worth'] as bool? ?? true,
      isArchived: json['is_archived'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'type': type.value,
      'currency': currency,
      'opening_balance': openingBalance,
      'credit_limit': creditLimit,
      'include_in_net_worth': includeInNetWorth,
      'is_archived': isArchived,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Account copyWith({
    String? id,
    String? userId,
    String? name,
    AccountType? type,
    String? currency,
    double? openingBalance,
    double? creditLimit,
    bool? clearCreditLimit,
    bool? includeInNetWorth,
    bool? isArchived,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Account(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      openingBalance: openingBalance ?? this.openingBalance,
      creditLimit:
          (clearCreditLimit ?? false) ? null : creditLimit ?? this.creditLimit,
      includeInNetWorth: includeInNetWorth ?? this.includeInNetWorth,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isCredit => type == AccountType.credit;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Account && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
