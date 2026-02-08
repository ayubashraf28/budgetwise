import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../models/subscription.dart';
import '../../models/transaction.dart';
import '../../providers/providers.dart';
import '../../widgets/charts/donut_chart.dart';
import '../../widgets/charts/stacked_bar_chart.dart';
import '../transactions/transaction_form_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int? _selectedYearlyBarIndex;
  bool _isAmountsVisible = true;

  @override
  void initState() {
    super.initState();
    // Ensure all 12 months exist and current calendar month is active.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ensureMonthSetupProvider.future).then((_) {
        ref.invalidate(activeMonthProvider);
        ref.invalidate(userMonthsProvider);
        ref.invalidate(categoriesProvider);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(monthlySummaryProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final profile = ref.watch(userProfileProvider);
    final upcoming = ref.watch(upcomingSubscriptionsProvider);
    final totalActualIncome = ref.watch(totalActualIncomeProvider);
    final totalActualExpenses = ref.watch(totalActualExpensesProvider);
    final categories = ref.watch(categoriesProvider);
    final yearlyMonthlyExpenses = ref.watch(yearlyMonthlyExpensesProvider);
    final transactions = ref.watch(transactionsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeMonthProvider);
          ref.invalidate(categoriesProvider);
          ref.invalidate(incomeSourcesProvider);
          ref.invalidate(subscriptionsProvider);
          ref.invalidate(yearlyMonthlyExpensesProvider);
          ref.invalidate(transactionsProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildGreetingHeader(profile),
            ),
            SliverToBoxAdapter(
              child: _buildOverviewHero(
                summary,
                currencySymbol,
                totalActualIncome,
                totalActualExpenses,
              ),
            ),
            SliverToBoxAdapter(
              child: _buildUpcomingPayments(currencySymbol, upcoming),
            ),
            SliverToBoxAdapter(
              child: _buildSpendingChart(categories, currencySymbol),
            ),
            SliverToBoxAdapter(
              child:
                  _buildYearlyBarChart(yearlyMonthlyExpenses, currencySymbol),
            ),
            SliverToBoxAdapter(
              child: _buildRecentTransactions(transactions, currencySymbol),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xl),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingHeader(AsyncValue<dynamic> profile) {
    final displayName = profile.value?.displayName ?? 'User';

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Row(
          children: [
            InkWell(
              onTap: () => context.push('/settings/profile'),
              borderRadius: BorderRadius.circular(AppSizing.radiusFull),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.surfaceLight,
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(displayName, style: AppTypography.h3),
                ],
              ),
            ),
            IconButton(
              icon:
                  const Icon(LucideIcons.bell, color: AppColors.textSecondary),
              onPressed: () {
                // Future: notifications screen.
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewHero(
    dynamic summary,
    String currencySymbol,
    double actualIncome,
    double actualExpenses,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: SizedBox(
        height: 214,
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: _buildBalanceHeroCard(summary, currencySymbol),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 6,
              child: Column(
                children: [
                  Expanded(
                    child: _buildCompactSummaryCard(
                      title: 'Income',
                      amount: actualIncome,
                      isAmountVisible: _isAmountsVisible,
                      currencySymbol: currencySymbol,
                      icon: LucideIcons.trendingUp,
                      accentColor: AppColors.success,
                      onTap: () => context.push('/income'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: _buildCompactSummaryCard(
                      title: 'Expense',
                      amount: actualExpenses,
                      isAmountVisible: _isAmountsVisible,
                      currencySymbol: currencySymbol,
                      icon: LucideIcons.trendingDown,
                      accentColor: AppColors.error,
                      onTap: () => context.push('/expenses'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceHeroCard(dynamic summary, String currencySymbol) {
    final actualBalance = summary?.actualBalance ?? 0.0;
    final monthName =
        summary?.monthName ?? DateFormat('MMMM').format(DateTime.now());
    final monthYear = _formatBalancePeriodLabel(monthName);

    return _buildGlassCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      borderColor: AppColors.savings.withValues(alpha: 0.35),
      gradientColors: const [
        Color(0xFF0F4D63),
        Color(0xFF0A3C4F),
      ],
      borderRadius: BorderRadius.circular(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppSizing.radiusSm),
                ),
                child: Icon(
                  LucideIcons.wallet,
                  size: 13,
                  color: Colors.white.withValues(alpha: 0.98),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Total Balance',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w500,
                  fontSize: 17,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () =>
                    setState(() => _isAmountsVisible = !_isAmountsVisible),
                borderRadius: BorderRadius.circular(AppSizing.radiusFull),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isAmountsVisible ? LucideIcons.eye : LucideIcons.eyeOff,
                    size: 15,
                    color: Colors.white.withValues(alpha: 0.94),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            height: 72,
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                _isAmountsVisible
                    ? '$currencySymbol${_formatAmount(actualBalance)}'
                    : '\u2022\u2022\u2022\u2022',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 66,
                  fontWeight: FontWeight.w500,
                  height: 1,
                ),
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  monthYear,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _showAddTransaction(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.28)),
                  ),
                  child: Icon(
                    LucideIcons.plus,
                    size: 20,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSummaryCard({
    required String title,
    required double amount,
    required bool isAmountVisible,
    required String currencySymbol,
    required IconData icon,
    required Color accentColor,
    VoidCallback? onTap,
  }) {
    final isIncome = accentColor == AppColors.success;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentColor.withValues(alpha: 0.22),
                accentColor.withValues(alpha: 0.10),
              ],
            ),
            borderRadius: BorderRadius.circular(AppSizing.radiusLg),
            border: Border.all(color: accentColor.withValues(alpha: 0.34)),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(AppSizing.radiusSm),
                    ),
                    child: Icon(icon, size: 13, color: accentColor),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    title,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppSizing.radiusFull),
                    ),
                    child: Text(
                      isIncome ? 'IN' : 'OUT',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      isAmountVisible
                          ? '$currencySymbol${_formatAmount(amount)}'
                          : '\u2022\u2022\u2022\u2022',
                      style: AppTypography.amountLarge.copyWith(
                        fontSize: 36,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    isIncome ? 'Money received' : 'Money spent',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 10,
                      height: 1.1,
                      color: accentColor.withValues(alpha: 0.85),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isIncome
                        ? LucideIcons.arrowUpRight
                        : LucideIcons.arrowDownRight,
                    size: 12,
                    color: accentColor.withValues(alpha: 0.9),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingPayments(
    String currencySymbol,
    AsyncValue<List<Subscription>> upcoming,
  ) {
    return upcoming.when(
      data: (upcomingList) {
        final sorted = [...upcomingList]
          ..sort((a, b) => a.daysUntilDue.compareTo(b.daysUntilDue));
        final visible = sorted.take(3).toList();

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Upcoming Payments', style: AppTypography.h3),
                  TextButton(
                    onPressed: () => context.push('/subscriptions'),
                    child: const Text(
                      'View All',
                      style: TextStyle(color: AppColors.savings),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildGlassCard(
                padding: EdgeInsets.zero,
                borderColor: AppColors.border.withValues(alpha: 0.85),
                child: sorted.isEmpty
                    ? _buildNoUpcomingPaymentsState()
                    : Column(
                        children: [
                          for (var index = 0;
                              index < visible.length;
                              index++) ...[
                            _buildUpcomingPaymentTile(
                                visible[index], currencySymbol),
                            if (index < visible.length - 1)
                              const Divider(height: 1, color: AppColors.border),
                          ],
                          if (sorted.length > visible.length)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '+${sorted.length - visible.length} more upcoming',
                                    style: AppTypography.bodySmall,
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () =>
                                        context.push('/subscriptions'),
                                    child: const Text(
                                      'See all',
                                      style:
                                          TextStyle(color: AppColors.savings),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildNoUpcomingPaymentsState() {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Icon(LucideIcons.calendarCheck2,
              color: AppColors.textMuted, size: 30),
          SizedBox(height: AppSpacing.sm),
          Text('No upcoming payments', style: AppTypography.bodyMedium),
          SizedBox(height: 2),
          Text('You are all caught up', style: AppTypography.bodySmall),
        ],
      ),
    );
  }

  Widget _buildUpcomingPaymentTile(Subscription sub, String currencySymbol) {
    final accentColor = sub.isOverdue ? AppColors.error : sub.colorValue;
    final statusColor = sub.isOverdue
        ? AppColors.error
        : sub.isDueToday
            ? AppColors.warning
            : AppColors.savings;

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSizing.radiusMd),
            ),
            child: Icon(_getIcon(sub.icon), size: 16, color: accentColor),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.name,
                  style: AppTypography.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('MMM d').format(sub.nextDueDate)} - ${sub.billingCycleLabel}',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$currencySymbol${_formatAmount(sub.amount)}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub.isOverdue
                    ? 'Overdue'
                    : sub.isDueToday
                        ? 'Due today'
                        : 'In ${sub.daysUntilDue}d',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingChart(
    AsyncValue<List<dynamic>> categories,
    String currencySymbol,
  ) {
    return categories.when(
      data: (categoryList) {
        final spendingCategories =
            categoryList.where((c) => c.totalActual > 0).toList();
        if (spendingCategories.isEmpty) {
          return const SizedBox.shrink();
        }

        final totalActual = spendingCategories.fold<double>(
          0.0,
          (sum, c) => sum + c.totalActual,
        );

        final segments = spendingCategories
            .map(
              (c) => DonutSegment(
                color: c.colorValue,
                value: c.totalActual,
                name: c.name,
                icon: c.icon,
              ),
            )
            .toList();

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Spending by category', style: AppTypography.h3),
              const SizedBox(height: AppSpacing.sm),
              _buildGlassCard(
                padding: const EdgeInsets.all(AppSpacing.sm),
                borderColor: AppColors.border.withValues(alpha: 0.85),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth;
                    final isWideLayout = availableWidth >= 460;
                    final chartSize = isWideLayout
                        ? 260.0
                        : availableWidth.clamp(240.0, 360.0).toDouble();
                    final strokeWidth =
                        isWideLayout ? 28.0 : (chartSize >= 320 ? 26.0 : 22.0);
                    final selectedStrokeWidth = strokeWidth + 6;
                    final gapDegrees = isWideLayout ? 15.0 : 13.0;
                    final centerAmountStyle =
                        AppTypography.amountLarge.copyWith(
                      fontSize: chartSize >= 320 ? 40 : 32,
                      height: 1.0,
                    );
                    final centerLabelStyle = TextStyle(
                      color: AppColors.textMuted,
                      fontSize: chartSize >= 320 ? 13 : 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                    );
                    final chartWidget = SizedBox(
                      width: chartSize,
                      child: DonutChart(
                        segments: segments,
                        total: totalActual,
                        height: chartSize,
                        strokeWidth: strokeWidth,
                        selectedStrokeWidth: selectedStrokeWidth,
                        gapDegrees: gapDegrees,
                        centerBuilder: (selectedIndex) {
                          if (selectedIndex == null ||
                              selectedIndex >= spendingCategories.length) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.trendingUp,
                                  color: AppColors.savings,
                                  size: 28,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '$currencySymbol${_formatAmount(totalActual)}',
                                  style: centerAmountStyle,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'TOTAL',
                                  style: centerLabelStyle,
                                ),
                              ],
                            );
                          }

                          final category = spendingCategories[selectedIndex];
                          final percentage = totalActual > 0
                              ? (category.totalActual / totalActual * 100)
                              : 0.0;

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getIcon(category.icon),
                                color: category.colorValue,
                                size: 28,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '$currencySymbol${_formatAmount(category.totalActual)}',
                                style: centerAmountStyle,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                category.name.toUpperCase(),
                                style: centerLabelStyle,
                              ),
                              Text(
                                '${percentage.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: category.colorValue,
                                  fontSize: chartSize >= 320 ? 18 : 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    );

                    final legendWidget = _buildSpendingLegend(
                      spendingCategories,
                      totalActual,
                      currencySymbol,
                      maxItems: isWideLayout ? 5 : 4,
                    );

                    if (isWideLayout) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          chartWidget,
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: legendWidget),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        Center(child: chartWidget),
                        const SizedBox(height: AppSpacing.md),
                        legendWidget,
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSpendingLegend(
    List<dynamic> categories,
    double totalActual,
    String currencySymbol, {
    int maxItems = 4,
  }) {
    final sorted = [...categories]
      ..sort((a, b) => b.totalActual.compareTo(a.totalActual));
    final visible = sorted.take(maxItems).toList();

    return Column(
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          _buildSpendingLegendRow(
            visible[i],
            totalActual,
            currencySymbol,
          ),
          if (i < visible.length - 1)
            const Divider(height: 1, color: AppColors.border),
        ],
      ],
    );
  }

  Widget _buildSpendingLegendRow(
    dynamic category,
    double totalActual,
    String currencySymbol,
  ) {
    final percentage =
        totalActual > 0 ? (category.totalActual / totalActual * 100) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: category.colorValue,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: TextStyle(
              color: category.colorValue,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$currencySymbol${_formatAmount(category.totalActual)}',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearlyBarChart(
    AsyncValue<List<MonthlyBarData>> yearlyMonthlyExpenses,
    String currencySymbol,
  ) {
    return yearlyMonthlyExpenses.when(
      data: (monthlyData) {
        if (monthlyData.isEmpty ||
            monthlyData.every((d) => d.totalExpenses == 0)) {
          return const SizedBox.shrink();
        }

        final year = DateTime.now().year;

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Yearly Overview', style: AppTypography.h3),
                  Text(
                    '$year',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildGlassCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                borderColor: AppColors.border.withValues(alpha: 0.85),
                child: StackedBarChart(
                  monthlyData: monthlyData,
                  currencySymbol: currencySymbol,
                  interactive: true,
                  selectedBarIndex: _selectedYearlyBarIndex,
                  onBarSelected: (index) {
                    setState(() => _selectedYearlyBarIndex = index);
                  },
                  height: 230,
                ),
              ),
              if (_selectedYearlyBarIndex != null &&
                  _selectedYearlyBarIndex! < monthlyData.length) ...[
                const SizedBox(height: AppSpacing.sm),
                _buildYearlySelectionSummary(
                  monthlyData[_selectedYearlyBarIndex!],
                  currencySymbol,
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildYearlySelectionSummary(
    MonthlyBarData selectedMonth,
    String currencySymbol,
  ) {
    return Row(
      children: [
        Text(
          '${selectedMonth.monthName}: $currencySymbol${_formatAmount(selectedMonth.totalExpenses)}',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => setState(() => _selectedYearlyBarIndex = null),
          child: const Text(
            'Clear',
            style: TextStyle(color: AppColors.savings),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(
    AsyncValue<List<Transaction>> transactions,
    String currencySymbol,
  ) {
    return transactions.when(
      data: (list) {
        final recent = [...list]..sort((a, b) => b.date.compareTo(a.date));
        final visible = recent.take(5).toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Transactions', style: AppTypography.h3),
                  TextButton(
                    onPressed: () => context.push('/transactions'),
                    child: const Text(
                      'View all',
                      style: TextStyle(color: AppColors.savings),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildGlassCard(
                padding: EdgeInsets.zero,
                borderColor: AppColors.border.withValues(alpha: 0.85),
                child: visible.isEmpty
                    ? _buildEmptyRecentTransactions()
                    : Column(
                        children: [
                          for (var index = 0;
                              index < visible.length;
                              index++) ...[
                            _buildRecentTransactionRow(
                              visible[index],
                              currencySymbol,
                            ),
                            if (index < visible.length - 1)
                              const Divider(height: 1, color: AppColors.border),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: _buildGlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          borderColor: AppColors.border.withValues(alpha: 0.85),
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildGlassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(AppSpacing.md),
    BorderRadius? borderRadius,
    Color borderColor = AppColors.border,
    Color tintColor = AppColors.surface,
    List<Color>? gradientColors,
  }) {
    final radius = borderRadius ?? BorderRadius.circular(AppSizing.radiusLg);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: tintColor.withValues(alpha: 0.45),
            gradient: gradientColors == null
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
            borderRadius: radius,
            border: Border.all(color: borderColor),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildEmptyRecentTransactions() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const Icon(LucideIcons.receipt, color: AppColors.textMuted, size: 30),
          const SizedBox(height: AppSpacing.sm),
          const Text('No transactions yet', style: AppTypography.bodyMedium),
          const SizedBox(height: 2),
          const Text('Start by adding your first transaction',
              style: AppTypography.bodySmall),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: () => _showAddTransaction(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.savings),
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text('Add transaction'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionRow(
      Transaction transaction, String currencySymbol) {
    final amountColor =
        transaction.isIncome ? AppColors.success : AppColors.error;
    final chipColor = transaction.isIncome
        ? AppColors.success.withValues(alpha: 0.15)
        : AppColors.error.withValues(alpha: 0.15);

    return InkWell(
      onTap: () => context.push('/transactions'),
      borderRadius: BorderRadius.circular(AppSizing.radiusLg),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: amountColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
              ),
              child: Icon(
                _getTransactionIcon(transaction),
                size: 16,
                color: amountColor,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.displayName,
                    style: AppTypography.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: chipColor,
                          borderRadius:
                              BorderRadius.circular(AppSizing.radiusFull),
                        ),
                        child: Text(
                          transaction.isIncome
                              ? 'Income'
                              : (transaction.categoryName ?? 'Expense'),
                          style: TextStyle(
                            color: amountColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('MMM d, yyyy').format(transaction.date),
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  transaction.formattedAmount(currencySymbol),
                  style: TextStyle(
                    color: amountColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.isIncome ? 'Received' : 'Paid',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount.abs() >= 100000) {
      return NumberFormat('#,##0').format(amount.round());
    }
    if (amount == amount.roundToDouble()) {
      return NumberFormat('#,##0').format(amount.round());
    }
    return NumberFormat('#,##0.##').format(amount);
  }

  String _formatBalancePeriodLabel(String monthName) {
    final alreadyHasYear = RegExp(r'\b\d{4}\b').hasMatch(monthName);
    if (alreadyHasYear) {
      return monthName;
    }
    return '$monthName ${DateTime.now().year}';
  }

  IconData _getTransactionIcon(Transaction transaction) {
    if (transaction.isIncome) {
      return LucideIcons.arrowDownLeft;
    }

    final name =
        (transaction.categoryName ?? transaction.displayName).toLowerCase();

    if (name.contains('food') || name.contains('restaurant')) {
      return LucideIcons.utensils;
    }
    if (name.contains('transport') || name.contains('car')) {
      return LucideIcons.car;
    }
    if (name.contains('home') || name.contains('housing')) {
      return LucideIcons.home;
    }
    if (name.contains('entertainment') || name.contains('game')) {
      return LucideIcons.gamepad2;
    }
    if (name.contains('shopping')) {
      return LucideIcons.shoppingBag;
    }
    if (name.contains('health')) {
      return LucideIcons.heart;
    }
    if (name.contains('gift')) {
      return LucideIcons.gift;
    }

    return LucideIcons.receipt;
  }

  IconData _getIcon(String iconName) {
    final icons = {
      'home': LucideIcons.home,
      'utensils': LucideIcons.utensils,
      'car': LucideIcons.car,
      'tv': LucideIcons.tv,
      'shopping-bag': LucideIcons.shoppingBag,
      'gamepad-2': LucideIcons.gamepad2,
      'piggy-bank': LucideIcons.piggyBank,
      'graduation-cap': LucideIcons.graduationCap,
      'heart': LucideIcons.heart,
      'wallet': LucideIcons.wallet,
      'briefcase': LucideIcons.briefcase,
      'plane': LucideIcons.plane,
      'gift': LucideIcons.gift,
      'credit-card': LucideIcons.creditCard,
      'landmark': LucideIcons.landmark,
      'baby': LucideIcons.baby,
      'dumbbell': LucideIcons.dumbbell,
      'music': LucideIcons.music,
      'book': LucideIcons.book,
      'repeat': LucideIcons.repeat,
    };

    return icons[iconName] ?? LucideIcons.creditCard;
  }

  void _showAddTransaction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TransactionFormSheet(),
    );
  }
}
