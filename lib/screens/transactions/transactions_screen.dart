import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../models/account.dart';
import '../../models/monthly_summary.dart';
import '../../models/transaction.dart';
import '../../providers/providers.dart';
import '../../utils/transaction_display_utils.dart';
import '../../widgets/budget/budget_widgets.dart';
import '../../widgets/common/neo_page_components.dart';
import 'transaction_form_sheet.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  final bool openComposerOnLoad;

  const TransactionsScreen({
    super.key,
    this.openComposerOnLoad = false,
  });

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  TransactionType? _filterType;
  String? _filterAccountId;

  NeoPalette get _palette => NeoTheme.of(context);

  @override
  void initState() {
    super.initState();
    if (widget.openComposerOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _showAddSheet();
        if (!mounted) return;

        final location = GoRouterState.of(context).matchedLocation;
        if (location == '/transactions/new') {
          context.go('/transactions');
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Transaction> _applyFilters(
    List<Transaction> transactions, {
    required bool isSimpleMode,
  }) {
    var filtered = transactions;

    if (_filterType != null) {
      filtered = filtered.where((t) => t.type == _filterType).toList();
    }

    if (_filterAccountId != null) {
      filtered =
          filtered.where((t) => t.accountId == _filterAccountId).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((t) {
        final name = transactionPrimaryLabel(
          t,
          isSimpleMode: isSimpleMode,
        ).toLowerCase();
        final category = (t.categoryName ?? '').toLowerCase();
        final account = (t.accountName ?? '').toLowerCase();
        final note = (t.note ?? '').toLowerCase();
        return name.contains(query) ||
            category.contains(query) ||
            account.contains(query) ||
            note.contains(query);
      }).toList();
    }

    return filtered;
  }

  Map<DateTime, List<Transaction>> _groupByDate(
      List<Transaction> transactions) {
    final grouped = <DateTime, List<Transaction>>{};
    for (final tx in transactions) {
      final key = DateTime(tx.date.year, tx.date.month, tx.date.day);
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (var key in sortedKeys) key: grouped[key]!};
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final summary = ref.watch(monthlySummaryProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final accounts = ref.watch(accountsProvider).value ?? <Account>[];
    final isSimpleMode = ref.watch(isSimpleBudgetModeProvider);

    return Scaffold(
      backgroundColor: _palette.appBg,
      body: NeoPageBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(transactionsProvider);
            ref.invalidate(incomeSourcesProvider);
            ref.invalidate(categoriesProvider);
            ref.invalidate(accountsProvider);
          },
          child: transactionsAsync.when(
            data: (transactions) {
              final filtered = _applyFilters(
                transactions,
                isSimpleMode: isSimpleMode,
              );
              final grouped = _groupByDate(filtered);

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: _buildSearchBar(accounts)),
                  SliverToBoxAdapter(
                    child: _buildSummaryCards(summary, currencySymbol),
                  ),
                  SliverToBoxAdapter(
                    child: _buildTransactionsHeader(filtered.length),
                  ),
                  if (filtered.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: NeoLayout.screenPadding,
                        ),
                        child: _buildEmptyState(),
                      ),
                    )
                  else
                    ..._buildGroupedTransactions(
                      grouped,
                      currencySymbol,
                      isSimpleMode: isSimpleMode,
                    ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: AppSpacing.xl +
                          MediaQuery.paddingOf(context).bottom +
                          NeoLayout.bottomNavSafeBuffer,
                    ),
                  ),
                ],
              );
            },
            loading: () => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 320),
                Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            error: (error, stack) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(NeoLayout.screenPadding),
              children: [
                _buildErrorState(error.toString()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        NeoLayout.screenPadding,
        0,
        NeoLayout.screenPadding,
        AppSpacing.sm,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transactions',
                    style: NeoTypography.pageTitle(context),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Search, filter, and manage activity by date',
                    style: NeoTypography.pageContext(context),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: NeoSettingsHeaderButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(List<Account> accounts) {
    final filterActive = _filterType != null || _filterAccountId != null;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: NeoLayout.screenPadding,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: NeoControlSizing.minHeight,
              decoration: BoxDecoration(
                color: _palette.surface2,
                borderRadius: BorderRadius.circular(NeoControlSizing.radius),
                border: Border.all(color: _palette.stroke),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: AppTypography.bodyMedium.copyWith(
                  color: _palette.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search by name, category, account, or note',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: _palette.textMuted,
                  ),
                  prefixIcon: Icon(
                    LucideIcons.search,
                    size: NeoIconSizes.md,
                    color: _palette.textMuted,
                  ),
                  filled: false,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          InkWell(
            onTap: () => _showFilterOptions(accounts),
            borderRadius: BorderRadius.circular(AppSizing.radiusMd),
            child: Container(
              width: NeoControlSizing.minHeight,
              height: NeoControlSizing.minHeight,
              decoration: BoxDecoration(
                color: filterActive
                    ? NeoTheme.controlSelectedBackground(context)
                    : _palette.surface2,
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                border: Border.all(
                  color: filterActive
                      ? NeoTheme.controlSelectedBorder(context)
                      : _palette.stroke,
                ),
              ),
              child: Icon(
                LucideIcons.slidersHorizontal,
                size: NeoIconSizes.lg,
                color: filterActive
                    ? NeoTheme.controlSelectedForeground(context)
                    : _palette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions(List<Account> accounts) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: NeoGlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _palette.stroke,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const AdaptiveHeadingText(
                    text: 'Filter transactions',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text('By type', style: NeoTypography.cardTitle(context)),
                  const SizedBox(height: AppSpacing.xs),
                  _buildFilterOption('All transactions', null),
                  _buildFilterOption('Income only', TransactionType.income),
                  _buildFilterOption('Expenses only', TransactionType.expense),
                  const SizedBox(height: AppSpacing.sm),
                  Divider(
                      color: _palette.stroke.withValues(alpha: 0.85),
                      height: 1),
                  const SizedBox(height: AppSpacing.sm),
                  Text('By account', style: NeoTypography.cardTitle(context)),
                  const SizedBox(height: AppSpacing.xs),
                  _buildAccountFilterOption(
                    label: 'All accounts',
                    accountId: null,
                  ),
                  ...accounts.map(
                    (account) => _buildAccountFilterOption(
                      label: account.name,
                      accountId: account.id,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String label, TransactionType? type) {
    final isSelected = _filterType == type;
    return ListTile(
      onTap: () {
        setState(() => _filterType = type);
        Navigator.pop(context);
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(
        isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
        color: isSelected
            ? NeoTheme.controlSelectedForeground(context)
            : _palette.textMuted,
        size: NeoIconSizes.lg,
      ),
      title: Text(
        label,
        style: AppTypography.bodyLarge.copyWith(
          color: isSelected ? _palette.textPrimary : _palette.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
      ),
    );
  }

  Widget _buildAccountFilterOption({
    required String label,
    required String? accountId,
  }) {
    final isSelected = _filterAccountId == accountId;
    return ListTile(
      onTap: () {
        setState(() => _filterAccountId = accountId);
        Navigator.pop(context);
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(
        isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
        color: isSelected
            ? NeoTheme.controlSelectedForeground(context)
            : _palette.textMuted,
        size: NeoIconSizes.lg,
      ),
      title: Text(
        label,
        style: AppTypography.bodyLarge.copyWith(
          color: isSelected ? _palette.textPrimary : _palette.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
      ),
    );
  }

  Widget _buildSummaryCards(MonthlySummary? summary, String currencySymbol) {
    final actualIncome = summary?.actualIncome ?? 0.0;
    final actualExpenses = summary?.actualExpenses ?? 0.0;
    final netBalance = summary?.actualBalance ?? 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        NeoLayout.screenPadding,
        AppSpacing.sm,
        NeoLayout.screenPadding,
        0,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Income',
                  amount: actualIncome,
                  currencySymbol: currencySymbol,
                  icon: LucideIcons.trendingUp,
                  color: NeoTheme.positiveValue(context),
                  onTap: () => context.push('/income'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildMetricCard(
                  title: 'Expenses',
                  amount: actualExpenses,
                  currencySymbol: currencySymbol,
                  icon: LucideIcons.trendingDown,
                  color: NeoTheme.negativeValue(context),
                  onTap: () => context.push('/expenses'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildMetricCard(
            title: 'Net balance',
            amount: netBalance,
            currencySymbol: currencySymbol,
            icon: LucideIcons.wallet,
            color: netBalance >= 0
                ? NeoTheme.positiveValue(context)
                : NeoTheme.negativeValue(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required double amount,
    required String currencySymbol,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    final content = Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _palette.surface2,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: _palette.stroke),
          ),
          child: Icon(icon, size: NeoIconSizes.lg, color: color),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: NeoTypography.rowSecondary(context)),
              const SizedBox(height: 2),
              Text(
                '$currencySymbol${_formatAmount(amount)}',
                style: NeoTypography.rowAmount(context, color),
              ),
            ],
          ),
        ),
      ],
    );

    if (onTap == null) {
      return NeoGlassCard(child: content);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(NeoLayout.cardRadius),
      child: NeoGlassCard(child: content),
    );
  }

  Widget _buildTransactionsHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        NeoLayout.screenPadding,
        NeoLayout.sectionGap,
        NeoLayout.screenPadding,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          const Expanded(
            child: AdaptiveHeadingText(
              text: 'All transactions',
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              '$count ${count == 1 ? 'transaction' : 'transactions'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: NeoTypography.rowSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedTransactions(
    Map<DateTime, List<Transaction>> grouped,
    String currencySymbol, {
    required bool isSimpleMode,
  }) {
    final slivers = <Widget>[];
    for (final entry in grouped.entries) {
      final date = entry.key;
      final transactions = entry.value;

      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              NeoLayout.screenPadding,
              AppSpacing.sm,
              NeoLayout.screenPadding,
              AppSpacing.xs,
            ),
            child: Text(
              _formatDateHeader(date),
              style: AppTypography.labelMedium.copyWith(
                color: _palette.textSecondary,
              ),
            ),
          ),
        ),
      );

      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: NeoLayout.screenPadding,
            ),
            child: NeoGlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: transactions.asMap().entries.map((entry) {
                  final txIndex = entry.key;
                  final transaction = entry.value;
                  final isLast = txIndex == transactions.length - 1;

                  return Column(
                    children: [
                      Dismissible(
                        key: Key(transaction.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: AppSpacing.md),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: NeoTheme.negativeValue(context),
                            borderRadius:
                                BorderRadius.circular(AppSizing.radiusMd),
                          ),
                          child: const Icon(
                            LucideIcons.trash2,
                            color: Colors.white,
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          return await _showDeleteConfirmation();
                        },
                        onDismissed: (direction) {
                          ref
                              .read(transactionNotifierProvider.notifier)
                              .deleteTransaction(transaction.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Transaction deleted')),
                          );
                        },
                        child: TransactionListItem(
                          transaction: transaction,
                          currencySymbol: currencySymbol,
                          useSimpleLabel: isSimpleMode,
                          onTap: () => _showEditSheet(transaction),
                        ),
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          indent: AppSpacing.md + 44 + AppSpacing.md,
                          color: _palette.stroke.withValues(alpha: 0.85),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      );
    }
    return slivers;
  }

  Widget _buildEmptyState() {
    final hasFilters = _searchQuery.isNotEmpty ||
        _filterType != null ||
        _filterAccountId != null;

    return NeoGlassCard(
      child: Padding(
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
                hasFilters ? LucideIcons.searchX : LucideIcons.receipt,
                color: _palette.textSecondary,
                size: NeoIconSizes.xl,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              hasFilters ? 'No matching transactions' : 'No transactions yet',
              style: NeoTypography.rowTitle(context),
            ),
            const SizedBox(height: 2),
            Text(
              hasFilters
                  ? 'Try adjusting search or filters.'
                  : 'Add your first transaction to start tracking.',
              style: NeoTypography.rowSecondary(context),
              textAlign: TextAlign.center,
            ),
            if (!hasFilters) ...[
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: () => _showAddSheet(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _palette.accent,
                  foregroundColor: NeoTheme.isLight(context)
                      ? _palette.textPrimary
                      : _palette.surface1,
                ),
                icon: const Icon(LucideIcons.plus, size: NeoIconSizes.md),
                label: const Text('Add transaction'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
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
          'Failed to load transactions: $error',
          style: AppTypography.bodySmall.copyWith(color: danger),
        ),
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == yesterday) return 'Yesterday';
    if (dateOnly.year == today.year) return DateFormat('d MMMM').format(date);
    return DateFormat('d MMMM yyyy').format(date);
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return NumberFormat('#,##0').format(amount.toInt());
    }
    if (amount == amount.roundToDouble()) {
      return NumberFormat('#,##0').format(amount);
    }
    return NumberFormat('#,##0.##').format(amount);
  }

  Future<void> _showAddSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TransactionFormSheet(),
    );
  }

  void _showEditSheet(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionFormSheet(transaction: transaction),
    );
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: _palette.surface1,
            title: Text(
              'Delete Transaction?',
              style: AppTypography.h3.copyWith(color: _palette.textPrimary),
            ),
            content: Text(
              'This action cannot be undone.',
              style: AppTypography.bodyMedium.copyWith(
                color: _palette.textSecondary,
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
