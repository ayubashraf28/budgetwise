import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../models/category.dart';
import '../../models/subscription.dart';
import '../../providers/providers.dart';
import '../../utils/app_icon_registry.dart';
import '../../widgets/common/neo_page_components.dart';
import '../expenses/category_form_sheet.dart';
import '../subscriptions/subscription_form_sheet.dart';

class ManageScreen extends ConsumerStatefulWidget {
  const ManageScreen({super.key});

  @override
  ConsumerState<ManageScreen> createState() => _ManageScreenState();
}

class _ManageScreenState extends ConsumerState<ManageScreen> {
  NeoPalette get _palette => NeoTheme.of(context);

  @override
  Widget build(BuildContext context) {
    final subscriptionsAsync = ref.watch(subscriptionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final dueSoonCount = ref.watch(dueSoonCountProvider);
    final monthlySubscriptionCost = ref.watch(totalSubscriptionCostProvider);
    final totalProjected = ref.watch(totalProjectedExpensesProvider);
    final totalActual = ref.watch(totalActualExpensesProvider);
    final overBudgetCount = ref.watch(overBudgetCountProvider);
    final budgetHealth = ref.watch(budgetHealthProvider);
    final isSubscriptionsExpanded =
        ref.watch(uiSectionExpandedProvider(UiSectionKeys.manageSubscriptions));
    final isBudgetsExpanded =
        ref.watch(uiSectionExpandedProvider(UiSectionKeys.manageBudgets));

    return Scaffold(
      backgroundColor: _palette.appBg,
      body: NeoPageBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(subscriptionsProvider);
            ref.invalidate(upcomingSubscriptionsProvider);
            ref.invalidate(categoriesProvider);
            ref.invalidate(totalProjectedExpensesProvider);
            ref.invalidate(totalActualExpensesProvider);
            ref.invalidate(overBudgetCountProvider);
            ref.invalidate(budgetHealthProvider);
          },
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              NeoLayout.screenPadding,
              0,
              NeoLayout.screenPadding,
              AppSpacing.xl +
                  MediaQuery.paddingOf(context).bottom +
                  NeoLayout.bottomNavSafeBuffer,
            ),
            children: [
              const SizedBox(height: AppSpacing.sm),
              const NeoPageHeader(
                title: 'Manage',
                subtitle: 'Subscriptions and budgets with inline details',
              ),
              const SizedBox(height: NeoLayout.sectionGap),
              _buildSectionCard(
                title: 'Subscriptions',
                expanded: isSubscriptionsExpanded,
                onToggle: () =>
                    ref.read(uiPreferencesProvider.notifier).setSectionExpanded(
                          UiSectionKeys.manageSubscriptions,
                          !isSubscriptionsExpanded,
                        ),
                onViewAll: () => context.push('/subscriptions'),
                onAdd: _showAddSubscriptionSheet,
                child: _buildSubscriptionsContent(
                  subscriptionsAsync: subscriptionsAsync,
                  dueSoonCount: dueSoonCount,
                  monthlySubscriptionCost: monthlySubscriptionCost,
                  currencySymbol: currencySymbol,
                ),
              ),
              const SizedBox(height: NeoLayout.sectionGap),
              _buildSectionCard(
                title: 'Budgets',
                expanded: isBudgetsExpanded,
                onToggle: () =>
                    ref.read(uiPreferencesProvider.notifier).setSectionExpanded(
                          UiSectionKeys.manageBudgets,
                          !isBudgetsExpanded,
                        ),
                onViewAll: () => context.push('/budget'),
                onAdd: _showAddBudgetCategorySheet,
                child: _buildBudgetsContent(
                  categoriesAsync: categoriesAsync,
                  budgetHealth: budgetHealth,
                  totalProjected: totalProjected,
                  totalActual: totalActual,
                  overBudgetCount: overBudgetCount,
                  currencySymbol: currencySymbol,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required bool expanded,
    required VoidCallback onToggle,
    required VoidCallback onViewAll,
    required VoidCallback onAdd,
    required Widget child,
  }) {
    return NeoGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: NeoTypography.sectionTitle(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              NeoSectionActionButton(
                label: 'View all',
                onPressed: onViewAll,
              ),
              const SizedBox(width: 8),
              NeoCircleIconButton(
                icon: LucideIcons.plus,
                onPressed: onAdd,
                semanticLabel: 'Add $title',
              ),
              const SizedBox(width: 8),
              NeoSectionChevronButton(
                expanded: expanded,
                onPressed: onToggle,
              ),
            ],
          ),
          if (expanded) ...[
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ],
      ),
    );
  }

  Widget _buildSubscriptionsContent({
    required AsyncValue<List<Subscription>> subscriptionsAsync,
    required int dueSoonCount,
    required double monthlySubscriptionCost,
    required String currencySymbol,
  }) {
    return subscriptionsAsync.when(
      data: (subscriptions) {
        if (subscriptions.isEmpty) {
          return _buildEmptySection(
            icon: LucideIcons.repeat,
            title: 'No subscriptions yet',
            subtitle: 'Add recurring services to track upcoming bills.',
            actionLabel: 'Add subscription',
            onAction: _showAddSubscriptionSheet,
          );
        }

        final active = subscriptions.where((sub) => sub.isActive).toList()
          ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
        final visible = active.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$dueSoonCount due soon • ~$currencySymbol${_formatAmount(monthlySubscriptionCost)}/month',
              style: NeoTypography.rowSecondary(context),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < visible.length; i++) ...[
              NeoHubRow(
                icon: _subscriptionIcon(visible[i].icon),
                iconColor: visible[i].colorValue,
                title: visible[i].name,
                subtitle:
                    '${visible[i].billingCycleLabel} • ${_dueDateLabel(visible[i])}',
                trailingTop:
                    '$currencySymbol${_formatAmount(visible[i].amount)}',
                trailingBottom: visible[i].status,
                trailingColor: _subscriptionStatusColor(visible[i]),
                onTap: () => context.push('/subscriptions'),
              ),
              if (i < visible.length - 1)
                Divider(
                  height: 16,
                  color: _palette.stroke.withValues(alpha: 0.85),
                ),
            ],
            if (active.length > visible.length) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '+${active.length - visible.length} more',
                style: NeoTypography.rowSecondary(context),
              ),
            ],
          ],
        );
      },
      loading: () => _buildLoadingSection(),
      error: (error, _) => _buildErrorSection(error.toString()),
    );
  }

  Widget _buildBudgetsContent({
    required AsyncValue<List<Category>> categoriesAsync,
    required String budgetHealth,
    required double totalProjected,
    required double totalActual,
    required int overBudgetCount,
    required String currencySymbol,
  }) {
    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return _buildEmptySection(
            icon: LucideIcons.pieChart,
            title: 'No budget categories yet',
            subtitle: 'Add expense categories to start tracking your budget.',
            actionLabel: 'Add budget category',
            onAction: _showAddBudgetCategorySheet,
          );
        }

        final sorted = [...categories]..sort((a, b) {
            if (a.isOverBudget == b.isOverBudget) {
              return b.totalActual.compareTo(a.totalActual);
            }
            return a.isOverBudget ? -1 : 1;
          });
        final visible = sorted.take(5).toList();

        final healthLabel = switch (budgetHealth) {
          'excellent' => 'Excellent',
          'good' => 'Good',
          'warning' => 'Warning',
          'critical' => 'Critical',
          _ => 'Good',
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$healthLabel • $overBudgetCount over budget • $currencySymbol${_formatAmount(totalActual)} / $currencySymbol${_formatAmount(totalProjected)}',
              style: NeoTypography.rowSecondary(context),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < visible.length; i++) ...[
              NeoHubRow(
                icon: _categoryIcon(visible[i].icon),
                iconColor: visible[i].colorValue,
                title: visible[i].name,
                subtitle: visible[i].isBudgeted
                    ? '${_budgetProgressLabel(visible[i])} • ${visible[i].itemCount} item${visible[i].itemCount == 1 ? '' : 's'}'
                    : '${visible[i].itemCount} item${visible[i].itemCount == 1 ? '' : 's'} • No budget',
                trailingTop:
                    '$currencySymbol${_formatAmount(visible[i].totalActual)}',
                trailingBottom: visible[i].isBudgeted
                    ? '$currencySymbol${_formatAmount(visible[i].totalProjected)} budget'
                    : 'Unbudgeted',
                trailingColor: visible[i].isOverBudget
                    ? NeoTheme.negativeValue(context)
                    : visible[i].totalActual > 0
                        ? NeoTheme.warningValue(context)
                        : _palette.textSecondary,
                onTap: () => context.push('/budget/category/${visible[i].id}'),
              ),
              if (i < visible.length - 1)
                Divider(
                  height: 16,
                  color: _palette.stroke.withValues(alpha: 0.85),
                ),
            ],
            if (sorted.length > visible.length) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '+${sorted.length - visible.length} more',
                style: NeoTypography.rowSecondary(context),
              ),
            ],
          ],
        );
      },
      loading: () => _buildLoadingSection(),
      error: (error, _) => _buildErrorSection(error.toString()),
    );
  }

  Widget _buildLoadingSection() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildErrorSection(String error) {
    final danger = NeoTheme.negativeValue(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: danger.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        'Failed to load: $error',
        style: AppTypography.bodySmall.copyWith(
          color: danger,
        ),
      ),
    );
  }

  Widget _buildEmptySection({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _palette.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _palette.stroke),
            ),
            child: Icon(
              icon,
              color: _palette.textSecondary,
              size: NeoIconSizes.xl,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: NeoTypography.rowTitle(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: NeoTypography.rowSecondary(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: _palette.accent,
              foregroundColor: NeoTheme.isLight(context)
                  ? _palette.textPrimary
                  : _palette.surface1,
            ),
            icon: const Icon(LucideIcons.plus, size: NeoIconSizes.md),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  Color _subscriptionStatusColor(Subscription sub) {
    if (!sub.isActive) return _palette.textSecondary;
    if (sub.isOverdue) return NeoTheme.negativeValue(context);
    if (sub.isDueSoon || sub.isDueToday) return NeoTheme.warningValue(context);
    return NeoTheme.positiveValue(context);
  }

  String _dueDateLabel(Subscription sub) {
    final date = DateFormat('MMM d').format(sub.nextDueDate);
    if (sub.isOverdue) return 'Overdue ($date)';
    if (sub.isDueToday) return 'Due today';
    if (sub.isDueSoon) return 'Due in ${sub.daysUntilDue}d';
    return 'Due $date';
  }

  String _budgetProgressLabel(Category category) {
    if (!category.isBudgeted || category.totalProjected <= 0) {
      return 'No budget';
    }
    final progress = (category.totalActual / category.totalProjected) * 100;
    return '${progress.toStringAsFixed(0)}% used';
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

  IconData _subscriptionIcon(String iconName) {
    return resolveAppIcon(iconName, fallback: LucideIcons.creditCard);
  }

  Future<void> _showAddSubscriptionSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SubscriptionFormSheet(),
    );
  }

  Future<void> _showAddBudgetCategorySheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CategoryFormSheet(),
    );
  }
}
