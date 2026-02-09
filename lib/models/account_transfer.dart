import 'package:flutter/foundation.dart';

import 'account.dart';

@immutable
class AccountTransfer {
  final String id;
  final String userId;
  final String fromAccountId;
  final String toAccountId;
  final double amount;
  final DateTime date;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Populated by joins (not stored in DB)
  final String? fromAccountName;
  final String? toAccountName;
  final AccountType? fromAccountType;
  final AccountType? toAccountType;

  const AccountTransfer({
    required this.id,
    required this.userId,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    required this.date,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.fromAccountName,
    this.toAccountName,
    this.fromAccountType,
    this.toAccountType,
  });

  factory AccountTransfer.fromJson(Map<String, dynamic> json) {
    String? fromAccountName;
    AccountType? fromAccountType;
    if (json['from_account'] != null) {
      fromAccountName = json['from_account']['name'] as String?;
      fromAccountType =
          AccountType.fromString(json['from_account']['type'] as String?);
    }

    String? toAccountName;
    AccountType? toAccountType;
    if (json['to_account'] != null) {
      toAccountName = json['to_account']['name'] as String?;
      toAccountType =
          AccountType.fromString(json['to_account']['type'] as String?);
    }

    return AccountTransfer(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fromAccountId: json['from_account_id'] as String,
      toAccountId: json['to_account_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      fromAccountName: fromAccountName ?? json['from_account_name'] as String?,
      toAccountName: toAccountName ?? json['to_account_name'] as String?,
      fromAccountType: fromAccountType ??
          (json['from_account_type'] != null
              ? AccountType.fromString(json['from_account_type'] as String)
              : null),
      toAccountType: toAccountType ??
          (json['to_account_type'] != null
              ? AccountType.fromString(json['to_account_type'] as String)
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'from_account_id': fromAccountId,
      'to_account_id': toAccountId,
      'amount': amount,
      'date': _formatDate(date),
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  AccountTransfer copyWith({
    String? id,
    String? userId,
    String? fromAccountId,
    String? toAccountId,
    double? amount,
    DateTime? date,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fromAccountName,
    String? toAccountName,
    AccountType? fromAccountType,
    AccountType? toAccountType,
  }) {
    return AccountTransfer(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fromAccountName: fromAccountName ?? this.fromAccountName,
      toAccountName: toAccountName ?? this.toAccountName,
      fromAccountType: fromAccountType ?? this.fromAccountType,
      toAccountType: toAccountType ?? this.toAccountType,
    );
  }

  String _formatDate(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccountTransfer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
