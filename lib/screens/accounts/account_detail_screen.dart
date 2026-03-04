import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../models/account.dart';
import '../../models/transaction.dart';
import '../../providers/providers.dart';
import '../../utils/account_balance_warning_utils.dart';
import '../../utils/app_icon_registry.dart';
import '../../utils/errors/error_mapper.dart';
import '../../widgets/common/neo_page_components.dart';
import '../settings/account_form_sheet.dart';
import '../transactions/transaction_form_sheet.dart';

class AccountDetailScreen extends ConsumerWidget {
  const AccountDetailScreen({
    super.key,
    required this.accountId,
  });

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountAsync = ref.watch(accountByIdProvider(accountId));
    final currencySymbol = ref.watch(currencySymbolProvider);

    return accountAsync.when(
      data: (account) {
        if (account == null) {
          return _buildMissingAccount(context);
        }
        return _AccountDetailView(
          accountId: accountId,
          account: account,
          currencySymbol: currencySymbol,
        );
      },
      loading: () => _buildLoadingState(context),
      error: (error, stackTrace) =>
          _buildErrorState(context, ErrorMapper.toUserMessage(error,
              stackTrace: stackTrace)),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoTheme.of(context).appBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildMissingAccount(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoTheme.of(context).appBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
        child: Text('Account not found'),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Scaffold(
      backgroundColor: NeoTheme.of(context).appBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Text(message),
      ),
    );
  }
}

class _AccountDetailView extends ConsumerWidget {
  const _AccountDetailView({
    required this.accountId,
    required this.account,
    required this.currencySymbol,
  });

