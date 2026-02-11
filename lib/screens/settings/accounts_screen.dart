import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../models/account.dart';
import '../../providers/providers.dart';
import '../../widgets/common/neo_page_components.dart';
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

  NeoPalette get _palette => NeoTheme.of(context);

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(allAccountsProvider);
    final balancesAsync = ref.watch(allAccountBalancesProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final netWorthAsync = ref.watch(netWorthProvider);

    return Scaffold(
      backgroundColor: _palette.appBg,
      body: NeoPageBackground(
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

              return ListView(
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
                  _buildNetWorthCard(
                    netWorth: netWorthAsync.value ?? 0,
                    currencySymbol: currencySymbol,
                  ),
                  const SizedBox(height: NeoLayout.sectionGap),
                  _buildSectionCard(
                    title: 'Active Accounts',
                    subtitle: 'Drag to reorder',
                    child: _buildActiveAccountsList(
                      activeAccounts: activeAccounts,
                      balances: balances,
                      currencySymbol: currencySymbol,
                    ),
                  ),
                  if (archivedAccounts.isNotEmpty) ...[
                    const SizedBox(height: NeoLayout.sectionGap),
                    _buildSectionCard(
                      title: 'Archived',
                      subtitle: 'Unavailable for new transactions',
                      child: _buildArchivedAccountsList(
                        archivedAccounts: archivedAccounts,
                        balances: balances,
                        currencySymbol: currencySymbol,
                      ),
                    ),
                  ],
                  if (accounts.isEmpty) ...[
                    const SizedBox(height: NeoLayout.sectionGap),
                    _buildEmptyState(),
                  ],
                ],
              );
            },
            loading: () => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 280),
                Center(child: CircularProgressIndicator()),
              ],
            ),
            error: (error, stack) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
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
                  'Accounts',
                  style: NeoTypography.pageTitle(context),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Balances, ordering, and account settings',
                  style: NeoTypography.pageContext(context),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: NeoCircleIconButton(
              icon: LucideIcons.plus,
              onPressed: _showCreateSheet,
              semanticLabel: 'Add account',
              size: 36,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetWorthCard({
    required double netWorth,
    required String currencySymbol,
  }) {
    final isNegative = netWorth < 0;
    final accent = isNegative
        ? NeoTheme.negativeValue(context)
        : NeoTheme.positiveValue(context);

    return NeoGlassCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _palette.surface2,
              borderRadius: BorderRadius.circular(AppSizing.radiusMd),
              border: Border.all(color: _palette.stroke),
            ),
            child: Icon(
              LucideIcons.pieChart,
              size: NeoIconSizes.lg,
              color: accent,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Net worth', style: NeoTypography.rowSecondary(context)),
                const SizedBox(height: 2),
                Text(
                  '$currencySymbol${_formatAmount(netWorth)}',
                  style: NeoTypography.rowAmount(context, accent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return NeoGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdaptiveHeadingText(text: title),
          const SizedBox(height: 2),
          Text(subtitle, style: NeoTypography.rowSecondary(context)),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }

  Widget _buildActiveAccountsList({
    required List<Account> activeAccounts,
    required Map<String, double> balances,
    required String currencySymbol,
  }) {
    if (activeAccounts.isEmpty) {
      return Text(
        'No active accounts yet. Create one to get started.',
        style: NeoTypography.rowSecondary(context),
      );
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activeAccounts.length,
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) =>
          _onReorder(activeAccounts, oldIndex, newIndex),
      itemBuilder: (context, index) {
        final account = activeAccounts[index];
        final balance = balances[account.id] ?? 0;
        final isLast = index == activeAccounts.length - 1;
        return Column(
          key: ValueKey(account.id),
          children: [
            _buildAccountRow(
              account: account,
              balance: balance,
              currencySymbol: currencySymbol,
              showDragHandle: true,
              dragIndex: index,
            ),
            if (!isLast)
              Divider(
                height: 12,
                color: _palette.stroke.withValues(alpha: 0.85),
              ),
          ],
        );
      },
    );
  }

  Widget _buildArchivedAccountsList({
    required List<Account> archivedAccounts,
    required Map<String, double> balances,
    required String currencySymbol,
  }) {
    return Column(
      children: archivedAccounts.asMap().entries.map((entry) {
        final index = entry.key;
        final account = entry.value;
        final balance = balances[account.id] ?? 0;
        final isLast = index == archivedAccounts.length - 1;

        return Column(
          children: [
            _buildAccountRow(
              account: account,
              balance: balance,
              currencySymbol: currencySymbol,
            ),
            if (!isLast)
              Divider(
                height: 12,
                color: _palette.stroke.withValues(alpha: 0.85),
              ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildAccountRow({
    required Account account,
    required double balance,
    required String currencySymbol,
    bool showDragHandle = false,
    int? dragIndex,
  }) {
    final isNegative = balance < 0;
    final balanceColor = isNegative
        ? NeoTheme.negativeValue(context)
        : NeoTheme.positiveValue(context);
    final accountColor = _accountTypeColor(account.type);

    return InkWell(
      onTap: () => _showEditSheet(account),
      borderRadius: BorderRadius.circular(AppSizing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _palette.surface2,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: _palette.stroke),
              ),
              child: Icon(
                _accountTypeIcon(account.type),
                size: NeoIconSizes.lg,
                color: accountColor,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
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
                          style: NeoTypography.rowTitle(context),
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
                            color: NeoTheme.warningValue(context)
                                .withValues(alpha: 0.14),
                            borderRadius:
                                BorderRadius.circular(AppSizing.radiusFull),
                          ),
                          child: Text(
                            'Excluded',
                            style: AppTypography.bodySmall.copyWith(
                              color: NeoTheme.warningValue(context),
                              fontSize: 10,
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
                    style: NeoTypography.rowSecondary(context),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$currencySymbol${_formatAmount(balance)}',
                  style: NeoTypography.rowAmount(context, balanceColor),
                ),
                const SizedBox(height: 2),
                Text(
                  account.isArchived ? 'Archived' : 'Active',
                  style: NeoTypography.rowSecondary(context),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.xs),
            Theme(
              data: Theme.of(context).copyWith(
                popupMenuTheme: PopupMenuThemeData(
                  color: _palette.surface2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                    side: BorderSide(color: _palette.stroke),
                  ),
                  textStyle: AppTypography.bodyMedium.copyWith(
                    color: _palette.textPrimary,
                  ),
                ),
              ),
              child: PopupMenuButton<String>(
                icon: Icon(
                  LucideIcons.moreVertical,
                  size: NeoIconSizes.lg,
                  color: _palette.textSecondary,
                ),
                onSelected: (value) => _onMenuSelect(account, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  if (!account.isArchived)
                    const PopupMenuItem(
                        value: 'archive', child: Text('Archive')),
                  if (account.isArchived)
                    const PopupMenuItem(
                      value: 'unarchive',
                      child: Text('Unarchive'),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: TextStyle(color: NeoTheme.negativeValue(context)),
                    ),
                  ),
                ],
              ),
            ),
            if (showDragHandle)
              ReorderableDragStartListener(
                index: dragIndex ?? 0,
                child: Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Icon(
                    LucideIcons.gripVertical,
                    size: NeoIconSizes.lg,
                    color: _palette.textMuted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
                LucideIcons.wallet,
                color: _palette.textSecondary,
                size: NeoIconSizes.xl,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('No accounts yet', style: NeoTypography.rowTitle(context)),
            const SizedBox(height: 2),
            Text(
              'Create your first account to start tracking balances.',
              style: NeoTypography.rowSecondary(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: _showCreateSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: _palette.accent,
                foregroundColor: NeoTheme.isLight(context)
                    ? _palette.textPrimary
                    : _palette.surface1,
              ),
              icon: const Icon(LucideIcons.plus, size: NeoIconSizes.md),
              label: const Text('Create account'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return NeoGlassCard(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: NeoTheme.negativeValue(context).withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: NeoTheme.negativeValue(context).withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          'Failed to load accounts: $error',
          style: AppTypography.bodySmall.copyWith(
            color: NeoTheme.negativeValue(context),
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
          backgroundColor: NeoTheme.negativeValue(context),
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
          backgroundColor: NeoTheme.negativeValue(context),
        ),
      );
    }
  }

  Future<bool> _confirmDelete() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: _palette.surface1,
            title: Text(
              'Delete Account?',
              style: AppTypography.h3.copyWith(color: _palette.textPrimary),
            ),
            content: Text(
              'Delete this account only if it has no transaction or transfer history.',
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

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
        return _palette.textSecondary;
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
    final formatted = absolute == absolute.roundToDouble()
        ? NumberFormat('#,##0').format(absolute)
        : NumberFormat('#,##0.##').format(absolute);
    return amount < 0 ? '-$formatted' : formatted;
  }
}
