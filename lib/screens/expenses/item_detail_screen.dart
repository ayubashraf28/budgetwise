import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../models/item.dart';
import '../../models/transaction.dart';
import '../../providers/providers.dart';
import '../../widgets/budget/budget_widgets.dart';
import '../transactions/transaction_form_sheet.dart';
import 'item_form_sheet.dart';

class ItemDetailScreen extends ConsumerWidget {
  final String categoryId;
  final String itemId;

  const ItemDetailScreen({
    super.key,
    required this.categoryId,
    required this.itemId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(itemByIdProvider(itemId));
    final transactionsAsync = ref.watch(transactionsByItemProvider(itemId));
    final categoryAsync = ref.watch(categoryByIdProvider(categoryId));
    final currencySymbol = ref.watch(currencySymbolProvider);

    return itemAsync.when(
      data: (item) {
        if (item == null) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: const Center(child: Text('Item not found')),
          );
        }

        final categoryColor =
            categoryAsync.value?.colorValue ?? AppColors.primary;
        final transactions = transactionsAsync.value ?? const <Transaction>[];

        return _ItemDetailScaffold(
          categoryId: categoryId,
          itemId: itemId,
          item: item,
          transactions: transactions,
          categoryColor: categoryColor,
          currencySymbol: currencySymbol,
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _ItemDetailScaffold extends ConsumerWidget {
  final String categoryId;
  final String itemId;
  final Item item;
  final List<Transaction> transactions;
  final Color categoryColor;
  final String currencySymbol;

  const _ItemDetailScaffold({
    required this.categoryId,
    required this.itemId,
    required this.item,
    required this.transactions,
    required this.categoryColor,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = <DateTime, List<Transaction>>{};
    for (final tx in transactions) {
      final key = DateTime(tx.date.year, tx.date.month, tx.date.day);
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          final _ = await Future.wait([
            ref.refresh(itemByIdProvider(itemId).future),
            ref.refresh(transactionsByItemProvider(itemId).future),
            ref.refresh(categoryByIdProvider(categoryId).future),
          ]);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              leading: IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(LucideIcons.moreVertical),
                  color: AppColors.surface,
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditItemSheet(context, ref, item);
                      case 'delete':
                        _showDeleteItemConfirmation(context, ref, item);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(LucideIcons.pencil, size: 18),
                          SizedBox(width: 8),
                          Text('Edit Item'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.trash2,
                            size: 18,
                            color: AppColors.error,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Delete Item',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              backgroundColor: AppColors.background,
            ),
            // Glass Summary Card
            SliverToBoxAdapter(
              child: _buildGlassSummaryCard(item),
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
                    const Text('Transactions', style: AppTypography.h3),
                    Text(
                      '${transactions.length} ${transactions.length == 1 ? 'transaction' : 'transactions'}',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            if (transactions.isEmpty)
              SliverToBoxAdapter(
                child: _buildEmptyState(context, ref),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final date = sortedDates[index];
                    final dayTransactions = grouped[date]!;
                    return _buildDateGroup(context, ref, date, dayTransactions);
                  },
                  childCount: sortedDates.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassSummaryCard(Item item) {
    final color = categoryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + item name + status badge
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                  ),
                  child: Icon(
                    LucideIcons.receipt,
                    size: 18,
                    color: color,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                _buildStatusBadge(item),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Amount
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$currencySymbol${item.actual.toStringAsFixed(0)}',
                  style: AppTypography.amountMedium.copyWith(color: color),
                ),
                Text(
                  ' / $currencySymbol${item.projected.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: color.withValues(alpha: 0.6),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Progress bar
            BudgetProgressBar(
              projected: item.projected,
              actual: item.actual,
              color: color,
              backgroundColor: color.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSpacing.xs),
            // Status text
            Text(
              item.isOverBudget
                  ? '$currencySymbol${(item.actual - item.projected).toStringAsFixed(0)} over budget'
                  : '$currencySymbol${item.remaining.toStringAsFixed(0)} remaining',
              style: TextStyle(
                fontSize: 12,
                color: item.isOverBudget
                    ? AppColors.error
                    : color.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Item item) {
    final label = item.status;
    final Color badgeColor;
    switch (label) {
      case 'Over budget':
        badgeColor = AppColors.error;
      case 'On budget':
      case 'Under budget':
        badgeColor = AppColors.success;
      case 'Not started':
      case 'No budget':
      default:
        badgeColor = AppColors.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizing.radiusFull),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: badgeColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDateGroup(
    BuildContext context,
    WidgetRef ref,
    DateTime date,
    List<Transaction> dayTransactions,
  ) {
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
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizing.radiusLg),
          ),
          child: Column(
            children: dayTransactions.asMap().entries.map((entry) {
              final txIndex = entry.key;
              final tx = entry.value;
              final isLast = txIndex == dayTransactions.length - 1;

              return Column(
                children: [
                  Dismissible(
                    key: Key(tx.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
                      ),
                      child:
                          const Icon(LucideIcons.trash2, color: Colors.white),
                    ),
                    confirmDismiss: (_) => _confirmDeleteTransaction(context),
                    onDismissed: (_) {
                      ref
                          .read(transactionNotifierProvider.notifier)
                          .deleteTransaction(tx.id);
                      _invalidateAfterTransactionChange(ref);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Transaction deleted')),
                      );
                    },
                    child: TransactionListItem(
                      transaction: tx,
                      currencySymbol: currencySymbol,
                      onEdit: () => _showEditTransactionSheet(context, ref, tx),
                      onDelete: () async {
                        final confirmed =
                            await _confirmDeleteTransaction(context);
                        if (!confirmed || !context.mounted) return;
                        ref
                            .read(transactionNotifierProvider.notifier)
                            .deleteTransaction(tx.id);
                        _invalidateAfterTransactionChange(ref);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Transaction deleted')),
                        );
                      },
                    ),
                  ),
                  if (!isLast)
                    const Divider(
                      height: 1,
                      indent: AppSpacing.md + 44 + AppSpacing.md,
                      color: AppColors.border,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
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

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizing.radiusLg),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.receipt,
                size: 48,
                color: AppColors.textMuted,
              ),
              SizedBox(height: AppSpacing.md),
              Text('No transactions yet', style: AppTypography.h3),
              SizedBox(height: AppSpacing.sm),
              Text(
                'Add a transaction to start tracking spending for this item',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditTransactionSheet(
    BuildContext context,
    WidgetRef ref,
    Transaction tx,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionFormSheet(transaction: tx),
    ).then((_) => _invalidateAfterTransactionChange(ref));
  }

  void _showEditItemSheet(BuildContext context, WidgetRef ref, Item item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ItemFormSheet(categoryId: categoryId, item: item),
    ).then((_) {
      ref.invalidate(itemByIdProvider(itemId));
      ref.invalidate(categoryByIdProvider(categoryId));
      ref.invalidate(categoriesProvider);
    });
  }

  Future<void> _showDeleteItemConfirmation(
    BuildContext context,
    WidgetRef ref,
    Item item,
  ) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Delete Item?'),
            content: Text(
              'This will delete "${item.name}" and all its transactions. This cannot be undone.',
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

    if (confirmed != true || !context.mounted) return;

    await ref
        .read(itemNotifierProvider(categoryId).notifier)
        .deleteItem(item.id);
    ref.invalidate(itemByIdProvider(itemId));
    ref.invalidate(categoryByIdProvider(categoryId));
    ref.invalidate(categoriesProvider);

    if (!context.mounted) return;
    Navigator.of(context).pop(); // Back to category detail
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.name} deleted')),
    );
  }

  Future<bool> _confirmDeleteTransaction(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Delete Transaction?'),
            content: const Text('This action cannot be undone.'),
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

  void _invalidateAfterTransactionChange(WidgetRef ref) {
    ref.invalidate(transactionsByItemProvider(itemId));
    ref.invalidate(itemByIdProvider(itemId));
    ref.invalidate(categoryByIdProvider(categoryId));
    ref.invalidate(categoriesProvider);
    ref.invalidate(transactionsProvider);
  }
}
