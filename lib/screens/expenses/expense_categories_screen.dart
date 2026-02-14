import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../models/category.dart';
import '../../models/transaction.dart';
import '../../providers/providers.dart';
import '../../utils/app_icon_registry.dart';
import '../../widgets/budget/budget_widgets.dart';
import '../../widgets/common/neo_page_components.dart';
import 'category_form_sheet.dart';

class ExpenseCategoriesScreen extends ConsumerWidget {
  const ExpenseCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = NeoTheme.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    final totalProjected = ref.watch(totalProjectedExpensesProvider);
    final totalActual = ref.watch(totalActualExpensesProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final isSimpleMode = ref.watch(isSimpleBudgetModeProvider);
    final monthTx = ref.watch(transactionsProvider).valueOrNull ?? [];
    final expenseTransactions =
        monthTx.where((t) => t.type == TransactionType.expense).toList();
    final txCountByCategory = <String, int>{};
    for (final tx in expenseTransactions) {
      final categoryId = tx.categoryId;
      if (categoryId != null) {
        txCountByCategory[categoryId] =
            (txCountByCategory[categoryId] ?? 0) + 1;
      }
    }

    return Scaffold(
      backgroundColor: palette.appBg,
      body: NeoPageBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(categoriesProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    NeoLayout.screenPadding,
                    0,
                    NeoLayout.screenPadding,
                    AppSpacing.sm,
                  ),
                  child: _buildHeader(context),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: NeoLayout.screenPadding,
                  ),
                  child: _buildSummaryCard(
                    context,
                    totalProjected,
                    totalActual,
                    currencySymbol,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    NeoLayout.screenPadding,
                    NeoLayout.sectionGap,
                    NeoLayout.screenPadding,
                    AppSpacing.sm,
                  ),
                  child: const AdaptiveHeadingText(
                    text: 'Expense Categories',
                  ),
                ),
              ),
              ...categoriesAsync.when(
                data: (categories) {
                  if (categories.isEmpty) {
                    return <Widget>[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: NeoLayout.screenPadding,
                          ),
                          child: _buildEmptyState(context, ref),
                        ),
                      ),
                    ];
                  }

                  final sorted = [...categories]
                    ..sort((a, b) => b.totalActual.compareTo(a.totalActual));

                  return <Widget>[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          NeoLayout.screenPadding,
                          0,
                          NeoLayout.screenPadding,
                          AppSpacing.sm,
                        ),
                        child: _buildAddExpenseCategoryRow(
                          context: context,
                          onTap: () => _showAddSheet(context),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: NeoLayout.screenPadding,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final category = sorted[index];
                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: _buildCategoryCard(
                                context,
                                ref,
                                category,
                                currencySymbol,
                                isSimpleMode: isSimpleMode,
                                transactionCount:
                                    txCountByCategory[category.id] ?? 0,
                              ),
                            );
                          },
                          childCount: sorted.length,
                        ),
                      ),
                    ),
                  ];
                },
                loading: () => <Widget>[
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 280,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                ],
                error: (error, stack) => <Widget>[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: NeoLayout.screenPadding,
                      ),
                      child: _buildErrorState(context, error.toString()),
                    ),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: AppSpacing.xl +
                      MediaQuery.paddingOf(context).bottom +
                      NeoLayout.bottomNavSafeBuffer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expense Categories',
                  style: NeoTypography.pageTitle(context),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Track budgeted and actual spending by category',
                  style: NeoTypography.pageContext(context),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: NeoSettingsHeaderButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddExpenseCategoryRow({
    required BuildContext context,
    required VoidCallback onTap,
  }) {
    final addColor = NeoTheme.positiveValue(context);
    final borderColor = NeoTheme.of(context).stroke;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        child: Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizing.radiusLg),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.plus, color: addColor, size: NeoIconSizes.lg),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Add Expense Category',
                style: AppTypography.bodyLarge.copyWith(
                  color: addColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    double totalProjected,
    double totalActual,
    String currencySymbol,
  ) {
    final difference = totalProjected - totalActual;
    final isWithinBudget = difference >= 0;
    final deltaColor = isWithinBudget
        ? NeoTheme.positiveValue(context)
        : NeoTheme.negativeValue(context);

    Widget summaryRow(String label, double amount) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: NeoTypography.rowSecondary(context)),
          Text(
            '$currencySymbol${_formatAmount(amount)}',
            style: NeoTypography.rowAmount(
              context,
              NeoTheme.of(context).textPrimary,
            ),
          ),
        ],
      );
    }

    return NeoGlassCard(
      child: Column(
        children: [
          summaryRow('Total budgeted', totalProjected),
          const SizedBox(height: AppSpacing.sm),
          summaryRow('Total spent', totalActual),
          Divider(
            height: AppSpacing.lg,
            color: NeoTheme.of(context).stroke.withValues(alpha: 0.85),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Difference', style: NeoTypography.cardTitle(context)),
              Row(
                children: [
                  Icon(
                    isWithinBudget
                        ? LucideIcons.trendingDown
                        : LucideIcons.trendingUp,
                    size: NeoIconSizes.md,
                    color: deltaColor,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${isWithinBudget ? '+' : '-'}$currencySymbol${_formatAmount(difference.abs())}',
                    style: NeoTypography.rowAmount(context, deltaColor),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    WidgetRef ref,
    Category category,
    String currencySymbol, {
    required bool isSimpleMode,
    required int transactionCount,
  }) {
    final palette = NeoTheme.of(context);

    return Dismissible(
      key: Key(category.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        decoration: BoxDecoration(
          color: NeoTheme.negativeValue(context),
          borderRadius: BorderRadius.circular(NeoLayout.cardRadius),
        ),
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      confirmDismiss: (direction) => _showDeleteConfirmation(context),
      onDismissed: (direction) {
        ref.read(categoryNotifierProvider.notifier).deleteCategory(category.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${category.name} deleted')),
        );
      },
      child: InkWell(
        onTap: () => context.push('/budget/category/${category.id}'),
        borderRadius: BorderRadius.circular(NeoLayout.cardRadius),
        child: NeoGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: palette.surface2,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: palette.stroke),
                    ),
                    child: Icon(
                      _categoryIcon(category.icon),
                      size: NeoIconSizes.lg,
                      color: category.colorValue,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      category.name,
                      style: NeoTypography.rowTitle(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusBadge(context, category),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                category.isBudgeted
                    ? '$currencySymbol${_formatAmount(category.totalActual)} / $currencySymbol${_formatAmount(category.totalProjected)}'
                    : '$currencySymbol${_formatAmount(category.totalActual)}',
                style: NeoTypography.rowSecondary(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                isSimpleMode
                    ? '$transactionCount ${transactionCount == 1 ? 'transaction' : 'transactions'}'
                    : '${category.itemCount} item${category.itemCount == 1 ? '' : 's'}',
                style: NeoTypography.rowSecondary(context),
              ),
              if (category.isBudgeted) ...[
                const SizedBox(height: AppSpacing.sm),
                BudgetProgressBar(
                  projected: category.totalProjected,
                  actual: category.totalActual,
                  color: category.isOverBudget
                      ? NeoTheme.negativeValue(context)
                      : NeoTheme.positiveValue(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, Category category) {
    String label;
    Color color;

    if (!category.isBudgeted) {
      label = 'No budget';
      color = NeoTheme.of(context).textMuted;
    } else if (category.totalProjected <= 0) {
      label = category.totalActual > 0 ? 'Unplanned' : 'No budget';
      color = category.totalActual > 0
          ? NeoTheme.warningValue(context)
          : NeoTheme.of(context).textMuted;
    } else if (category.isOverBudget) {
      label = 'Over budget';
      color = NeoTheme.negativeValue(context);
    } else if (category.totalActual == 0) {
      label = 'No spend';
      color = NeoTheme.of(context).textMuted;
    } else if (category.isOnBudget) {
      label = 'On budget';
      color = NeoTheme.positiveValue(context);
    } else {
      label = 'On track';
      color = NeoTheme.positiveValue(context);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSizing.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final palette = NeoTheme.of(context);
    return NeoGlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: palette.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.stroke),
              ),
              child: Icon(
                LucideIcons.pieChart,
                size: NeoIconSizes.xl,
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No expense categories yet',
              style: NeoTypography.rowTitle(context),
            ),
            const SizedBox(height: 2),
            Text(
              'Add your first expense category to start tracking.',
              style: NeoTypography.rowSecondary(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: () => _showAddSheet(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: NeoTheme.isLight(context)
                    ? palette.textPrimary
                    : palette.surface1,
              ),
              icon: const Icon(LucideIcons.plus, size: NeoIconSizes.md),
              label: const Text('Add expense category'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final danger = NeoTheme.negativeValue(context);
    return NeoGlassCard(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: danger.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: danger.withValues(alpha: 0.35)),
        ),
        child: Text(
          'Failed to load expense categories: $error',
          style: AppTypography.bodySmall.copyWith(color: danger),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return NumberFormat('#,##0').format(amount);
    }
    return NumberFormat('#,##0.##').format(amount);
  }

  IconData _categoryIcon(String iconName) {
    return resolveAppIcon(iconName, fallback: LucideIcons.wallet);
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CategoryFormSheet(),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    final palette = NeoTheme.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: palette.surface1,
            title: Text(
              'Delete Category?',
              style: AppTypography.h3.copyWith(color: palette.textPrimary),
            ),
            content: Text(
              'This action cannot be undone.',
              style: AppTypography.bodyMedium.copyWith(
                color: palette.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: NeoTheme.negativeValue(context),
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
