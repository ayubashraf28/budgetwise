import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../models/category.dart';
import '../../models/month.dart';
import '../../providers/providers.dart';
import '../../utils/app_icon_registry.dart';
import '../../widgets/budget/progress_bar.dart';
import '../../widgets/common/neo_page_components.dart';
import '../expenses/category_form_sheet.dart';

class BudgetOverviewScreen extends ConsumerStatefulWidget {
  const BudgetOverviewScreen({super.key});

  @override
  ConsumerState<BudgetOverviewScreen> createState() =>
      _BudgetOverviewScreenState();
}

class _BudgetOverviewScreenState extends ConsumerState<BudgetOverviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(ensureMonthSetupProvider.future);

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
    final selectedMonthId = ref.watch(budgetSelectedMonthIdProvider);

    if (selectedMonthId == null) {
      return Scaffold(
        backgroundColor: palette.appBg,
        body: const NeoPageBackground(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final categoriesAsync =
        ref.watch(categoriesForMonthProvider(selectedMonthId));
    final monthsAsync = ref.watch(userMonthsProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final monthLabel = _resolveMonthLabel(monthsAsync, selectedMonthId);

    return Scaffold(
      backgroundColor: palette.appBg,
      body: NeoPageBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userMonthsProvider);
            ref.invalidate(categoriesForMonthProvider(selectedMonthId));
          },
          child: categoriesAsync.when(
            data: (categoryList) {
              final sortedCategories = [...categoryList]..sort((a, b) =>
                  a.name.toLowerCase().compareTo(b.name.toLowerCase()));
              final budgetedCategories = sortedCategories
                  .where((category) => category.hasBudget)
                  .toList();
              final notBudgetedCategories = sortedCategories
                  .where((category) => !category.hasBudget)
                  .toList();

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildPageHeader(monthLabel),
                  ),
                  if (categoryList.isEmpty)
                    SliverToBoxAdapter(
                      child: _buildNoCategoriesState(),
                    )
                  else ...[
                    SliverToBoxAdapter(
                      child: _buildSectionHeader(
                        'Budgeted categories: $monthLabel',
                      ),
                    ),
                    if (budgetedCategories.isEmpty)
                      SliverToBoxAdapter(
                        child: _buildNoBudgetedState(),
                      )
                    else
                      SliverToBoxAdapter(
                        child: _buildBudgetedList(
                          budgetedCategories,
                          currencySymbol,
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: _buildSectionHeader('Not budgeted this month'),
                    ),
                    if (notBudgetedCategories.isEmpty)
                      SliverToBoxAdapter(
                        child: _buildAllBudgetedState(),
                      )
                    else
                      SliverToBoxAdapter(
                        child: _buildNotBudgetedList(
                          notBudgetedCategories,
                          currencySymbol,
                        ),
                      ),
                  ],
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

  Widget _buildPageHeader(String monthLabel) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        NeoLayout.screenPadding,
        0,
        NeoLayout.screenPadding,
        AppSpacing.sm,
      ),
      child: NeoPageHeader(
        title: 'Budget Setup',
        subtitle: 'Set monthly limits for $monthLabel',
      ),
    );
  }

  Widget _buildSectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Text(text, style: AppTypography.h3),
    );
  }

  Widget _buildBudgetedList(
    List<Category> categories,
    String currencySymbol,
  ) {
    return Column(
      children: categories.map((category) {
        return Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.sm,
          ),
          child: _buildBudgetedCategoryCard(
            category: category,
            currencySymbol: currencySymbol,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBudgetedCategoryCard({
    required Category category,
    required String currencySymbol,
  }) {
    final palette = NeoTheme.of(context);
    final remaining = category.remaining;
    final remainingColor = remaining >= 0
        ? NeoTheme.positiveValue(context)
        : NeoTheme.negativeValue(context);
    final progressColor = category.isOverBudget
        ? NeoTheme.negativeValue(context)
        : NeoTheme.positiveValue(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/budget/category/${category.id}'),
        onLongPress: () => _showEditSheet(category),
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        child: Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: palette.surface1,
            borderRadius: BorderRadius.circular(AppSizing.radiusLg),
            border: Border.all(color: palette.stroke),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: category.colorValue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIcon(category.icon),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelLarge,
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    color: palette.textMuted,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildMetricRow(
                label: 'Limit',
                value:
                    '$currencySymbol${_formatAmount(category.totalProjected)}',
              ),
              const SizedBox(height: 2),
              _buildMetricRow(
                label: 'Spent',
                value: '$currencySymbol${_formatAmount(category.totalActual)}',
              ),
              const SizedBox(height: 2),
              _buildMetricRow(
                label: 'Remaining',
                value:
                    '${remaining < 0 ? '-' : ''}$currencySymbol${_formatAmount(remaining.abs())}',
                valueColor: remainingColor,
              ),
              const SizedBox(height: AppSpacing.sm),
              BudgetProgressBar(
                projected: category.totalProjected,
                actual: category.totalActual,
                color: progressColor,
                backgroundColor: palette.stroke.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricRow({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final palette = NeoTheme.of(context);
    return Row(
      children: [
        Text(
          '$label: ',
          style:
              AppTypography.bodyMedium.copyWith(color: palette.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              color: valueColor ?? palette.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildNotBudgetedList(
    List<Category> categories,
    String currencySymbol,
  ) {
    return Column(
      children: categories.map((category) {
        return Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.sm,
          ),
          child: _buildNotBudgetedRow(
            category: category,
            currencySymbol: currencySymbol,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotBudgetedRow({
    required Category category,
    required String currencySymbol,
  }) {
    final palette = NeoTheme.of(context);
    final helperText = category.isBudgeted
        ? 'No limit set yet'
        : 'Budgeting is currently disabled';

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        border: Border.all(color: palette.stroke),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: category.colorValue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIcon(category.icon),
              color: Colors.white,
              size: 19,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  '$helperText - Spent $currencySymbol${_formatAmount(category.totalActual)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          OutlinedButton(
            onPressed: () => _setBudget(category),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              side: BorderSide(
                color: palette.accent.withValues(alpha: 0.45),
              ),
              foregroundColor: palette.accent,
              textStyle: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizing.radiusSm),
              ),
            ),
            child: const Text('Set budget'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoCategoriesState() {
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
            'No categories yet',
            style: AppTypography.h3,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Create categories in Expenses first, then set their budgets here.',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoBudgetedState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: NeoTheme.of(context).surface1,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        border: Border.all(color: NeoTheme.of(context).stroke),
      ),
      child: Text(
        'No categories have a budget limit yet. Use "Set budget" below.',
        style: AppTypography.bodyMedium.copyWith(
          color: NeoTheme.of(context).textSecondary,
        ),
      ),
    );
  }

  Widget _buildAllBudgetedState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: NeoTheme.of(context).surface1,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        border: Border.all(color: NeoTheme.of(context).stroke),
      ),
      child: Text(
        'All categories are budgeted for this month.',
        style: AppTypography.bodyMedium.copyWith(
          color: NeoTheme.of(context).textSecondary,
        ),
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
            Icon(
              LucideIcons.alertCircle,
              size: 48,
              color: NeoTheme.negativeValue(context),
            ),
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

  String _resolveMonthLabel(
    AsyncValue<List<Month>> monthsAsync,
    String selectedMonthId,
  ) {
    final months = monthsAsync.valueOrNull;
    if (months == null || months.isEmpty) {
      return DateFormat('MMM, y').format(DateTime.now());
    }

    for (final month in months) {
      if (month.id == selectedMonthId) {
        return DateFormat('MMM, y').format(month.startDate);
      }
    }

    return DateFormat('MMM, y').format(DateTime.now());
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return NumberFormat('#,##,###').format(amount.toInt());
    }
    return amount.toStringAsFixed(amount == amount.roundToDouble() ? 0 : 2);
  }

  IconData _getIcon(String iconName) {
    return resolveAppIcon(iconName, fallback: LucideIcons.wallet);
  }

  void _setBudget(Category category) {
    _showEditSheet(category);
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