  final String accountId;
  final Account account;
  final String currencySymbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = NeoTheme.of(context);
    final transactionsAsync = ref.watch(transactionsByAccountProvider(accountId));
    final balances = ref.watch(allAccountBalancesProvider).valueOrNull ??
        const <String, double>{};
    final balance = balances[account.id] ?? account.openingBalance;
    final transactions = transactionsAsync.valueOrNull ?? const <Transaction>[];
    final groupedTransactions = _groupTransactionsByDate(transactions);
    final groupedDates = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: palette.appBg,
      body: NeoPageBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(accountByIdProvider(accountId));
            ref.invalidate(transactionsByAccountProvider(accountId));
            ref.invalidate(accountsProvider);
            ref.invalidate(allAccountsProvider);
            ref.invalidate(allAccountBalancesProvider);
          },
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                leading: IconButton(
                  icon: const Icon(LucideIcons.arrowLeft),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(LucideIcons.pencil),
                    onPressed: () => _showEditAccountSheet(context, ref),
                  ),
                  const NeoSettingsAppBarAction(),
                ],
                backgroundColor: palette.appBg,
              ),
              SliverToBoxAdapter(
                child: _buildSummaryCard(context, balance),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: AdaptiveHeadingText(text: 'Transactions'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          '${transactions.length} ${transactions.length == 1 ? 'transaction' : 'transactions'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: NeoTypography.rowSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (transactionsAsync.isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (transactionsAsync.hasError)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      ErrorMapper.toUserMessage(
                        transactionsAsync.error!,
                        stackTrace: transactionsAsync.stackTrace,
                      ),
                      style: AppTypography.bodyMedium.copyWith(
                        color: NeoTheme.negativeValue(context),
                      ),
                    ),
                  ),
                )
              else if (transactions.isEmpty)
                SliverToBoxAdapter(
                  child: _buildEmptyState(context),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final date = groupedDates[index];
                      return _buildDateGroup(
                        context,
                        ref,
                        date: date,
                        transactions: groupedTransactions[date]!,
                      );
                    },
                    childCount: groupedDates.length,
                  ),
                ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.xl),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, double balance) {
    final accentColor = _accountTypeColor(context, account.type);
    final amountColor = balance < 0
        ? NeoTheme.negativeValue(context)
        : NeoTheme.positiveValue(context);
    final showNegativeWarning =
        shouldWarnNegativeBalance(account.type, balance);
    final utilization = _creditUtilization(balance);
    final utilizationPercent =
        utilization == null ? null : (utilization * 100).toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: NeoTheme.accentCardSurface(context, accentColor),
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
          border: Border.all(
            color: NeoTheme.accentCardBorder(context, accentColor),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: NeoTheme.of(context).surface2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: NeoTheme.of(context).stroke),
                  ),
                  child: Icon(
                    _accountTypeIcon(account.type),
                    color: accentColor,
                    size: NeoIconSizes.xl,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: NeoTypography.sectionTitle(context),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.14),
                          borderRadius:
                              BorderRadius.circular(AppSizing.radiusFull),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.24),
                          ),
                        ),
                        child: Text(
                          _accountTypeLabel(account.type),
                          style: AppTypography.bodySmall.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Current balance',
              style: NeoTypography.rowSecondary(context),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Flexible(
                  child: Text(
                    '$currencySymbol${_formatAmount(balance)}',
                    style: AppTypography.amountMedium.copyWith(
                      color: amountColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (showNegativeWarning) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Tooltip(
                    message: 'Balance is negative',
                    child: Icon(
                      LucideIcons.alertTriangle,
                      size: NeoIconSizes.md,
                      color: NeoTheme.warningValue(context),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Opening balance: $currencySymbol${_formatAmount(account.openingBalance)}',
              style: NeoTypography.rowSecondary(context),
            ),
            if (account.creditLimit != null && account.creditLimit! > 0) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Credit limit',
                    style: NeoTypography.rowSecondary(context),
                  ),
                  Text(
                    '$currencySymbol${_formatAmount(account.creditLimit!)}',
                    style: NeoTypography.rowSecondary(context).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizing.radiusFull),
                child: LinearProgressIndicator(
                  value: utilization == null ? 0 : utilization.clamp(0, 1),
                  minHeight: 8,
                  backgroundColor: NeoTheme.of(context)
                      .surface2
                      .withValues(alpha: 0.8),
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                utilization == null
                    ? 'No utilization data'
                    : utilization > 1
                        ? '$utilizationPercent% utilized (over limit)'
                        : '$utilizationPercent% utilized',
                style: NeoTypography.rowSecondary(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateGroup(
    BuildContext context,
    WidgetRef ref, {
    required DateTime date,
    required List<Transaction> transactions,
  }) {
    final palette = NeoTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Text(
            _formatDateHeader(date),
            style: AppTypography.labelMedium
                .copyWith(color: palette.textSecondary),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: palette.surface1,
            borderRadius: BorderRadius.circular(AppSizing.radiusLg),
          ),
          child: Column(
            children: transactions.asMap().entries.map((entry) {
              final index = entry.key;
              final transaction = entry.value;
              final isLast = index == transactions.length - 1;

              return Column(
                children: [
                  Dismissible(
                    key: Key(transaction.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: NeoTheme.negativeValue(context),
                        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
                      ),
                      child:
                          const Icon(LucideIcons.trash2, color: Colors.white),
                    ),
                    confirmDismiss: (_) =>
                        _confirmDeleteTransaction(context),
                    onDismissed: (_) async {
                      await ref
                          .read(transactionNotifierProvider.notifier)
                          .deleteTransaction(transaction.id);
                      _invalidateTransactionState(ref);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Transaction deleted')),
                        );
                      }
                    },
                    child: _AccountTransactionRow(
                      transaction: transaction,
                      currencySymbol: currencySymbol,
                      onTap: () => _showEditTransactionSheet(
                        context,
                        ref,
                        transaction,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: AppSpacing.md + 44 + AppSpacing.md,
                      color: palette.stroke.withValues(alpha: 0.85),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final palette = NeoTheme.of(context);

    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: palette.surface1,
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
          border: Border.all(color: palette.stroke.withValues(alpha: 0.7)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _accountTypeIcon(account.type),
              size: 48,
              color: palette.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No transactions yet',
              style: NeoTypography.rowTitle(context),
            ),
            const SizedBox(height: 2),
            Text(
              'Transactions for this account will appear here.',
              style: NeoTypography.rowSecondary(context),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Map<DateTime, List<Transaction>> _groupTransactionsByDate(
    List<Transaction> transactions,
  ) {
    final grouped = <DateTime, List<Transaction>>{};
    for (final tx in transactions) {
      final key = DateTime(tx.date.year, tx.date.month, tx.date.day);
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    return grouped;
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

  Future<void> _showEditAccountSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AccountFormSheet(account: account),
    );
    ref.invalidate(accountByIdProvider(accountId));
    ref.invalidate(accountsProvider);
    ref.invalidate(allAccountsProvider);
    ref.invalidate(allAccountBalancesProvider);
  }

  Future<void> _showEditTransactionSheet(
    BuildContext context,
    WidgetRef ref,
    Transaction transaction,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionFormSheet(transaction: transaction),
    );
    _invalidateTransactionState(ref);
  }

  Future<bool> _confirmDeleteTransaction(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: NeoTheme.of(context).surface1,
            title: const Text('Delete Transaction?'),
            content: const Text('This action cannot be undone.'),
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

  void _invalidateTransactionState(WidgetRef ref) {
    ref.invalidate(transactionsByAccountProvider(accountId));
    ref.invalidate(accountBalancesProvider);
    ref.invalidate(allAccountBalancesProvider);
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

  Color _accountTypeColor(BuildContext context, AccountType type) {
    switch (type) {
      case AccountType.cash:
        return NeoTheme.of(context).accent;
      case AccountType.debit:
        return NeoTheme.infoValue(context);
      case AccountType.credit:
        return NeoTheme.warningValue(context);
      case AccountType.savings:
        return NeoTheme.positiveValue(context);
      case AccountType.other:
        return NeoTheme.of(context).textSecondary;
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

  double? _creditUtilization(double balance) {
    final limit = account.creditLimit;
    if (limit == null || limit <= 0) return null;
    return balance.abs() / limit;
  }

  String _formatAmount(double amount) {
    final absolute = amount.abs();
    final formatted = absolute == absolute.roundToDouble()
        ? NumberFormat('#,##0').format(absolute)
        : NumberFormat('#,##0.##').format(absolute);
    return amount < 0 ? '-$formatted' : formatted;
  }
}

class _AccountTransactionRow extends StatelessWidget {
  const _AccountTransactionRow({
    required this.transaction,
    required this.currencySymbol,
    required this.onTap,
  });

  final Transaction transaction;
  final String currencySymbol;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);
    final isIncome = transaction.isIncome;
    final amountColor = isIncome
        ? NeoTheme.positiveValue(context)
        : NeoTheme.negativeValue(context);
    final chipColor = isIncome
        ? NeoTheme.positiveValue(context)
        : _parseColor(transaction.categoryColor);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: palette.surface2,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: palette.stroke),
                    ),
                    child: Icon(
                      isIncome
                          ? LucideIcons.arrowDownLeft
                          : transaction.categoryIcon != null
                              ? resolveAppIcon(
                                  transaction.categoryIcon!,
                                  fallback: _fallbackExpenseIcon(
                                    transaction.categoryName,
                                  ),
                                )
                              : _fallbackExpenseIcon(transaction.categoryName),
                      color: chipColor,
                      size: NeoIconSizes.lg,
                    ),
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: amountColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: palette.surface1, width: 2),
                      ),
                      child: Center(
                        child: Icon(
                          isIncome ? LucideIcons.plus : LucideIcons.minus,
                          size: NeoIconSizes.xxs,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _primaryLabel,
                      style: NeoTypography.rowTitle(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: chipColor.withValues(alpha: 0.14),
                        borderRadius:
                            BorderRadius.circular(AppSizing.radiusFull),
                        border: Border.all(
                          color: chipColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        _secondaryLabel,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: chipColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                transaction.formattedAmount(currencySymbol),
                style: NeoTypography.rowAmount(context, amountColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _primaryLabel {
    final trimmedNote = transaction.note?.trim();
    if (trimmedNote != null && trimmedNote.isNotEmpty) {
      return trimmedNote;
    }

    final itemName = transaction.itemName?.trim();
    if (itemName != null && itemName.isNotEmpty) {
      return itemName;
    }

    final incomeSourceName = transaction.incomeSourceName?.trim();
    if (incomeSourceName != null && incomeSourceName.isNotEmpty) {
      return incomeSourceName;
    }

    final categoryName = transaction.categoryName?.trim();
    if (categoryName != null && categoryName.isNotEmpty) {
      return categoryName;
    }

    return transaction.isIncome ? 'Income' : 'Expense';
  }

  String get _secondaryLabel {
    if (transaction.isIncome) {
      final incomeSourceName = transaction.incomeSourceName?.trim();
      return incomeSourceName != null && incomeSourceName.isNotEmpty
          ? incomeSourceName
          : 'Income';
    }

    final categoryName = transaction.categoryName?.trim();
    return categoryName != null && categoryName.isNotEmpty
        ? categoryName
        : 'Expense';
  }

  Color _parseColor(String? hex) {
    if (hex == null) return NeoTheme.dark.accent;
    try {
      final hexCode = hex.replaceFirst('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (_) {
      return NeoTheme.dark.accent;
    }
  }

  IconData _fallbackExpenseIcon(String? categoryName) {
    if (categoryName == null) return LucideIcons.receipt;

    final iconMap = {
      'housing': LucideIcons.home,
      'food': LucideIcons.utensils,
      'transport': LucideIcons.car,
      'subscriptions': LucideIcons.tv,
      'personal': LucideIcons.shoppingBag,
      'entertainment': LucideIcons.gamepad2,
      'savings': LucideIcons.piggyBank,
      'education': LucideIcons.graduationCap,
      'health': LucideIcons.heart,
      'business': LucideIcons.briefcase,
      'travel': LucideIcons.plane,
      'gifts': LucideIcons.gift,
      'charity': LucideIcons.heart,
    };

    final lowerName = categoryName.toLowerCase();
    for (final entry in iconMap.entries) {
      if (lowerName.contains(entry.key)) {
        return entry.value;
      }
    }

    return LucideIcons.receipt;
  }
}
