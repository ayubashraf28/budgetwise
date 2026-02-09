import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../models/account.dart';
import '../../providers/providers.dart';
import 'account_form_sheet.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({
    super.key,
    this.initialAccountId,
  });

  final String? initialAccountId;

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  bool _didHandleInitialAccount = false;

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(allAccountsProvider);
    final balancesAsync = ref.watch(allAccountBalancesProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final netWorthAsync = ref.watch(netWorthProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Accounts'),
        backgroundColor: AppColors.background,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSheet,
        icon: const Icon(LucideIcons.plus),
        label: const Text('Add Account'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(accountsProvider);
            ref.invalidate(allAccountsProvider);
            ref.invalidate(accountBalancesProvider);
            ref.invalidate(allAccountBalancesProvider);
            ref.invalidate(netWorthProvider);
          },
          child: accountsAsync.when(
            data: (accounts) {
              _maybeOpenInitialAccount(accounts);

              final balances = balancesAsync.value ?? const <String, double>{};
              final activeAccounts =
                  accounts.where((a) => !a.isArchived).toList();
              final archivedAccounts =
                  accounts.where((a) => a.isArchived).toList();

              if (accounts.isEmpty) {
                return _buildEmptyState();
              }

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _buildNetWorthCard(
                    netWorth: netWorthAsync.value ?? 0,
                    currencySymbol: currencySymbol,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSectionHeader(
                    title: 'Active Accounts',
                    subtitle: 'Drag to reorder',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildActiveAccountsCard(
                    activeAccounts: activeAccounts,
                    balances: balances,
                    currencySymbol: currencySymbol,
                  ),
                  if (archivedAccounts.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _buildSectionHeader(
                      title: 'Archived',
                      subtitle: 'Unavailable for new transactions',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildArchivedAccountsCard(
                      archivedAccounts: archivedAccounts,
                      balances: balances,
                      currencySymbol: currencySymbol,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
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

  void _maybeOpenInitialAccount(List<Account> accounts) {
    if (_didHandleInitialAccount) return;
    final initialId = widget.initialAccountId;
    if (initialId == null || initialId.isEmpty) {
      _didHandleInitialAccount = true;
      return;
    }

    final matches = accounts.where((a) => a.id == initialId);
    if (matches.isEmpty) {
      _didHandleInitialAccount = true;
      return;
    }

    final account = matches.first;
    _didHandleInitialAccount = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showEditSheet(account);
    });
  }

  Widget _buildNetWorthCard({
    required double netWorth,
    required String currencySymbol,
  }) {
    final isNegative = netWorth < 0;
    final color = isNegative ? AppColors.error : AppColors.savings;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSizing.radiusMd),
            ),
            child: Icon(
              LucideIcons.pieChart,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Net Worth',
                  style: AppTypography.labelLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  '$currencySymbol${_formatAmount(netWorth)}',
                  style: AppTypography.amountMedium.copyWith(color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.h3,
        ),
        Text(
          subtitle,
          style: AppTypography.bodySmall,
        ),
      ],
    );
  }

  Widget _buildActiveAccountsCard({
    required List<Account> activeAccounts,
    required Map<String, double> balances,
    required String currencySymbol,
  }) {
    if (activeAccounts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        ),
        child: const Text(
          'No active accounts yet. Create one to get started.',
          style: AppTypography.bodyMedium,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
      ),
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activeAccounts.length,
        buildDefaultDragHandles: false,
        onReorder: (oldIndex, newIndex) =>
            _onReorder(activeAccounts, oldIndex, newIndex),
        itemBuilder: (context, index) {
          final account = activeAccounts[index];
          final balance = balances[account.id] ?? 0;
          return _buildAccountTile(
            key: ValueKey(account.id),
            account: account,
            balance: balance,
            currencySymbol: currencySymbol,
            showDragHandle: true,
            dragIndex: index,
          );
        },
      ),
    );
  }

  Widget _buildArchivedAccountsCard({
    required List<Account> archivedAccounts,
    required Map<String, double> balances,
    required String currencySymbol,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
      ),
      child: Column(
        children: archivedAccounts.asMap().entries.map((entry) {
          final index = entry.key;
          final account = entry.value;
          final balance = balances[account.id] ?? 0;
          final isLast = index == archivedAccounts.length - 1;
          return Column(
            children: [
              _buildAccountTile(
                account: account,
                balance: balance,
                currencySymbol: currencySymbol,
              ),
              if (!isLast) const Divider(height: 1, color: AppColors.border),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAccountTile({
    Key? key,
    required Account account,
    required double balance,
    required String currencySymbol,
    bool showDragHandle = false,
    int? dragIndex,
  }) {
    final isNegative = balance < 0;
    final accent = isNegative ? AppColors.error : AppColors.savings;

    return Material(
      key: key,
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showEditSheet(account),
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color:
                      _accountTypeColor(account.type).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                ),
                child: Icon(
                  _accountTypeIcon(account.type),
                  size: 18,
                  color: _accountTypeColor(account.type),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            account.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelLarge,
                          ),
                        ),
                        if (!account.includeInNetWorth) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius:
                                  BorderRadius.circular(AppSizing.radiusFull),
                            ),
                            child: const Text(
                              'Excluded',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _accountTypeLabel(account.type),
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$currencySymbol${_formatAmount(balance)}',
                    style: AppTypography.labelLarge.copyWith(color: accent),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    account.isArchived ? 'Archived' : 'Active',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.xs),
              PopupMenuButton<String>(
                color: AppColors.surfaceLight,
                icon: const Icon(
                  LucideIcons.moreVertical,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                onSelected: (value) => _onMenuSelect(account, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  if (!account.isArchived)
                    const PopupMenuItem(
                      value: 'archive',
                      child: Text('Archive'),
                    ),
                  if (account.isArchived)
                    const PopupMenuItem(
                      value: 'unarchive',
                      child: Text('Unarchive'),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
              ),
              if (showDragHandle)
                ReorderableDragStartListener(
                  index: dragIndex ?? 0,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 2),
                    child: Icon(
                      LucideIcons.gripVertical,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onReorder(
      List<Account> activeAccounts, int oldIndex, int newIndex) async {
    HapticFeedback.selectionClick();

    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;

    final reordered = [...activeAccounts];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    try {
      await ref
          .read(accountNotifierProvider.notifier)
          .reorderAccounts(reordered.map((a) => a.id).toList());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reorder accounts: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _onMenuSelect(Account account, String action) async {
    final notifier = ref.read(accountNotifierProvider.notifier);

    try {
      switch (action) {
        case 'edit':
          _showEditSheet(account);
          break;
        case 'archive':
          await notifier.archiveAccount(account.id);
          _showSuccess('Account archived');
          break;
        case 'unarchive':
          await notifier.unarchiveAccount(account.id);
          _showSuccess('Account unarchived');
          break;
        case 'delete':
          final confirmed = await _confirmDelete();
          if (confirmed && mounted) {
            await notifier.deleteAccount(account.id);
            _showSuccess('Account deleted');
          }
          break;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<bool> _confirmDelete() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Delete Account?'),
            content: const Text(
              'Delete this account only if it has no transaction or transfer history.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AccountFormSheet(),
    );
  }

  void _showEditSheet(Account account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AccountFormSheet(account: account),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizing.radiusLg),
          ),
          child: Column(
            children: [
              const Icon(
                LucideIcons.wallet,
                size: 46,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'No accounts yet',
                style: AppTypography.h3,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Create accounts for cash, debit cards, and credit cards to track balances accurately.',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: _showCreateSheet,
                icon: const Icon(LucideIcons.plus, size: 18),
                label: const Text('Create First Account'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          'Failed to load accounts: $error',
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
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
        return AppColors.savings;
      case AccountType.debit:
        return AppColors.info;
      case AccountType.credit:
        return AppColors.warning;
      case AccountType.savings:
        return AppColors.success;
      case AccountType.other:
        return AppColors.textSecondary;
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

  String _formatAmount(double amount) {
    final absolute = amount.abs();
    final sign = amount < 0 ? '-' : '';
    return '$sign${absolute.toStringAsFixed(2)}';
  }
}
