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

  bool _isLightMode(BuildContext context) => NeoTheme.isLight(context);

  Color get _neoAppBg => _palette.appBg;
  Color get _neoSurface1 => _palette.surface1;
  Color get _neoSurface2 => _palette.surface2;
  Color get _neoStroke => _palette.stroke;
  Color get _neoTextPrimary => _palette.textPrimary;
  Color get _neoTextSecondary => _palette.textSecondary;
  Color get _neoAccent => _palette.accent;

  static const double _cardRadius = 16;
  static const double _sectionGap = 12;
  static const double _screenPadding = 16;

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final balancesAsync = ref.watch(accountBalancesProvider);
    final expenseCategoriesAsync = ref.watch(categoriesProvider);
    final incomeSourcesAsync = ref.watch(incomeSourcesProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      backgroundColor: _neoAppBg,
      body: _buildBackground(
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
              _screenPadding,
              0,
              _screenPadding,
              AppSpacing.xl + MediaQuery.paddingOf(context).bottom + 92,
            ),
            children: [
              const SizedBox(height: AppSpacing.sm),
              _buildHeader(),
              const SizedBox(height: _sectionGap),
              _buildAccountsCard(
                accountsAsync: accountsAsync,
                balancesAsync: balancesAsync,
                currencySymbol: currencySymbol,
              ),
              const SizedBox(height: _sectionGap),
              _buildExpenseCategoriesCard(
                categoriesAsync: expenseCategoriesAsync,
                currencySymbol: currencySymbol,
              ),
              const SizedBox(height: _sectionGap),
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
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Categories',
            style: NeoTypography.pageTitle(context),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Accounts, expense categories, and income categories',
            style: NeoTypography.pageContext(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground({required Widget child}) {
    final textureColor = _isLightMode(context)
        ? Colors.black.withValues(alpha: 0.018)
        : Colors.white.withValues(alpha: 0.025);
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_neoAppBg, _neoAppBg],
            ),
          ),
        ),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.85, -0.95),
                radius: 1.25,
                colors: [textureColor, Colors.transparent],
              ),
            ),
          ),
        ),
        child,
      ],
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
      onAdd: _showAddAccountSheet,
      addLabel: 'Add',
      addIcon: LucideIcons.plus,
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
                _HubRow(
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
      onAdd: _showAddExpenseCategorySheet,
      addLabel: 'Add',
      addIcon: LucideIcons.plus,
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
                _HubRow(
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
      onAdd: _showAddIncomeCategorySheet,
      addLabel: 'Add',
      addIcon: LucideIcons.plus,
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
                _HubRow(
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
    required VoidCallback onAdd,
    required String addLabel,
    required IconData addIcon,
    required Widget child,
  }) {
    return _glassCard(
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
              _buildSectionActionButton(
                label: addLabel,
                icon: addIcon,
                onPressed: onAdd,
              ),
              const SizedBox(width: 8),
              _buildSectionChevronButton(
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

  Widget _buildSectionActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final isLight = _isLightMode(context);
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: NeoIconSizes.sm, color: _neoAccent),
      label: Text(label, style: NeoTypography.sectionAction(context)),
      style: OutlinedButton.styleFrom(
        foregroundColor: _neoAccent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        backgroundColor:
            isLight ? _neoAccent.withValues(alpha: 0.10) : Colors.transparent,
        side: BorderSide(
          color: _neoAccent.withValues(alpha: isLight ? 0.55 : 0.4),
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        ),
      ),
    );
  }

  Widget _buildSectionChevronButton({
    required bool expanded,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppSizing.radiusFull),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: _neoSurface2,
          borderRadius: BorderRadius.circular(AppSizing.radiusFull),
          border: Border.all(color: _neoStroke),
        ),
        child: Icon(
          expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
          size: NeoIconSizes.md,
          color: _neoTextSecondary,
        ),
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
              color: _neoSurface2,
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
              backgroundColor: _neoAccent,
              foregroundColor:
                  _isLightMode(context) ? _neoTextPrimary : _neoSurface1,
            ),
            icon: const Icon(LucideIcons.plus, size: NeoIconSizes.md),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  Widget _glassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(AppSpacing.md),
  }) {
    final shadowColor = _isLightMode(context)
        ? Colors.black.withValues(alpha: 0.14)
        : _neoAppBg.withValues(alpha: 0.86);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _neoSurface1,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: _neoStroke),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
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
        return _neoAccent;
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
    final icons = <String, IconData>{
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
    return icons[iconName] ?? LucideIcons.wallet;
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

class _HubRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String trailingTop;
  final String trailingBottom;
  final Color trailingColor;
  final VoidCallback onTap;

  const _HubRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailingTop,
    required this.trailingBottom,
    required this.trailingColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
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
                icon,
                size: NeoIconSizes.lg,
                color: iconColor,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: NeoTypography.rowTitle(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: NeoTypography.rowSecondary(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  trailingTop,
                  style: NeoTypography.rowAmount(context, trailingColor),
                ),
                const SizedBox(height: 2),
                Text(
                  trailingBottom,
                  style: NeoTypography.rowSecondary(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
