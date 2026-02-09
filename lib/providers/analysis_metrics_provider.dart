import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/account.dart';
import '../models/month.dart';
import '../models/transaction.dart';
import 'account_provider.dart';
import 'analysis_provider.dart';
import 'month_provider.dart';
import 'transaction_provider.dart';

class AccountMovementSummary {
  final String accountId;
  final String accountName;
  final double income;
  final double expense;
  final int transactionCount;
  final bool isUnassigned;

  const AccountMovementSummary({
    required this.accountId,
    required this.accountName,
    required this.income,
    required this.expense,
    required this.transactionCount,
    this.isUnassigned = false,
  });

  double get net => income - expense;
  double get movement => income + expense;
}

class TrendPoint {
  final String monthId;
  final String monthLabel;
  final int year;
  final double income;
  final double expense;

  const TrendPoint({
    required this.monthId,
    required this.monthLabel,
    required this.year,
    required this.income,
    required this.expense,
  });

  double get net => income - expense;
}

class TrendInsights {
  final String highestSpendingMonthLabel;
  final double averageMonthlyExpense;
  final double monthOverMonthDelta;
  final bool hasMonthOverMonthDelta;

  const TrendInsights({
    required this.highestSpendingMonthLabel,
    required this.averageMonthlyExpense,
    required this.monthOverMonthDelta,
    required this.hasMonthOverMonthDelta,
  });
}

/// Account-level month movement for the Analysis > Accounts mode.
///
/// Rules:
/// - Includes only active accounts by default.
/// - Groups by `transaction.accountId`.
/// - Uses transaction types to compute movement.
/// - Transfers are excluded because they live in `account_transfers`.
final analysisAccountMovementProvider =
    FutureProvider.family<List<AccountMovementSummary>, String>(
        (ref, monthId) async {
  final accounts = await ref.watch(accountsProvider.future);
  final transactions =
      await ref.watch(transactionsForMonthProvider(monthId).future);

  final activeAccounts =
      accounts.where((account) => !account.isArchived).toList();
  final accountById = <String, Account>{
    for (final account in activeAccounts) account.id: account,
  };

  final rows = <String, AccountMovementSummary>{};
  int unassignedCount = 0;
  double unassignedIncome = 0;
  double unassignedExpense = 0;

  for (final tx in transactions) {
    if (tx.type != TransactionType.expense &&
        tx.type != TransactionType.income) {
      continue;
    }

    if (tx.accountId == null || tx.accountId!.isEmpty) {
      unassignedCount += 1;
      if (tx.type == TransactionType.income) {
        unassignedIncome += tx.amount;
      } else {
        unassignedExpense += tx.amount;
      }
      continue;
    }

    final account = accountById[tx.accountId!];
    if (account == null) {
      continue;
    }

    final existing = rows[account.id] ??
        AccountMovementSummary(
          accountId: account.id,
          accountName: account.name,
          income: 0,
          expense: 0,
          transactionCount: 0,
        );

    rows[account.id] = AccountMovementSummary(
      accountId: existing.accountId,
      accountName: existing.accountName,
      income:
          existing.income + (tx.type == TransactionType.income ? tx.amount : 0),
      expense: existing.expense +
          (tx.type == TransactionType.expense ? tx.amount : 0),
      transactionCount: existing.transactionCount + 1,
    );
  }

  final summaries = rows.values.where((row) => row.movement > 0).toList();
  if (unassignedCount > 0) {
    summaries.add(
      AccountMovementSummary(
        accountId: '__unassigned__',
        accountName: 'Unassigned',
        income: unassignedIncome,
        expense: unassignedExpense,
        transactionCount: unassignedCount,
        isUnassigned: true,
      ),
    );
  }

  summaries.sort((a, b) => b.movement.compareTo(a.movement));
  return summaries;
});

