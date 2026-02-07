import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../models/month.dart';
import '../models/transaction.dart';
import '../services/category_service.dart';
import '../services/transaction_service.dart';
import 'category_provider.dart';
import 'month_provider.dart';
import 'transaction_provider.dart';

// ─────────────────────────────────────────────
// DATA CLASSES
// ─────────────────────────────────────────────

/// Aggregated category data across all months in a year.
/// Groups by category name (not ID, since each month has its own category IDs).
class YearlyCategorySummary {
  final String name;
  final String icon;
  final Color color;
  final double totalActual;
  final int transactionCount;

  const YearlyCategorySummary({
    required this.name,
    required this.icon,
    required this.color,
    required this.totalActual,
    required this.transactionCount,
  });
}

/// Data for one bar in the yearly expense bar chart.
class MonthlyBarData {
  final String monthId;
  final String monthName;
  final double totalExpenses;

  const MonthlyBarData({
    required this.monthId,
    required this.monthName,
    required this.totalExpenses,
  });
}

// ─────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────

/// The selected year (derived from active month's start date).
final selectedYearProvider = Provider<int>((ref) {
  final activeMonth = ref.watch(activeMonthProvider).value;
  return activeMonth?.startDate.year ?? DateTime.now().year;
});

/// All months belonging to the same year as the active month.
/// Sorted chronologically (January first).
final yearMonthsProvider = FutureProvider<List<Month>>((ref) async {
  final activeMonth = await ref.watch(activeMonthProvider.future);
  if (activeMonth == null) return [];

  final year = activeMonth.startDate.year;
  final allMonths = await ref.watch(userMonthsProvider.future);

  final yearMonths = allMonths
      .where((m) => m.startDate.year == year)
      .toList()
    ..sort((a, b) => a.startDate.compareTo(b.startDate));

  return yearMonths;
});

/// Monthly expense totals for the bar chart.
/// Returns one MonthlyBarData per month that exists in the year.
/// Uses a single DB query for all transactions via getTransactionsForMonths().
final yearlyMonthlyExpensesProvider =
    FutureProvider<List<MonthlyBarData>>((ref) async {
  final yearMonths = await ref.watch(yearMonthsProvider.future);
  if (yearMonths.isEmpty) return [];

  final transactionService = ref.read(transactionServiceProvider);
  final monthIds = yearMonths.map((m) => m.id).toList();

  // Single query: get ALL transactions for all months in the year
  final allTransactions =
      await transactionService.getTransactionsForMonths(monthIds);

  // Group expense transactions by monthId and sum amounts
  final expensesByMonth = <String, double>{};
  for (final tx in allTransactions) {
    if (tx.type == TransactionType.expense) {
      expensesByMonth[tx.monthId] =
          (expensesByMonth[tx.monthId] ?? 0) + tx.amount;
    }
  }

  return yearMonths.map((month) {
    return MonthlyBarData(
      monthId: month.id,
      monthName: month.name,
      totalExpenses: expensesByMonth[month.id] ?? 0,
    );
  }).toList();
});

/// Total expenses for the entire year (sum of all monthly totals).
final totalYearlyExpensesProvider = Provider<double>((ref) {
  final monthlyData = ref.watch(yearlyMonthlyExpensesProvider).value ?? [];
  return monthlyData.fold<double>(0, (sum, d) => sum + d.totalExpenses);
});

/// Aggregated categories for the year, grouped by category name.
///
/// IMPORTANT: Follows the CALCULATED ACTUALS pattern (CLAUDE.md Section 3).
/// - Fetches all categories for all months in the year
/// - Fetches all transactions for all months in the year
/// - Calculates actual amounts from transactions (NOT from stored values)
/// - Groups categories by name (not ID) since each month has its own category IDs
/// - Sorted by highest spending first
final yearlyCategorySummariesProvider =
    FutureProvider<List<YearlyCategorySummary>>((ref) async {
  final yearMonths = await ref.watch(yearMonthsProvider.future);
  if (yearMonths.isEmpty) return [];

  final categoryService = ref.read(categoryServiceProvider);
  final transactionService = ref.read(transactionServiceProvider);
  final monthIds = yearMonths.map((m) => m.id).toList();

  // 2 DB queries total: all categories + all transactions for the year
  final allCategories =
      await categoryService.getCategoriesForMonths(monthIds);
  final allTransactions =
      await transactionService.getTransactionsForMonths(monthIds);

  // ── Calculate actuals for each item (same pattern as categoriesProvider) ──
  final categoriesWithActuals = allCategories.map((category) {
    final updatedItems = category.items?.map((item) {
      final itemTransactions = allTransactions.where(
        (tx) => tx.itemId == item.id && tx.type == TransactionType.expense,
      );
      final actual =
          itemTransactions.fold<double>(0.0, (sum, tx) => sum + tx.amount);
      return item.copyWith(actual: actual);
    }).toList();
    return category.copyWith(items: updatedItems);
  }).toList();

  // ── Count transactions per category ID ──
  final txCountByCategory = <String, int>{};
  for (final tx in allTransactions) {
    if (tx.categoryId != null && tx.type == TransactionType.expense) {
      txCountByCategory[tx.categoryId!] =
          (txCountByCategory[tx.categoryId!] ?? 0) + 1;
    }
  }

  // ── Group categories by name across all months ──
  final grouped = <String, _CategoryAccumulator>{};
  for (final cat in categoriesWithActuals) {
    final key = cat.name;
    if (!grouped.containsKey(key)) {
      // Use first occurrence's icon and color
      grouped[key] = _CategoryAccumulator(
        name: cat.name,
        icon: cat.icon,
        color: cat.colorValue,
      );
    }
    // Add this category's actual to the group total
    grouped[key]!.totalActual += cat.totalActual;
    // Add transaction count (only count each category ID once)
    if (!grouped[key]!.countedCategoryIds.contains(cat.id)) {
      grouped[key]!.transactionCount += txCountByCategory[cat.id] ?? 0;
      grouped[key]!.countedCategoryIds.add(cat.id);
    }
  }

  // ── Convert to sorted list (highest spending first) ──
  final summaries = grouped.values
      .map((acc) => YearlyCategorySummary(
            name: acc.name,
            icon: acc.icon,
            color: acc.color,
            totalActual: acc.totalActual,
            transactionCount: acc.transactionCount,
          ))
      .toList()
    ..sort((a, b) => b.totalActual.compareTo(a.totalActual));

  return summaries;
});

// ─────────────────────────────────────────────
// HELPER (private to this file)
// ─────────────────────────────────────────────

/// Accumulates category data across months for grouping by name.
class _CategoryAccumulator {
  final String name;
  final String icon;
  final Color color;
  double totalActual = 0;
  int transactionCount = 0;
  final Set<String> countedCategoryIds = {};

  _CategoryAccumulator({
    required this.name,
    required this.icon,
    required this.color,
  });
}

