import 'dart:math' as math;

import 'package:flutter/services.dart';

import '../../config/constants.dart';

class InputValidator {
  InputValidator._();

  static const int maxCategoryNameLength = 64;
  static const int maxItemNameLength = 64;
  static const int maxIncomeSourceNameLength = 64;
  static const int maxAccountNameLength = 64;
  static const int maxDisplayNameLength = 80;
  static const int maxTransactionNoteLength = 280;
  static const int maxFormNoteLength = 300;

  static const Duration maxFutureTransactionOffset = Duration(days: 31);
  static final DateTime minTransactionDate = DateTime(2000, 1, 1);

  static int decimalPlacesForCurrency(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'JPY':
        return 0;
      default:
        return 2;
    }
  }

  static FilteringTextInputFormatter amountInputFormatter({
    required int decimalPlaces,
    bool allowNegative = false,
  }) {
    final sign = allowNegative ? '-?' : '';
    if (decimalPlaces <= 0) {
      return FilteringTextInputFormatter.allow(RegExp('^$sign\\d*\$'));
    }
    return FilteringTextInputFormatter.allow(
      RegExp('^$sign\\d*\\.?\\d{0,$decimalPlaces}\$'),
    );
  }

  static String? validateBoundedName(
    String? value, {
    required String fieldName,
    required int maxLength,
    int minLength = 1,
  }) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return '$fieldName is required';
    }
    if (normalized.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    if (normalized.length > maxLength) {
      return '$fieldName must be at most $maxLength characters';
    }
    return null;
  }

  static String? validateNoteLength(
    String? value, {
    required String fieldName,
    required int maxLength,
  }) {
    final normalized = value?.trim() ?? '';
    if (normalized.length > maxLength) {
      return '$fieldName must be at most $maxLength characters';
    }
    return null;
  }

  static String? validateNonNegativeAmountValue(
    double amount, {
    double maxAmount = AppConstants.maxTransactionAmount,
  }) {
    if (amount < 0) {
      return 'Amount must be zero or greater';
    }
    if (amount > maxAmount) {
      return 'Amount cannot exceed ${maxAmount.toStringAsFixed(2)}';
    }
    return null;
  }

  static String? validatePositiveAmountValue(
    double amount, {
    required String currencyCode,
    double maxAmount = AppConstants.maxTransactionAmount,
  }) {
    if (amount <= 0) {
      return 'Enter an amount greater than zero';
    }
    if (amount > maxAmount) {
      final decimals = decimalPlacesForCurrency(currencyCode);
      return 'Amount cannot exceed ${maxAmount.toStringAsFixed(decimals)}';
    }

    final decimals = decimalPlacesForCurrency(currencyCode);
    if (!hasAllowedPrecision(amount, decimalPlaces: decimals)) {
      if (decimals == 0) {
        return 'This currency requires whole numbers only';
      }
      return 'Amount can include up to $decimals decimal places';
    }
    return null;
  }

  static String? validateNonNegativeAmountInput(
    String? value, {
    required String currencyCode,
    required String fieldName,
    bool required = true,
    double maxAmount = AppConstants.maxTransactionAmount,
  }) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return required ? '$fieldName is required' : null;
    }

    final amount = double.tryParse(normalized);
    if (amount == null) {
      return 'Please enter a valid amount';
    }

    final rangeError = validateNonNegativeAmountValue(
      amount,
      maxAmount: maxAmount,
    );
    if (rangeError != null) return rangeError;

    final decimals = decimalPlacesForCurrency(currencyCode);
    if (!hasAllowedPrecision(amount, decimalPlaces: decimals)) {
      if (decimals == 0) {
        return 'This currency requires whole numbers only';
      }
      return 'Amount can include up to $decimals decimal places';
    }

    return null;
  }

  static String? validateTransactionDate(
    DateTime value, {
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final normalizedValue = DateTime(value.year, value.month, value.day);
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final maxDate = normalizedToday.add(maxFutureTransactionOffset);

    if (normalizedValue.isBefore(minTransactionDate)) {
      return 'Date must be on or after Jan 1, 2000';
    }
    if (normalizedValue.isAfter(maxDate)) {
      return 'Date cannot be more than 31 days in the future';
    }
    return null;
  }

  static bool hasAllowedPrecision(
    double amount, {
    required int decimalPlaces,
  }) {
    final factor = math.pow(10, decimalPlaces).toDouble();
    final scaled = amount * factor;
    return (scaled - scaled.roundToDouble()).abs() < 0.0000001;
  }

  static double normalizeAmount(
    double amount, {
    required int decimalPlaces,
  }) {
    return double.parse(amount.toStringAsFixed(decimalPlaces));
  }
}
