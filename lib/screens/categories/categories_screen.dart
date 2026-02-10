import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../models/account.dart';
import '../../models/category.dart';
import '../../models/income_source.dart';
import '../../providers/providers.dart';
import '../../utils/app_icon_registry.dart';
import '../../widgets/common/neo_page_components.dart';
import '../expenses/category_form_sheet.dart';
import '../income/income_form_sheet.dart';
import '../settings/account_form_sheet.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  bool _isAccountsExpanded = true;
  bool _isExpenseExpanded = true;
  bool _isIncomeExpanded = true;

  NeoPalette get _palette => NeoTheme.of(context);

  Color get _neoAppBg => _palette.appBg;
  Color get _neoStroke => _palette.stroke;
  Color get _neoTextPrimary => _palette.textPrimary;
  Color get _neoTextSecondary => _palette.textSecondary;

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final balancesAsync = ref.watch(accountBalancesProvider);
    final expenseCategoriesAsync = ref.watch(categoriesProvider);
    final incomeSourcesAsync = ref.watch(incomeSourcesProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      backgroundColor: _neoAppBg,
      body: NeoPageBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(accountsProvider);
            ref.invalidate(allAccountsProvider);
            ref.invalidate(accountBalancesProvider);
            ref.invalidate(allAccountBalancesProvider);
            ref.invalidate(categoriesProvider);
            ref.invalidate(incomeSourcesProvider);
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
              _buildHeader(),
              const SizedBox(height: NeoLayout.sectionGap),
              _buildAccountsCard(
                accountsAsync: accountsAsync,
                balancesAsync: balancesAsync,
                currencySymbol: currencySymbol,
              ),
              const SizedBox(height: NeoLayout.sectionGap),
              _buildExpenseCategoriesCard(
                categoriesAsync: expenseCategoriesAsync,
                currencySymbol: currencySymbol,
              ),
              const SizedBox(height: NeoLayout.sectionGap),
              _buildIncomeCategoriesCard(
                incomeSourcesAsync: incomeSourcesAsync,
                currencySymbol: currencySymbol,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const NeoPageHeader(
      title: 'Categories',
      subtitle: 'Accounts, expense categories, and income categories',
    );
  }

  Widget _buildAccountsCard({
    required AsyncValue<List<Account>> accountsAsync,
    required AsyncValue<Map<String, double>> balancesAsync,
    required String currencySymbol,
  }) {
    return _buildSectionCard(
      title: 'Accounts',
      expanded: _isAccountsExpanded,
      onToggle: () =>
          setState(() => _isAccountsExpanded = !_isAccountsExpanded),
      onViewAll: () => context.push('/settings/accounts'),
      onAdd: _showAddAccountSheet,
      child: accountsAsync.when(
        data: (accounts) {
          final balances =
              balancesAsync.valueOrNull ?? const <String, double>{};
          if (accounts.isEmpty) {
            return _buildEmptySection(
              icon: LucideIcons.wallet,
              title: 'No accounts yet',
              subtitle: 'Create your first account to start tracking balances.',
              actionLabel: 'Add account',
              onAction: _showAddAccountSheet,
            );
          }

          return Column(
            children: [
              for (var index = 0; index < accounts.length; index++) ...[
                NeoHubRow(
                  icon: _accountTypeIcon(accounts[index].type),
                  iconColor: _accountTypeColor(accounts[index].type),
                  title: accounts[index].name,
                  subtitle: _accountTypeLabel(accounts[index].type),
                  trailingTop:
                      '$currencySymbol${_formatAmount(balances[accounts[index].id] ?? 0)}',
                  trailingBottom:
                      accounts[index].isArchived ? 'Archived' : 'Active',
                  trailingColor: (balances[accounts[index].id] ?? 0) < 0
                      ? NeoTheme.negativeValue(context)
                      : NeoTheme.positiveValue(context),
                  onTap: () => context.push(
                    '/settings/accounts?accountId=${Uri.encodeComponent(accounts[index].id)}',
                  ),
                ),
                if (index < accounts.length - 1)
                  Divider(
                    height: 16,
                    color: _neoStroke.withValues(alpha: 0.85),
                  ),
              ],
            ],
          );
        },
        loading: () => _buildLoadingSection(),
        error: (error, _) => _buildErrorSection(error.toString()),
      ),
    );
  }

  Widget _buildExpenseCategoriesCard({
    required AsyncValue<List<Category>> categoriesAsync,
    required String currencySymbol,
  }) {
    return _buildSectionCard(
      title: 'Expense Categories',
      expanded: _isExpenseExpanded,
      onToggle: () => setState(() => _isExpenseExpanded = !_isExpenseExpanded),
      onViewAll: () => context.push('/budget'),
      onAdd: _showAddExpenseCategorySheet,
      child: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return _buildEmptySection(
              icon: LucideIcons.pieChart,
              title: 'No expense categories yet',
              subtitle: 'Add categories to organize budget and spending.',
              actionLabel: 'Add expense category',
              onAction: _showAddExpenseCategorySheet,
            );
          }

          final sorted = [...categories]
            ..sort((a, b) => b.totalActual.compareTo(a.totalActual));

          return Column(
            children: [
              for (var index = 0; index < sorted.length; index++) ...[
                NeoHubRow(
                  icon: _categoryIcon(sorted[index].icon),
                  iconColor: sorted[index].colorValue,
                  title: sorted[index].name,
                  subtitle:
                      '${sorted[index].itemCount} item${sorted[index].itemCount == 1 ? '' : 's'}',
                  trailingTop:
                      '$currencySymbol${_formatAmount(sorted[index].totalActual)}',
                  trailingBottom:
                      sorted[index].isBudgeted ? 'Budgeted' : 'No budget',
                  trailingColor: sorted[index].isOverBudget
                      ? NeoTheme.negativeValue(context)
                      : sorted[index].totalActual > 0
                          ? NeoTheme.warningValue(context)
                          : _neoTextSecondary,
                  onTap: () =>
                      context.push('/budget/category/${sorted[index].id}'),
                ),
                if (index < sorted.length - 1)
                  Divider(
                    height: 16,
                    color: _neoStroke.withValues(alpha: 0.85),
                  ),
              ],
            ],
          );
        },
        loading: () => _buildLoadingSection(),
        error: (error, _) => _buildErrorSection(error.toString()),
      ),
    );
  }

  Widget _buildIncomeCategoriesCard({
    required AsyncValue<List<IncomeSource>> incomeSourcesAsync,
    required String currencySymbol,
  }) {
    return _buildSectionCard(
      title: 'Income Categories',
      expanded: _isIncomeExpanded,
      onToggle: () => setState(() => _isIncomeExpanded = !_isIncomeExpanded),
      onViewAll: () => context.push('/income'),
      onAdd: _showAddIncomeCategorySheet,
      child: incomeSourcesAsync.when(
        data: (incomeSources) {
          if (incomeSources.isEmpty) {
            return _buildEmptySection(
              icon: LucideIcons.trendingUp,
              title: 'No income categories yet',
              subtitle: 'Add sources to track expected and actual income.',
              actionLabel: 'Add income category',
              onAction: _showAddIncomeCategorySheet,
            );
          }

          final sorted = [...incomeSources]
            ..sort((a, b) => b.actual.compareTo(a.actual));

          return Column(
            children: [
              for (var index = 0; index < sorted.length; index++) ...[
                NeoHubRow(
                  icon: LucideIcons.trendingUp,
                  iconColor: NeoTheme.positiveValue(context),
                  title: sorted[index].name,
                  subtitle:
                      sorted[index].isRecurring ? 'Recurring' : 'One-time',
                  trailingTop:
                      '$currencySymbol${_formatAmount(sorted[index].actual)}',
                  trailingBottom: sorted[index].isRecurring
                      ? 'Projected $currencySymbol${_formatAmount(sorted[index].projected)}'
                      : 'Actual received',
                  trailingColor: NeoTheme.positiveValue(context),
                  onTap: () => context.push('/income'),
                ),
                if (index < sorted.length - 1)
                  Divider(
                    height: 16,
                    color: _neoStroke.withValues(alpha: 0.85),
                  ),
              ],
            ],
          );
        },
        loading: () => _buildLoadingSection(),
        error: (error, _) => _buildErrorSection(error.toString()),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        'Failed to load: $error',
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.error,
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
              border: Border.all(color: _neoStroke),
            ),
            child: Icon(
              icon,
              color: _neoTextSecondary,
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
                  ? _neoTextPrimary
                  : _palette.surface1,
            ),
            icon: const Icon(LucideIcons.plus, size: NeoIconSizes.md),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  IconData _accountTypeIcon(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return LucideIcons.wallet;
      case AccountType.debit:
        return LucideIcons.creditCard;
      case AccountType.credit:
        return LucideIcons.landmark;
      case AccountType.savings:
        return LucideIcons.piggyBank;
      case AccountType.other:
        return LucideIcons.circleDollarSign;
    }
  }

  Color _accountTypeColor(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return _palette.accent;
      case AccountType.debit:
        return NeoTheme.infoValue(context);
      case AccountType.credit:
        return NeoTheme.warningValue(context);
      case AccountType.savings:
        return NeoTheme.positiveValue(context);
      case AccountType.other:
        return _neoTextSecondary;
    }
  }

  String _accountTypeLabel(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return 'Cash';
      case AccountType.debit:
        return 'Debit';
      case AccountType.credit:
        return 'Credit';
      case AccountType.savings:
        return 'Savings';
      case AccountType.other:
        return 'Other';
    }
  }

  IconData _categoryIcon(String iconName) {
    return resolveAppIcon(iconName, fallback: LucideIcons.wallet);
  }

  String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return NumberFormat('#,##0').format(amount);
    }
    return NumberFormat('#,##0.##').format(amount);
  }

  Future<void> _showAddAccountSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AccountFormSheet(),
    );
  }

  Future<void> _showAddExpenseCategorySheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CategoryFormSheet(),
    );
  }

  Future<void> _showAddIncomeCategorySheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const IncomeFormSheet(),
    );
  }
}