/// Month list used by the Analysis > Trends chart based on selected range.
final analysisTrendMonthsProvider = FutureProvider<List<Month>>((ref) async {
  final allMonths = await ref.watch(userMonthsProvider.future);
  if (allMonths.isEmpty) return [];

  final sortedMonths = [...allMonths]
    ..sort((a, b) => a.startDate.compareTo(b.startDate));
  final selectedMonthId = ref.watch(analysisSelectedMonthIdProvider);
  final selectedYear = ref.watch(analysisSelectedYearProvider);
  final range = ref.watch(analysisTrendRangeProvider);

  if (range == AnalysisTrendRange.year) {
    final selectedMonth = selectedMonthId == null
        ? null
        : sortedMonths
            .where((month) => month.id == selectedMonthId)
            .firstOrNull;
    final year = selectedYear ??
        selectedMonth?.startDate.year ??
        sortedMonths.last.startDate.year;
    final yearMonths = sortedMonths
        .where((month) => month.startDate.year == year)
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    return yearMonths;
  }

  final selectedMonth = selectedMonthId == null
      ? null
      : sortedMonths.where((month) => month.id == selectedMonthId).firstOrNull;

  final anchorMonth = selectedMonth ??
      sortedMonths
          .where((month) => month.startDate.year == selectedYear)
          .lastOrNull ??
      sortedMonths.last;

  final upToAnchor = sortedMonths
      .where((month) => !month.startDate.isAfter(anchorMonth.startDate))
      .toList()
    ..sort((a, b) => a.startDate.compareTo(b.startDate));
  if (upToAnchor.isEmpty) return [];

  final windowSize = range.windowSize ?? upToAnchor.length;
  final startIndex = math.max(0, upToAnchor.length - windowSize);
  return upToAnchor.sublist(startIndex);
});

/// Trend points for Analysis > Trends.
///
/// Aggregates monthly income and expense, then derives net as income - expense.
final analysisTrendSeriesProvider =
    FutureProvider<List<TrendPoint>>((ref) async {
  final trendMonths = await ref.watch(analysisTrendMonthsProvider.future);
  if (trendMonths.isEmpty) return [];

  final monthTransactions = await Future.wait(
    trendMonths
        .map(
            (month) => ref.watch(transactionsForMonthProvider(month.id).future))
        .toList(),
  );

  final points = <TrendPoint>[];
  for (int i = 0; i < trendMonths.length; i++) {
    final month = trendMonths[i];
    final transactions = monthTransactions[i];

    var income = 0.0;
    var expense = 0.0;
    for (final tx in transactions) {
      if (tx.type == TransactionType.income) {
        income += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        expense += tx.amount;
      }
    }

    points.add(
      TrendPoint(
        monthId: month.id,
        monthLabel:
            month.name.length >= 3 ? month.name.substring(0, 3) : month.name,
        year: month.startDate.year,
        income: income,
        expense: expense,
      ),
    );
  }

  return points;
});

final analysisTrendInsightsProvider = Provider<TrendInsights?>((ref) {
  final points = ref.watch(analysisTrendSeriesProvider).valueOrNull;
  final metric = ref.watch(analysisTrendMetricProvider);
  if (points == null || points.isEmpty) return null;

  final highestSpending = points.reduce(
    (a, b) => a.expense >= b.expense ? a : b,
  );
  final averageExpense =
      points.fold<double>(0, (sum, point) => sum + point.expense) /
          points.length;

  final hasDelta = points.length >= 2;
  final delta = hasDelta
      ? _metricValue(points.last, metric) -
          _metricValue(points[points.length - 2], metric)
      : 0.0;

  return TrendInsights(
    highestSpendingMonthLabel:
        '${highestSpending.monthLabel} ${highestSpending.year}',
    averageMonthlyExpense: averageExpense,
    monthOverMonthDelta: delta,
    hasMonthOverMonthDelta: hasDelta,
  );
});

double _metricValue(TrendPoint point, AnalysisTrendMetric metric) {
  switch (metric) {
    case AnalysisTrendMetric.expense:
      return point.expense;
    case AnalysisTrendMetric.income:
      return point.income;
    case AnalysisTrendMetric.net:
      return point.net;
  }
}
