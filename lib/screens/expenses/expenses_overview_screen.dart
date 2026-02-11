import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../models/category.dart';
import '../../models/month.dart';
import '../../models/transaction.dart';
import '../../providers/providers.dart';
import '../../services/category_service.dart';
import '../../services/income_service.dart';
import '../../utils/app_icon_registry.dart';
import '../../widgets/charts/donut_chart.dart';
import '../../widgets/charts/stacked_bar_chart.dart';
import '../../widgets/common/neo_page_components.dart';
import 'category_form_sheet.dart';

class ExpensesOverviewScreen extends ConsumerStatefulWidget {
  const ExpensesOverviewScreen({super.key});

  @override
  ConsumerState<ExpensesOverviewScreen> createState() =>
      _ExpensesOverviewScreenState();
}

class _ExpensesOverviewScreenState
    extends ConsumerState<ExpensesOverviewScreen> {
  int? _selectedCategoryIndex;
  int? _selectedBarMonthIndex; // Tapped bar in year view → filter categories

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Trigger month setup: creates all 12 months + copies categories
      await ref.read(ensureMonthSetupProvider.future);
      ref.invalidate(userMonthsProvider);

      // Initialize budget month selection from active month (only if not set)
      final current = ref.read(budgetSelectedMonthIdProvider);
      if (current == null) {
        final active = await ref.read(activeMonthProvider.future);
        if (active != null) {
          ref.read(budgetSelectedMonthIdProvider.notifier).state = active.id;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);
    final isYearView = ref.watch(budgetYearViewEnabledProvider);
    // Budget screen's own month (independent from home / transactions)
    final selectedMonthId = ref.watch(budgetSelectedMonthIdProvider);
    if (selectedMonthId == null) {
      return Scaffold(
        backgroundColor: palette.appBg,
        body: const NeoPageBackground(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final categories = ref.watch(categoriesForMonthProvider(selectedMonthId));
    final userMonths = ref.watch(userMonthsProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    // Transactions for expense count (non-blocking)
    final monthTx =
        ref.watch(transactionsForMonthProvider(selectedMonthId)).valueOrNull ??
            [];
    final expenseTransactions =
        monthTx.where((t) => t.type == TransactionType.expense).toList();

    // ── Year view providers ──
    final yearlyMonthlyExpenses = ref.watch(yearlyMonthlyExpensesProvider);
    final totalYearlyExpenses = ref.watch(totalYearlyExpensesProvider);
    final yearlyCategorySummaries = ref.watch(yearlyCategorySummariesProvider);

    // Build transaction count map: categoryId -> count
    final txCountByCategory = <String, int>{};
    for (final tx in expenseTransactions) {
      if (tx.categoryId != null) {
        txCountByCategory[tx.categoryId!] =
            (txCountByCategory[tx.categoryId!] ?? 0) + 1;
      }
    }

    return Scaffold(
      backgroundColor: palette.appBg,
      body: NeoPageBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(categoriesForMonthProvider(selectedMonthId));
            ref.invalidate(transactionsForMonthProvider(selectedMonthId));
            if (isYearView) {
              ref.invalidate(yearlyMonthlyExpensesProvider);
              ref.invalidate(yearlyCategorySummariesProvider);
            }
          },
          child: categories.when(
            data: (categoryList) {
              // Filter to only categories with actual spending for the chart
              final totalActual = categoryList.fold<double>(
                  0.0, (sum, c) => sum + c.totalActual);
              final spendingCategories =
                  categoryList.where((c) => c.totalActual > 0).toList();

              return CustomScrollView(
                slivers: [
                  // ── Page Header (unchanged) ──
                  SliverToBoxAdapter(
                    child: _buildPageHeader(),
                  ),

                  // ── Month/Year Toggle (NEW) ──
                  SliverToBoxAdapter(
                    child: _buildViewToggle(isYearView: isYearView),
                  ),

                  // ── MONTH VIEW (unchanged, conditionally shown) ──
                  if (!isYearView) ...[
                    // Month Selector
                    SliverToBoxAdapter(
                      child: _buildMonthSelector(userMonths, selectedMonthId),
                    ),
                    // Spacing
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.lg),
                    ),
                    // Donut Chart
                    SliverToBoxAdapter(
                      child: _buildDonutChart(
                        spendingCategories,
                        totalActual,
                        currencySymbol,
                      ),
                    ),
                  ],

                  // ── YEAR VIEW (conditionally shown) ──
                  if (isYearView) ...[
                    // Year Selector
                    SliverToBoxAdapter(
                      child: _buildYearSelector(),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.lg),
                    ),
                    SliverToBoxAdapter(
                      child: yearlyMonthlyExpenses.when(
                        data: (monthlyData) =>
                            _buildBarChart(monthlyData, currencySymbol),
                        loading: () => const SizedBox(
                          height: 280,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ),
                  ],

                  // ── Categories Header ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.sm,
                      ),
                      child: isYearView && _selectedBarMonthIndex != null
                          ? _buildSelectedBarHeader(yearlyMonthlyExpenses)
                          : const Text(
                              'Categories',
                              style: AppTypography.h3,
                            ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.sm,
                      ),
                      child: _buildAddButton(),
                    ),
                  ),

                  // ── MONTH VIEW: Category List (unchanged, conditionally shown) ──
                  if (!isYearView) ...[
                    if (categoryList.isEmpty)
                      SliverToBoxAdapter(child: _buildEmptyState())
                    else
                      SliverToBoxAdapter(
                        child: _buildCategoryList(
                          categoryList,
                          totalActual,
                          currencySymbol,
                          txCountByCategory,
                        ),
                      ),
                  ],

                  // ── YEAR VIEW: Category list ──
                  if (isYearView) ...[
                    // When a bar is selected → show that month's categories
                    if (_selectedBarMonthIndex != null)
                      SliverToBoxAdapter(
                        child: _buildBarMonthCategories(
                          yearlyMonthlyExpenses,
                          currencySymbol,
                        ),
                      )
                    // Default → yearly aggregated categories
                    else
                      SliverToBoxAdapter(
                        child: yearlyCategorySummaries.when(
                          data: (summaries) {
                            if (summaries.isEmpty) return _buildEmptyState();
                            return _buildYearlyCategoryList(
                              summaries,
                              totalYearlyExpenses,
                              currencySymbol,
                            );
                          },
                          loading: () => const Padding(
                            padding: EdgeInsets.all(AppSpacing.xl),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ),
                  ],

                  // ── Bottom Padding (unchanged) ──
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xxl),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildErrorState(error.toString()),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // PAGE HEADER
  // ──────────────────────────────────────────────

  Widget _buildPageHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        NeoLayout.screenPadding,
        0,
        NeoLayout.screenPadding,
        AppSpacing.sm,
      ),
      child: NeoPageHeader(
        title: 'Budget',
        subtitle: 'View your spending by category',
      ),
    );
  }

  // ──────────────────────────────────────────────
  // MONTH SELECTOR
  // ──────────────────────────────────────────────

  Widget _buildMonthSelector(
    AsyncValue<List<Month>> userMonths,
    String selectedMonthId,
  ) {
    return userMonths.when(
      data: (months) {
        if (months.isEmpty) return const SizedBox.shrink();

        final now = DateTime.now();
        // Derive year from the selected month
        final selectedMonth =
            months.where((m) => m.id == selectedMonthId).firstOrNull;
        final currentYear = selectedMonth?.startDate.year ?? now.year;

        // Filter to months in the active year, sorted chronologically
        final yearMonths = months
            .where((m) => m.startDate.year == currentYear)
            .toList()
          ..sort((a, b) => a.startDate.compareTo(b.startDate));

        if (yearMonths.isEmpty) return const SizedBox.shrink();

        final monthAbbreviations = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
        ];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              // Month chips (scrollable)
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: yearMonths.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final month = yearMonths[index];
                      final isActive = month.id == selectedMonthId;
                      final isFuture = month.startDate.isAfter(now);
                      final isCurrentCalendarMonth =
                          month.startDate.month == now.month &&
                              month.startDate.year == now.year;

                      // Get 3-letter abbreviation
                      final abbr =
                          month.startDate.month <= monthAbbreviations.length
                              ? monthAbbreviations[month.startDate.month - 1]
                              : month.name.substring(0, 3);

                      return GestureDetector(
                        onTap: () => _switchMonth(month.id),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.white
                                    : NeoTheme.of(context).surface1,
                                borderRadius:
                                    BorderRadius.circular(AppSizing.radiusMd),
                                border: isActive
                                    ? null
                                    : Border.all(
                                        color: NeoTheme.of(context).stroke),
                              ),
                              child: Text(
                                abbr,
                                style: TextStyle(
                                  color: isActive
                                      ? NeoTheme.of(context).appBg
                                      : isFuture
                                          ? NeoTheme.of(context)
                                              .textMuted
                                              .withValues(alpha: 0.5)
                                          : NeoTheme.of(context).textSecondary,
                                  fontSize: 13,
                                  fontWeight: isActive
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                            // Current calendar month indicator dot
                            if (isCurrentCalendarMonth && !isActive)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: NeoTheme.positiveValue(context),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Year label
              Text(
                '$currentYear',
                style: TextStyle(
                  color: NeoTheme.of(context).textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 50),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _switchMonth(String monthId) async {
    setState(() => _selectedCategoryIndex = null); // Reset chart selection

    // Ensure the target month has categories AND income sources
    final categoryService = CategoryService();
    final incomeService = IncomeService();
    await categoryService.ensureCategoriesForMonth(monthId);
    await incomeService.ensureIncomeSourcesForMonth(monthId);

    // Update budget screen selection only — does NOT affect home/transactions
    ref.read(budgetSelectedMonthIdProvider.notifier).state = monthId;
  }

  // ──────────────────────────────────────────────
  // YEAR SELECTOR
  // ──────────────────────────────────────────────

  Widget _buildYearSelector() {
    final selectedYear = ref.watch(selectedYearProvider);
    final yearsWithData = ref.watch(yearsWithDataProvider);
    final now = DateTime.now();
    final currentYear = now.year;

    // Show 10 years: 5 past + current + 4 future
    final years = List.generate(10, (i) => currentYear - 5 + i);

    // Auto-scroll to the selected year's position
    final selectedIndex = years.indexOf(selectedYear);
    // Each chip is ~60px wide + 8px separator
    final initialOffset = selectedIndex > 0
        ? (selectedIndex * 68.0) - 100 // Offset to roughly center it
        : 0.0;
    final scrollController = ScrollController(
      initialScrollOffset: initialOffset.clamp(0.0, double.infinity),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: SizedBox(
        height: 50,
        child: ListView.separated(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          itemCount: years.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final year = years[index];
            final isActive = year == selectedYear;
            final isFuture = year > currentYear;
            final hasData = yearsWithData.contains(year);
            final isCurrentYear = year == currentYear;

            // Future years without data are disabled
            final isDisabled = isFuture && !hasData;

            return GestureDetector(
              onTap: isDisabled
                  ? null
                  : () {
                      ref.read(budgetSelectedYearProvider.notifier).state =
                          year;
                      setState(() {
                        _selectedCategoryIndex = null;
                        _selectedBarMonthIndex = null;
                      });
                    },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white
                          : NeoTheme.of(context).surface1,
                      borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                      border: isActive
                          ? null
                          : Border.all(color: NeoTheme.of(context).stroke),
                    ),
                    child: Text(
                      '$year',
                      style: TextStyle(
                        color: isActive
                            ? NeoTheme.of(context).appBg
                            : isDisabled
                                ? NeoTheme.of(context)
                                    .textMuted
                                    .withValues(alpha: 0.3)
                                : isFuture
                                    ? NeoTheme.of(context)
                                        .textMuted
                                        .withValues(alpha: 0.5)
                                    : hasData
                                        ? NeoTheme.of(context).textSecondary
                                        : NeoTheme.of(context)
                                            .textMuted
                                            .withValues(alpha: 0.5),
                        fontSize: 13,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  // Current calendar year indicator dot
                  if (isCurrentYear && !isActive)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: NeoTheme.positiveValue(context),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // DONUT CHART
  // ──────────────────────────────────────────────

  Widget _buildDonutChart(
    List<Category> spendingCategories,
    double totalActual,
    String currencySymbol,
  ) {
    if (spendingCategories.isEmpty) {
      return const SizedBox(height: AppSpacing.lg);
    }

    final segments = spendingCategories
        .map((c) => DonutSegment(
              color: c.colorValue,
              value: c.totalActual,
              name: c.name,
              icon: c.icon,
            ))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: NeoTheme.of(context).surface1,
          borderRadius: BorderRadius.circular(AppSizing.radiusXl),
        ),
        child: DonutChart(
          segments: segments,
          total: totalActual,
          initialSelectedIndex: _selectedCategoryIndex,
          onSelectionChanged: (index) {
            setState(() => _selectedCategoryIndex = index);
          },
          centerBuilder: (selectedIndex) {
            return _buildChartCenter(
              spendingCategories,
              totalActual,
              currencySymbol,
              selectedIndex,
            );
          },
        ),
      ),
    );
  }

  Widget _buildChartCenter(
    List<Category> spendingCategories,
    double totalActual,
    String currencySymbol,
    int? selectedIndex,
  ) {
    // Default: show total
    if (selectedIndex == null || selectedIndex >= spendingCategories.length) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.trendingUp,
            color: NeoTheme.positiveValue(context),
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            '$currencySymbol${_formatAmount(totalActual)}',
            style: AppTypography.amountMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'TOTAL',
            style: TextStyle(
              color: NeoTheme.of(context).textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.0,
            ),
          ),
        ],
      );
    }

    // Selected category
    final category = spendingCategories[selectedIndex];
    final percentage =
        totalActual > 0 ? (category.totalActual / totalActual * 100) : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _getIcon(category.icon),
          color: category.colorValue,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          '$currencySymbol${_formatAmount(category.totalActual)}',
          style: AppTypography.amountMedium,
        ),
        const SizedBox(height: 4),
        Text(
          category.name.toUpperCase(),
          style: TextStyle(
            color: NeoTheme.of(context).textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${percentage.toStringAsFixed(0)}%',
          style: TextStyle(
            color: category.colorValue,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  // CATEGORIES LIST
  // ──────────────────────────────────────────────

  Widget _buildCategoryList(
    List<Category> categoryList,
    double totalActual,
    String currencySymbol,
    Map<String, int> txCountByCategory,
  ) {
    return Column(
      children: categoryList.asMap().entries.map((entry) {
        final category = entry.value;
        final percentage =
            totalActual > 0 ? (category.totalActual / totalActual * 100) : 0.0;
        final txCount = txCountByCategory[category.id] ?? 0;

        return Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.sm,
          ),
          child: _buildCategoryRow(
            category: category,
            percentage: percentage,
            txCount: txCount,
            currencySymbol: currencySymbol,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryRow({
    required Category category,
    required double percentage,
    required int txCount,
    required String currencySymbol,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/budget/category/${category.id}'),
        onLongPress: () => _showEditSheet(category),
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        child: Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: NeoTheme.of(context).surface1,
            borderRadius: BorderRadius.circular(AppSizing.radiusLg),
            border: Border.all(color: NeoTheme.of(context).stroke),
          ),
          child: Row(
            children: [
              // Circular colored icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: category.colorValue,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIcon(category.icon),
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Name + transaction count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: AppTypography.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$txCount ${txCount == 1 ? 'transaction' : 'transactions'}',
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
              ),

              // Amount + percentage
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$currencySymbol${_formatAmount(category.totalActual)}',
                    style: AppTypography.amountSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // MONTH/YEAR TOGGLE
  // ──────────────────────────────────────────────

  Widget _buildViewToggle({required bool isYearView}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: NeoTheme.of(context).surface1,
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
          border: Border.all(color: NeoTheme.of(context).stroke),
        ),
        child: Row(
          children: [
            // Month button
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // Clear explicit year selection when switching back to month
                  ref.read(budgetSelectedYearProvider.notifier).state = null;
                  ref
                      .read(uiPreferencesProvider.notifier)
                      .setBudgetViewMode(BudgetViewMode.month);
                  setState(() {
                    _selectedCategoryIndex = null;
                    _selectedBarMonthIndex = null;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: !isYearView ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        size: 16,
                        color: !isYearView
                            ? NeoTheme.of(context).appBg
                            : NeoTheme.of(context).textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Month',
                        style: TextStyle(
                          color: !isYearView
                              ? NeoTheme.of(context).appBg
                              : NeoTheme.of(context).textMuted,
                          fontWeight:
                              !isYearView ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Year button
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // Initialize year from current selected month when switching
                  if (!isYearView) {
                    final selectedMonthId =
                        ref.read(budgetSelectedMonthIdProvider);
                    final months = ref.read(userMonthsProvider).value ?? [];
                    final selectedMonth = months
                        .where((m) => m.id == selectedMonthId)
                        .firstOrNull;
                    ref.read(budgetSelectedYearProvider.notifier).state =
                        selectedMonth?.startDate.year ?? DateTime.now().year;
                  }
                  ref
                      .read(uiPreferencesProvider.notifier)
                      .setBudgetViewMode(BudgetViewMode.year);
                  setState(() {
                    _selectedCategoryIndex = null;
                    _selectedBarMonthIndex = null;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isYearView ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.barChart3,
                        size: 16,
                        color: isYearView
                            ? NeoTheme.of(context).appBg
                            : NeoTheme.of(context).textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Year',
                        style: TextStyle(
                          color: isYearView
                              ? NeoTheme.of(context).appBg
                              : NeoTheme.of(context).textMuted,
                          fontWeight:
                              isYearView ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // BAR CHART (Year view only)
  // ──────────────────────────────────────────────

  Widget _buildBarChart(
    List<MonthlyBarData> monthlyData,
    String currencySymbol,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: NeoTheme.of(context).surface1,
          borderRadius: BorderRadius.circular(AppSizing.radiusXl),
        ),
        child: StackedBarChart(
          monthlyData: monthlyData,
          currencySymbol: currencySymbol,
          interactive: true,
          selectedBarIndex: _selectedBarMonthIndex,
          onBarSelected: (index) {
            setState(() => _selectedBarMonthIndex = index);
          },
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // BAR-SELECTED MONTH CATEGORIES (Year view)
  // ──────────────────────────────────────────────

  /// Header showing the selected month name + a "clear" button
  Widget _buildSelectedBarHeader(
    AsyncValue<List<MonthlyBarData>> yearlyMonthlyExpenses,
  ) {
    final monthlyData = yearlyMonthlyExpenses.valueOrNull ?? [];
    final idx = _selectedBarMonthIndex ?? 0;
    final monthName =
        (idx < monthlyData.length) ? monthlyData[idx].monthName : 'Month';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$monthName Categories',
          style: AppTypography.h3,
        ),
        GestureDetector(
          onTap: () => setState(() => _selectedBarMonthIndex = null),
          child: Text(
            'Show Year',
            style: TextStyle(
              color: NeoTheme.positiveValue(context),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Shows categories for a single month selected via the bar chart.
  Widget _buildBarMonthCategories(
    AsyncValue<List<MonthlyBarData>> yearlyMonthlyExpenses,
    String currencySymbol,
  ) {
    final monthlyData = yearlyMonthlyExpenses.valueOrNull ?? [];
    final idx = _selectedBarMonthIndex ?? 0;
    if (idx >= monthlyData.length) return _buildEmptyState();

    final barData = monthlyData[idx];
    final monthId = barData.monthId;

    // Fetch categories for this specific month (with calculated actuals)
    final monthCategories = ref.watch(categoriesForMonthProvider(monthId));
    // Fetch transactions for this month (for counts)
    final monthTx = ref.watch(transactionsForMonthProvider(monthId));

    return monthCategories.when(
      data: (cats) {
        if (cats.isEmpty) return _buildEmptyState();

        final totalActual =
            cats.fold<double>(0.0, (sum, c) => sum + c.totalActual);

        // Build tx count map for this month
        final txList = monthTx.valueOrNull ?? [];
        final txCountByCategory = <String, int>{};
        for (final tx in txList) {
          if (tx.categoryId != null && tx.type == TransactionType.expense) {
            txCountByCategory[tx.categoryId!] =
                (txCountByCategory[tx.categoryId!] ?? 0) + 1;
          }
        }

        return Column(
          children: cats.map((category) {
            final txCount = txCountByCategory[category.id] ?? 0;
            final percentage = totalActual > 0
                ? (category.totalActual / totalActual * 100)
                : 0.0;

            return Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.sm,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push('/budget/category/${category.id}'),
                  borderRadius: BorderRadius.circular(AppSizing.radiusLg),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md + 4,
                    ),
                    decoration: BoxDecoration(
                      color: NeoTheme.of(context).surface1,
                      borderRadius: BorderRadius.circular(AppSizing.radiusLg),
                      border: Border.all(color: NeoTheme.of(context).stroke),
                    ),
                    child: Row(
                      children: [
                        // Circular colored icon
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: category.colorValue,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIcon(category.icon),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),

                        // Name + transaction count
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.name,
                                style: AppTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$txCount ${txCount == 1 ? 'transaction' : 'transactions'}',
                                style: AppTypography.bodyMedium,
                              ),
                            ],
                          ),
                        ),

                        // Amount + percentage
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$currencySymbol${_formatAmount(category.totalActual)}',
                              style: AppTypography.amountSmall,
                            ),
                            const SizedBox(height: 4),
                            if (category.totalActual > 0)
                              Text(
                                '${percentage.toStringAsFixed(0)}%',
                                style: AppTypography.bodyMedium,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  // ──────────────────────────────────────────────
  // YEARLY CATEGORIES LIST (Year view only)
  // ──────────────────────────────────────────────

  Widget _buildYearlyCategoryList(
    List<YearlyCategorySummary> summaries,
    double totalYearlyExpenses,
    String currencySymbol,
  ) {
    return Column(
      children: summaries.map((summary) {
        final percentage = totalYearlyExpenses > 0
            ? (summary.totalActual / totalYearlyExpenses * 100)
            : 0.0;

        return Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.sm,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (summary.categoryIds.isNotEmpty) {
                  context.push(
                    '/budget/category/${summary.categoryIds.first}?yearMode=true',
                  );
                }
              },
              borderRadius: BorderRadius.circular(AppSizing.radiusLg),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md + 4,
                ),
                decoration: BoxDecoration(
                  color: NeoTheme.of(context).surface1,
                  borderRadius: BorderRadius.circular(AppSizing.radiusLg),
                  border: Border.all(color: NeoTheme.of(context).stroke),
                ),
                child: Row(
                  children: [
                    // Circular colored icon
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: summary.color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIcon(summary.icon),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),

                    // Name + transaction count
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            summary.name,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${summary.transactionCount} ${summary.transactionCount == 1 ? 'transaction' : 'transactions'}',
                            style: AppTypography.bodyMedium,
                          ),
                        ],
                      ),
                    ),

                    // Amount + percentage
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$currencySymbol${_formatAmount(summary.totalActual)}',
                          style: AppTypography.amountSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${percentage.toStringAsFixed(0)}%',
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ──────────────────────────────────────────────
  // ADD BUTTON
  // ──────────────────────────────────────────────

  Widget _buildAddButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showAddSheet(),
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        child: Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizing.radiusLg),
            border: Border.all(color: NeoTheme.of(context).stroke),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.plus,
                  color: NeoTheme.positiveValue(context), size: 20),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Add Category',
                style: TextStyle(
                  color: NeoTheme.positiveValue(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // EMPTY & ERROR STATES
  // ──────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: NeoTheme.of(context).surface1,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.folderOpen,
            size: 48,
            color: NeoTheme.of(context).textMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'No expense categories yet',
            style: AppTypography.h3,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Add your first expense category to start budgeting',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: () => _showAddSheet(),
            style: ElevatedButton.styleFrom(
              backgroundColor: NeoTheme.positiveValue(context),
            ),
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('Add Category'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: NeoTheme.negativeValue(context).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.alertCircle,
                size: 48, color: NeoTheme.negativeValue(context)),
            const SizedBox(height: AppSpacing.md),
            const Text('Something went wrong', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return NumberFormat('#,##,###').format(amount.toInt());
    }
    return amount.toStringAsFixed(amount == amount.roundToDouble() ? 0 : 2);
  }

  IconData _getIcon(String iconName) {
    return resolveAppIcon(iconName, fallback: LucideIcons.wallet);
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CategoryFormSheet(),
    );
  }

  void _showEditSheet(Category category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryFormSheet(category: category),
    );
  }
}
