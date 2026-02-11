import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../models/item.dart';
import '../models/month.dart';
import '../models/transaction.dart';
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
  final List<String> categoryIds;

  const YearlyCategorySummary({
    required this.name,
    required this.icon,
    required this.color,
    required this.totalActual,
    required this.transactionCount,
    required this.categoryIds,
  });
}

/// A single category segment within a monthly bar.
class CategoryBarSegment {
  final String categoryName;
  final Color color;
  final double amount;

  const CategoryBarSegment({
    required this.categoryName,
    required this.color,
    required this.amount,
  });
}

/// Data for one bar in the yearly expense bar chart (stacked by category).
class MonthlyBarData {
  final String monthId;
  final String monthName;
  final double totalExpenses;
  final List<CategoryBarSegment> segments;

  const MonthlyBarData({
    required this.monthId,
    required this.monthName,
    required this.totalExpenses,
    required this.segments,
  });
}

// ─────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────

/// Budget screen's explicitly selected year (year view only).
/// null = not yet set (will fall back to the month-derived year).
final budgetSelectedYearProvider = StateProvider<int?>((ref) => null);

/// The selected year — prefers the explicit year selection, then falls back
/// to the budget screen's selected month, then the global active month.
final selectedYearProvider = Provider<int>((ref) {
  // 1. Explicit year selection (from year selector in year view)
  final explicitYear = ref.watch(budgetSelectedYearProvider);
  if (explicitYear != null) return explicitYear;

  // 2. Derive from budget screen's selected month
  final budgetMonthId = ref.watch(budgetSelectedMonthIdProvider);
  if (budgetMonthId != null) {
    final months = ref.watch(userMonthsProvider).value ?? [];
    final budgetMonth = months.where((m) => m.id == budgetMonthId).firstOrNull;
    if (budgetMonth != null) return budgetMonth.startDate.year;
  }

  // 3. Fall back to global active month / current year
  final activeMonth = ref.watch(activeMonthProvider).value;
  return activeMonth?.startDate.year ?? DateTime.now().year;
});

/// Set of years that have at least one month with data in the database.
/// Used to determine which years in the year selector should be active vs muted.
final yearsWithDataProvider = Provider<Set<int>>((ref) {
  final months = ref.watch(userMonthsProvider).value ?? [];
  return months.map((m) => m.startDate.year).toSet();
});

/// All months belonging to the same year as the budget-selected month.
/// Sorted chronologically (January first).
final yearMonthsProvider = FutureProvider<List<Month>>((ref) async {
  final allMonths = await ref.watch(userMonthsProvider.future);
  if (allMonths.isEmpty) return [];

  final year = ref.watch(selectedYearProvider);

  final yearMonths = allMonths.where((m) => m.startDate.year == year).toList()
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
  final categoryService = ref.read(categoryServiceProvider);
  final monthIds = yearMonths.map((m) => m.id).toList();

  // Get ALL transactions and categories for the year
  final allTransactions =
      await transactionService.getTransactionsForMonths(monthIds);
  final allCategories = await categoryService.getCategoriesForMonths(monthIds);

  // Build category color map: categoryId -> color
  final categoryColorMap = <String, Color>{};
  final categoryNameMap = <String, String>{};
  for (final cat in allCategories) {
    categoryColorMap[cat.id] = cat.colorValue;
    categoryNameMap[cat.id] = cat.name;
  }

  // Group expense transactions by month + category
  final expensesByMonthCategory = <String, Map<String, double>>{};
  final expensesByMonth = <String, double>{};
  for (final tx in allTransactions) {
    if (tx.type == TransactionType.expense) {
      expensesByMonth[tx.monthId] =
          (expensesByMonth[tx.monthId] ?? 0) + tx.amount;

      if (tx.categoryId != null) {
        expensesByMonthCategory.putIfAbsent(tx.monthId, () => {});
        expensesByMonthCategory[tx.monthId]![tx.categoryId!] =
            (expensesByMonthCategory[tx.monthId]![tx.categoryId!] ?? 0) +
                tx.amount;
      }
    }
  }

  return yearMonths.map((month) {
    // Build segments for this month, sorted by amount (largest first)
    final monthCategoryMap = expensesByMonthCategory[month.id] ?? {};
    final segments = monthCategoryMap.entries.map((entry) {
      return CategoryBarSegment(
        categoryName: categoryNameMap[entry.key] ?? 'Unknown',
        color: categoryColorMap[entry.key] ?? const Color(0xFF6366F1),
        amount: entry.value,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return MonthlyBarData(
      monthId: month.id,
      monthName: month.name,
      totalExpenses: expensesByMonth[month.id] ?? 0,
      segments: segments,
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
  final allCategories = await categoryService.getCategoriesForMonths(monthIds);
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
      grouped[key]!.allCategoryIds.add(cat.id);
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
            categoryIds: acc.allCategoryIds,
          ))
      .toList()
    ..sort((a, b) => b.totalActual.compareTo(a.totalActual));

  return summaries;
});

/// Provider for category detail in year mode.
/// Aggregates a category's data across all months in the year.
final yearlyCategoryDetailProvider = FutureProvider.family<
    ({Category category, List<Transaction> transactions})?,
    String>((ref, categoryId) async {
  final categoryService = ref.read(categoryServiceProvider);
  final transactionService = ref.read(transactionServiceProvider);

  // Get the source category to know its name
  final sourceCategory = await categoryService.getCategoryById(categoryId);
  if (sourceCategory == null) return null;

  // Get all months in the year
  final yearMonths = await ref.watch(yearMonthsProvider.future);
  if (yearMonths.isEmpty) return null;

  final monthIds = yearMonths.map((m) => m.id).toList();

  // Get all categories with this name across all months
  final allCategories = await categoryService.getCategoriesForMonths(monthIds);
  final matchingCategories = allCategories
      .where((c) => c.name.toLowerCase() == sourceCategory.name.toLowerCase())
      .toList();

  if (matchingCategories.isEmpty) return null;

  final matchingCategoryIds = matchingCategories.map((c) => c.id).toSet();

  // Get all transactions for the year
  final allTransactions =
      await transactionService.getTransactionsForMonths(monthIds);

  // Filter to transactions belonging to matching categories
  final categoryTransactions = allTransactions
      .where((tx) =>
          tx.categoryId != null && matchingCategoryIds.contains(tx.categoryId))
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  // Aggregate items by name across all matching categories
  final itemsByName = <String, Item>{};
  for (final cat in matchingCategories) {
    if (cat.items == null) continue;
    for (final item in cat.items!) {
      if (!itemsByName.containsKey(item.name)) {
        itemsByName[item.name] = item.copyWith(actual: 0);
      }
      // Sum actuals from transactions for this item
      final itemTxs = allTransactions.where(
        (tx) => tx.itemId == item.id && tx.type == TransactionType.expense,
      );
      final itemActual =
          itemTxs.fold<double>(0.0, (sum, tx) => sum + tx.amount);
      final existing = itemsByName[item.name]!;
      itemsByName[item.name] = existing.copyWith(
        actual: existing.actual + itemActual,
        projected: existing.projected > 0 ? existing.projected : item.projected,
      );
    }
  }

  // Build aggregated category
  final aggregatedCategory = sourceCategory.copyWith(
    items: itemsByName.values.toList(),
  );

  return (category: aggregatedCategory, transactions: categoryTransactions);
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
  final List<String> allCategoryIds = [];

  _CategoryAccumulator({
    required this.name,
    required this.icon,
    required this.color,
  });
}
