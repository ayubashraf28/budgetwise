import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../models/item.dart';
import '../../models/transaction.dart';
import '../../providers/providers.dart';
import '../../widgets/budget/transaction_list_item.dart';
import '../../widgets/common/neo_page_components.dart';
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
    final isSimpleMode = ref.watch(isSimpleBudgetModeProvider);
    if (isSimpleMode) {
      final path = GoRouterState.of(context).uri.path;
      final prefix = path.startsWith('/expenses') ? '/expenses' : '/budget';
      return Scaffold(
        backgroundColor: NeoTheme.of(context).appBg,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => context.go('$prefix/category/$categoryId'),
          ),
          actions: const [NeoSettingsAppBarAction()],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AdaptiveHeadingText(text: 'Item details are hidden'),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Switch to Detailed mode in Settings to manage items.',
                  style: NeoTypography.rowSecondary(context),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: () => context.go('$prefix/category/$categoryId'),
                  child: const Text('Back to category'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final itemAsync = ref.watch(itemByIdProvider(itemId));
    final transactionsAsync = ref.watch(transactionsByItemProvider(itemId));
    final categoryAsync = ref.watch(categoryByIdProvider(categoryId));
    final currencySymbol = ref.watch(currencySymbolProvider);

    return itemAsync.when(
      data: (item) {
        if (item == null) {
          return Scaffold(
            backgroundColor: NeoTheme.of(context).appBg,
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: const [NeoSettingsAppBarAction()],
            ),
            body: const Center(child: Text('Item not found')),
          );
        }

        final categoryColor =
            categoryAsync.value?.colorValue ?? NeoTheme.of(context).accent;
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
        backgroundColor: NeoTheme.of(context).appBg,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: const [NeoSettingsAppBarAction()],
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: NeoTheme.of(context).appBg,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: const [NeoSettingsAppBarAction()],
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
    final palette = NeoTheme.of(context);
    final grouped = <DateTime, List<Transaction>>{};
    for (final tx in transactions) {
      final key = DateTime(tx.date.year, tx.date.month, tx.date.day);
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: NeoTheme.of(context).appBg,
      body: NeoPageBackground(
        child: RefreshIndicator(
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
                    color: palette.surface2,
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
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.trash2,
                              size: 18,
                              color: NeoTheme.negativeValue(context),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Delete Item',
                              style: TextStyle(
                                color: NeoTheme.negativeValue(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const NeoSettingsAppBarAction(),
                ],
                backgroundColor: palette.appBg,
              ),
              // Glass Summary Card
              SliverToBoxAdapter(
                child: _buildGlassSummaryCard(context, item),
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
                        child: AdaptiveHeadingText(
                          text: 'Transactions',
                        ),
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
                      return _buildDateGroup(
                          context, ref, date, dayTransactions);
                    },
                    childCount: sortedDates.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassSummaryCard(BuildContext context, Item item) {
    final color = categoryColor;
    final accentColor = NeoTheme.accentCardTone(context, color);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: NeoTheme.accentCardSurface(context, color),
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
          border: Border.all(color: NeoTheme.accentCardBorder(context, color)),
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
                    color: accentColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                  ),
                  child: Icon(
                    _getItemIcon(item.name),
                    size: 18,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ),
                _buildStatusBadge(context, item),
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
                  style:
                      AppTypography.amountMedium.copyWith(color: accentColor),
                ),
                Text(
                  ' spent',
                  style: TextStyle(
                    color: accentColor.withValues(alpha: 0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${transactions.length} ${transactions.length == 1 ? 'transaction' : 'transactions'}',
              style: TextStyle(
                fontSize: 12,
                color: accentColor.withValues(alpha: 0.78),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, Item item) {
    final palette = NeoTheme.of(context);
    final label = item.actual > 0 ? 'Spent' : 'No spending';
    final badgeColor =
        item.actual > 0 ? NeoTheme.warningValue(context) : palette.textMuted;

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
                        color: NeoTheme.negativeValue(context),
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
    final palette = NeoTheme.of(context);
    return Center(
      child: SingleChildScrollView(
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
                _getItemIcon(item.name),
                size: 48,
                color: palette.textMuted,
              ),
              const SizedBox(height: AppSpacing.md),
              const AdaptiveHeadingText(text: 'No transactions yet'),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Add a transaction to start tracking spending for this item',
                style: NeoTypography.rowSecondary(context),
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
      builder: (context) => ItemFormSheet(
        categoryId: categoryId,
        item: item,
      ),
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
            backgroundColor: NeoTheme.of(context).surface1,
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
                style: TextButton.styleFrom(
                  foregroundColor: NeoTheme.negativeValue(context),
                ),
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

  void _invalidateAfterTransactionChange(WidgetRef ref) {
    ref.invalidate(transactionsByItemProvider(itemId));
    ref.invalidate(itemByIdProvider(itemId));
    ref.invalidate(categoryByIdProvider(categoryId));
    ref.invalidate(categoriesProvider);
    ref.invalidate(transactionsProvider);
  }

  IconData _getItemIcon(String itemName) {
    final name = itemName.toLowerCase().trim();

    // Housing & Utilities
    if (name.contains('rent') || name.contains('mortgage')) {
      return LucideIcons.home;
    }
    if (name.contains('electricity') || name.contains('electric')) {
      return LucideIcons.zap;
    }
    if (name.contains('gas')) {
      return LucideIcons.flame;
    }
    if (name.contains('water')) {
      return LucideIcons.droplet;
    }
    if (name.contains('internet') ||
        name.contains('wifi') ||
        name.contains('broadband')) {
      return LucideIcons.wifi;
    }
    if (name.contains('council') || name.contains('tax')) {
      return LucideIcons.fileText;
    }
    if (name.contains('insurance')) {
      return LucideIcons.shield;
    }
    if (name.contains('maintenance') || name.contains('repair')) {
      return LucideIcons.wrench;
    }

    // Food & Dining
    if (name.contains('grocery') ||
        name.contains('groceries') ||
        name.contains('food')) {
      return LucideIcons.shoppingCart;
    }
    if (name.contains('dining') ||
        name.contains('restaurant') ||
        name.contains('eat out')) {
      return LucideIcons.utensilsCrossed;
    }
    if (name.contains('coffee') || name.contains('cafe')) {
      return LucideIcons.coffee;
    }
    if (name.contains('takeaway') ||
        name.contains('takeout') ||
        name.contains('delivery')) {
      return LucideIcons.package;
    }

    // Transport
    if (name.contains('fuel') ||
        name.contains('petrol') ||
        name.contains('gasoline')) {
      return LucideIcons.fuel;
    }
    if (name.contains('public transport') ||
        name.contains('bus') ||
        name.contains('train') ||
        name.contains('metro')) {
      return LucideIcons.bus;
    }
    if (name.contains('uber') ||
        name.contains('taxi') ||
        name.contains('cab')) {
      return LucideIcons.car;
    }
    if (name.contains('parking')) {
      return LucideIcons.parkingCircle;
    }

    // Subscriptions & Services
    if (name.contains('netflix') ||
        name.contains('streaming') ||
        name.contains('video')) {
      return LucideIcons.tv;
    }
    if (name.contains('spotify') ||
        name.contains('music') ||
        name.contains('audio')) {
      return LucideIcons.music;
    }
    if (name.contains('gym') ||
        name.contains('fitness') ||
        name.contains('workout')) {
      return LucideIcons.dumbbell;
    }
    if (name.contains('phone') || name.contains('mobile')) {
      return LucideIcons.smartphone;
    }
    if (name.contains('cloud') || name.contains('storage')) {
      return LucideIcons.cloud;
    }

    // Personal & Shopping
    if (name.contains('clothing') ||
        name.contains('clothes') ||
        name.contains('apparel')) {
      return LucideIcons.shirt;
    }
    if (name.contains('haircut') ||
        name.contains('hair') ||
        name.contains('salon')) {
      return LucideIcons.scissors;
    }
    if (name.contains('health') ||
        name.contains('medicine') ||
        name.contains('medical')) {
      return LucideIcons.heartPulse;
    }
    if (name.contains('personal care') || name.contains('hygiene')) {
      return LucideIcons.sparkles;
    }

    // Entertainment
    if (name.contains('game') || name.contains('gaming')) {
      return LucideIcons.gamepad2;
    }
    if (name.contains('movie') ||
        name.contains('cinema') ||
        name.contains('theater')) {
      return LucideIcons.film;
    }
    if (name.contains('event') ||
        name.contains('concert') ||
        name.contains('show')) {
      return LucideIcons.ticket;
    }
    if (name.contains('hobby') || name.contains('hobbies')) {
      return LucideIcons.palette;
    }

    // Savings & Investments
    if (name.contains('saving') || name.contains('emergency fund')) {
      return LucideIcons.piggyBank;
    }
    if (name.contains('investment') ||
        name.contains('stock') ||
        name.contains('crypto')) {
      return LucideIcons.trendingUp;
    }
    if (name.contains('holiday') ||
        name.contains('vacation') ||
        name.contains('travel')) {
      return LucideIcons.plane;
    }

    // Education
    if (name.contains('education') ||
        name.contains('school') ||
        name.contains('tuition')) {
      return LucideIcons.graduationCap;
    }
    if (name.contains('book') ||
        name.contains('course') ||
        name.contains('learning')) {
      return LucideIcons.bookOpen;
    }

    // Other common items
    if (name.contains('subscription') || name.contains('membership')) {
      return LucideIcons.repeat;
    }
    if (name.contains('bill') || name.contains('payment')) {
      return LucideIcons.fileText;
    }
    if (name.contains('bank') ||
        name.contains('fee') ||
        name.contains('charge')) {
      return LucideIcons.landmark;
    }
    if (name.contains('gift') || name.contains('present')) {
      return LucideIcons.gift;
    }
    if (name.contains('charity') || name.contains('donation')) {
      return LucideIcons.heartHandshake;
    }

    // Default fallback
    return LucideIcons.receipt;
  }
}
