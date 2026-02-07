import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../models/subscription.dart';
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
  bool _isBalanceVisible = true;

  @override
  void initState() {
    super.initState();
    // Ensure all 12 months exist and current calendar month is active
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
    final totalProjectedIncome = ref.watch(totalProjectedIncomeProvider);
    final totalActualExpenses = ref.watch(totalActualExpensesProvider);
    final totalProjectedExpenses = ref.watch(totalProjectedExpensesProvider);
    final categories = ref.watch(categoriesProvider);
    final yearlyMonthlyExpenses = ref.watch(yearlyMonthlyExpensesProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeMonthProvider);
          ref.invalidate(categoriesProvider);
          ref.invalidate(incomeSourcesProvider);
          ref.invalidate(subscriptionsProvider);
          ref.invalidate(yearlyMonthlyExpensesProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Greeting Header
            SliverToBoxAdapter(
              child: _buildGreetingHeader(ref, profile),
            ),

            // Balance Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _buildBalanceCard(ref, summary, currencySymbol),
              ),
            ),

            // Upcoming Payments (always shown)
            SliverToBoxAdapter(
              child: _buildUpcomingPayments(ref, currencySymbol, upcoming),
            ),

            // Income / Expense Summary Cards
            SliverToBoxAdapter(
              child: _buildIncomeExpenseCards(
                currencySymbol,
                totalActualIncome,
                totalProjectedIncome,
                totalActualExpenses,
                totalProjectedExpenses,
              ),
            ),

            // Spending by Category Donut Chart
            SliverToBoxAdapter(
              child: _buildSpendingChart(categories, currencySymbol),
            ),

            // Yearly Overview Bar Chart
            SliverToBoxAdapter(
              child: _buildYearlyBarChart(yearlyMonthlyExpenses, currencySymbol),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xl),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingHeader(WidgetRef ref, AsyncValue<dynamic> profile) {
    final displayName = profile.value?.displayName ?? 'User';

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
        child: Row(
          children: [
            // Profile avatar circle
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.savings,
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Greeting text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back',
                    style: AppTypography.bodySmall,
                  ),
                  Text(displayName, style: AppTypography.h2),
                ],
              ),
            ),
            // Notification bell icon
            IconButton(
              icon: const Icon(LucideIcons.bell, color: AppColors.textSecondary),
              onPressed: () {
                // Future: notifications screen
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(WidgetRef ref, dynamic summary, String currencySymbol) {
    final actualBalance = summary?.actualBalance ?? 0.0;
    const color = AppColors.savings;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + title row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                ),
                child: const Icon(LucideIcons.wallet, size: 18, color: color),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'Total Balance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const Spacer(),
              // Eye toggle
              GestureDetector(
                onTap: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
                child: Icon(
                  _isBalanceVisible ? LucideIcons.eye : LucideIcons.eyeOff,
                  size: 18,
                  color: color.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Amount
          Text(
            _isBalanceVisible
                ? '$currencySymbol${actualBalance.toStringAsFixed(0)}'
                : '••••••',
            style: AppTypography.amountMedium.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(
            'This month',
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // "Add New Transaction" button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddTransaction(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                foregroundColor: color,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                  side: BorderSide(color: color.withValues(alpha: 0.3)),
                ),
              ),
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text(
                'Add New Transaction',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildUpcomingPayments(
    WidgetRef ref,
    String currencySymbol,
    AsyncValue<List<Subscription>> upcoming,
  ) {
    return upcoming.when(
      data: (upcomingList) {
        if (upcomingList.isEmpty) {
          return _buildNoUpcomingPayments();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Upcoming Payments', style: AppTypography.h3),
                      Text('Bills due soon', style: AppTypography.bodySmall),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.push('/subscriptions'),
                    child: Text(
                      'View All',
                      style: TextStyle(color: AppColors.savings),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Horizontal scroll of cards
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: upcomingList.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final sub = upcomingList[index];
                  return _buildUpcomingCard(sub, currencySymbol);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildNoUpcomingPayments() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Upcoming Payments', style: AppTypography.h3),
              TextButton(
                onPressed: () => context.push('/subscriptions'),
                child: Text(
                  'View All',
                  style: TextStyle(color: AppColors.savings),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizing.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              children: [
                Icon(LucideIcons.calendarCheck, color: AppColors.textMuted, size: 32),
                SizedBox(height: AppSpacing.sm),
                Text('No upcoming payments', style: AppTypography.bodyMedium),
                Text("You're all caught up!", style: AppTypography.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildUpcomingCard(Subscription sub, String currencySymbol) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(AppSpacing.sm + 4), // 12px padding
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon + name row
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: sub.colorValue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSizing.radiusSm),
                ),
                child: Icon(_getIcon(sub.icon), color: sub.colorValue, size: 16),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  sub.name,
                  style: AppTypography.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Amount + cycle
          Text(
            '$currencySymbol${sub.amount.toStringAsFixed(0)}/${sub.billingCycleLabel.toLowerCase()}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          // Due date chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: sub.isOverdue
                  ? AppColors.error.withValues(alpha: 0.15)
                  : AppColors.savings.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSizing.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.calendar,
                  size: 11,
                  color: sub.isOverdue ? AppColors.error : AppColors.savings,
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    sub.isDueToday
                        ? 'Due today'
                        : 'Due in ${sub.daysUntilDue} days',
                    style: TextStyle(
                      fontSize: 10,
                      color: sub.isOverdue ? AppColors.error : AppColors.savings,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.alertCircle,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Something went wrong',
            style: AppTypography.h3,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            error,
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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

  Widget _buildIncomeExpenseCards(
    String currencySymbol,
    double actualIncome,
    double projectedIncome,
    double actualExpenses,
    double projectedExpenses,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Monthly Summary', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              // Income Card
              Expanded(
                child: _buildSummaryCard(
                  icon: LucideIcons.trendingUp,
                  title: 'Income',
                  actual: actualIncome,
                  projected: projectedIncome,
                  currencySymbol: currencySymbol,
                  accentColor: AppColors.savings,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Expense Card
              Expanded(
                child: _buildSummaryCard(
                  icon: LucideIcons.trendingDown,
                  title: 'Expenses',
                  actual: actualExpenses,
                  projected: projectedExpenses,
                  currencySymbol: currencySymbol,
                  accentColor: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required double actual,
    required double projected,
    required String currencySymbol,
    required Color accentColor,
  }) {
    final progress = projected > 0 ? (actual / projected).clamp(0.0, 1.5) : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accentColor),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$currencySymbol${actual.toStringAsFixed(0)}',
            style: AppTypography.amountSmall,
          ),
          const SizedBox(height: 2),
          Text(
            'of $currencySymbol${projected.toStringAsFixed(0)}',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.toDouble(),
              backgroundColor: accentColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              minHeight: 4,
            ),
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
        final spendingCategories = categoryList
            .where((c) => c.totalActual > 0)
            .toList();

        if (spendingCategories.isEmpty) {
          return const SizedBox.shrink();
        }

        final totalActual = spendingCategories.fold<double>(
          0.0,
          (sum, c) => sum + c.totalActual,
        );

        final segments = spendingCategories
            .map((c) => DonutSegment(
                  color: c.colorValue,
                  value: c.totalActual,
                  name: c.name,
                  icon: c.icon,
                ))
            .toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Spending by Category', style: AppTypography.h3),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSizing.radiusXl),
                ),
                child: DonutChart(
                  segments: segments,
                  total: totalActual,
                  centerBuilder: (selectedIndex) {
                    if (selectedIndex == null ||
                        selectedIndex >= spendingCategories.length) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.trendingUp,
                            color: AppColors.savings,
                            size: 24,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$currencySymbol${totalActual.toStringAsFixed(0)}',
                            style: AppTypography.amountMedium,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'TOTAL',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.0,
                            ),
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
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$currencySymbol${category.totalActual.toStringAsFixed(0)}',
                          style: AppTypography.amountMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category.name.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.textMuted,
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
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSizing.radiusXl),
                ),
                child: StackedBarChart(
                  monthlyData: monthlyData,
                  currencySymbol: currencySymbol,
                  interactive: false,
                  height: 200,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
