import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/monthly_summary.dart';
import 'month_provider.dart';
import 'income_provider.dart';
import 'category_provider.dart';

/// Monthly summary combining all financial data
final monthlySummaryProvider = Provider<MonthlySummary?>((ref) {
  final month = ref.watch(activeMonthProvider).value;
  if (month == null) return null;

  final projectedIncome = ref.watch(totalProjectedIncomeProvider);
  final actualIncome = ref.watch(totalActualIncomeProvider);
  final projectedExpenses = ref.watch(totalProjectedExpensesProvider);
  final actualExpenses = ref.watch(totalActualExpensesProvider);

  return MonthlySummary(
    monthId: month.id,
    monthName: month.name,
    projectedIncome: projectedIncome,
    actualIncome: actualIncome,
    projectedExpenses: projectedExpenses,
    actualExpenses: actualExpenses,
    projectedBalance: projectedIncome - projectedExpenses,
    actualBalance: actualIncome - actualExpenses,
    totalDays: month.totalDays,
    daysElapsed: month.daysElapsed(),
    daysRemaining: month.daysRemaining(),
  );
});

/// Projected balance (income - expenses)
final projectedBalanceProvider = Provider<double>((ref) {
  return ref.watch(monthlySummaryProvider)?.projectedBalance ?? 0;
});

/// Actual balance (income - expenses)
final actualBalanceProvider = Provider<double>((ref) {
  return ref.watch(monthlySummaryProvider)?.actualBalance ?? 0;
});

/// Difference between actual and projected balance
/// Positive = ahead of plan, Negative = behind plan
final balanceDifferenceProvider = Provider<double>((ref) {
  return ref.watch(monthlySummaryProvider)?.balanceDifference ?? 0;
});

/// Is the user ahead of their projected balance?
final isAheadOfPlanProvider = Provider<bool>((ref) {
  return ref.watch(monthlySummaryProvider)?.balanceImproved ?? true;
});

/// Are there any categories over budget?
final hasOverspendingProvider = Provider<bool>((ref) {
  return ref.watch(overBudgetCategoriesProvider).isNotEmpty;
});

/// Number of categories over budget
final overBudgetCountProvider = Provider<int>((ref) {
  return ref.watch(overBudgetCategoriesProvider).length;
});

/// Health indicator: 'excellent', 'good', 'warning', 'critical'
final budgetHealthProvider = Provider<String>((ref) {
  final summary = ref.watch(monthlySummaryProvider);
  if (summary == null) return 'good';

  final isAhead = summary.balanceImproved;
  final isUnder = summary.expensesUnderBudget;

  if (isAhead && isUnder) return 'excellent';
  if (isAhead || isUnder) return 'good';
  if (summary.balanceDifference > -100) return 'warning';
  return 'critical';
});

/// Income progress percentage (0-100+)
final incomeProgressProvider = Provider<double>((ref) {
  return ref.watch(monthlySummaryProvider)?.incomeProgress ?? 0;
});

/// Expense progress percentage (0-100+)
final expenseProgressProvider = Provider<double>((ref) {
  return ref.watch(monthlySummaryProvider)?.expenseProgress ?? 0;
});

/// Daily spending pace calculation
final dailySpendingPaceProvider = Provider<Map<String, double>>((ref) {
  final summary = ref.watch(monthlySummaryProvider);

  if (summary == null) {
    return {
      'dailyBudget': 0,
      'dailyActual': 0,
      'dailyBudgetRemaining': 0,
      'expectedSpent': 0,
      'pace': 0,
      'daysElapsed': 0,
      'daysRemaining': 0,
    };
  }

  // What we should have spent by now
  final expectedSpent = summary.dailyBudget * summary.daysElapsed;

  // Pace: <1 = under budget, >1 = over budget
  final pace = expectedSpent > 0 ? summary.actualExpenses / expectedSpent : 0.0;

  return {
    'dailyBudget': summary.dailyBudget,
    'dailyActual': summary.dailySpendingPace,
    'dailyBudgetRemaining': summary.remainingDailyBudget,
    'expectedSpent': expectedSpent.toDouble(),
    'pace': pace.toDouble(),
    'daysElapsed': summary.daysElapsed.toDouble(),
    'daysRemaining': summary.daysRemaining.toDouble(),
  };
});

/// Spending pace status: 'on_track', 'ahead', 'behind', 'over_budget'
final spendingPaceStatusProvider = Provider<String>((ref) {
  final pace = ref.watch(dailySpendingPaceProvider);
  final paceValue = pace['pace'] ?? 0;
  final isUnderBudget = ref.watch(isUnderBudgetProvider);

  if (!isUnderBudget) return 'over_budget';
  if (paceValue < 0.9) return 'ahead';
  if (paceValue <= 1.1) return 'on_track';
  return 'behind';
});

/// Savings amount (remaining after all projected expenses)
final projectedSavingsProvider = Provider<double>((ref) {
  final summary = ref.watch(monthlySummaryProvider);
  if (summary == null) return 0;
  return summary.projectedBalance;
});

/// Actual savings so far
final actualSavingsProvider = Provider<double>((ref) {
  final summary = ref.watch(monthlySummaryProvider);
  if (summary == null) return 0;
  return summary.actualBalance;
});
