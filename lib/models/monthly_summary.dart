import 'package:flutter/foundation.dart';

/// Summary of a month's budget data
@immutable
class MonthlySummary {
  final String monthId;
  final String monthName;

  // Income
  final double projectedIncome;
  final double actualIncome;

  // Expenses
  final double projectedExpenses;
  final double actualExpenses;

  // Balance
  final double projectedBalance;
  final double actualBalance;

  // Progress
  final int totalDays;
  final int daysElapsed;
  final int daysRemaining;

  const MonthlySummary({
    required this.monthId,
    required this.monthName,
    required this.projectedIncome,
    required this.actualIncome,
    required this.projectedExpenses,
    required this.actualExpenses,
    required this.projectedBalance,
    required this.actualBalance,
    required this.totalDays,
    required this.daysElapsed,
    required this.daysRemaining,
  });

  /// Create an empty summary
  factory MonthlySummary.empty(String monthId, String monthName) {
    return MonthlySummary(
      monthId: monthId,
      monthName: monthName,
      projectedIncome: 0,
      actualIncome: 0,
      projectedExpenses: 0,
      actualExpenses: 0,
      projectedBalance: 0,
      actualBalance: 0,
      totalDays: 30,
      daysElapsed: 0,
      daysRemaining: 30,
    );
  }

  /// Income difference (positive = received more than expected)
  double get incomeDifference => actualIncome - projectedIncome;

  /// Expense difference (positive = spent less than expected)
  double get expenseDifference => projectedExpenses - actualExpenses;

  /// Balance difference (positive = better than expected)
  double get balanceDifference => actualBalance - projectedBalance;

  /// Whether actual income exceeds projected
  bool get incomeExceeded => actualIncome > projectedIncome;

  /// Whether actual expenses are under budget
  bool get expensesUnderBudget => actualExpenses < projectedExpenses;

  /// Whether actual balance is better than projected
  bool get balanceImproved => actualBalance > projectedBalance;

  /// Income progress percentage
  double get incomeProgress {
    if (projectedIncome <= 0) return actualIncome > 0 ? 100 : 0;
    return (actualIncome / projectedIncome) * 100;
  }

  /// Expense progress percentage
  double get expenseProgress {
    if (projectedExpenses <= 0) return actualExpenses > 0 ? 100 : 0;
    return (actualExpenses / projectedExpenses) * 100;
  }

  /// Month progress percentage (0-100)
  double get monthProgress {
    if (totalDays <= 0) return 0;
    return (daysElapsed / totalDays) * 100;
  }

  /// Daily budget (projected expenses / total days)
  double get dailyBudget {
    if (totalDays <= 0) return 0;
    return projectedExpenses / totalDays;
  }

  /// Daily spending pace (actual expenses / days elapsed)
  double get dailySpendingPace {
    if (daysElapsed <= 0) return 0;
    return actualExpenses / daysElapsed;
  }

  /// Whether spending pace is on track
  bool get isSpendingOnTrack => dailySpendingPace <= dailyBudget;

  /// Projected remaining budget based on current pace
  double get projectedMonthEndBalance {
    final projectedTotalExpenses = dailySpendingPace * totalDays;
    return actualIncome - projectedTotalExpenses;
  }

  /// Amount available to spend per remaining day to stay on budget
  double get remainingDailyBudget {
    if (daysRemaining <= 0) return 0;
    final remainingBudget = projectedExpenses - actualExpenses;
    return remainingBudget / daysRemaining;
  }

  MonthlySummary copyWith({
    String? monthId,
    String? monthName,
    double? projectedIncome,
    double? actualIncome,
    double? projectedExpenses,
    double? actualExpenses,
    double? projectedBalance,
    double? actualBalance,
    int? totalDays,
    int? daysElapsed,
    int? daysRemaining,
  }) {
    return MonthlySummary(
      monthId: monthId ?? this.monthId,
      monthName: monthName ?? this.monthName,
      projectedIncome: projectedIncome ?? this.projectedIncome,
      actualIncome: actualIncome ?? this.actualIncome,
      projectedExpenses: projectedExpenses ?? this.projectedExpenses,
      actualExpenses: actualExpenses ?? this.actualExpenses,
      projectedBalance: projectedBalance ?? this.projectedBalance,
      actualBalance: actualBalance ?? this.actualBalance,
      totalDays: totalDays ?? this.totalDays,
      daysElapsed: daysElapsed ?? this.daysElapsed,
      daysRemaining: daysRemaining ?? this.daysRemaining,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MonthlySummary && other.monthId == monthId;
  }

  @override
  int get hashCode => monthId.hashCode;

  @override
  String toString() =>
      'MonthlySummary(monthId: $monthId, actualBalance: $actualBalance)';
}
