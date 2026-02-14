part of 'category_detail_screen.dart';

extension _CategoryDetailContent on CategoryDetailScreen {
  Widget _buildScreen(BuildContext context, WidgetRef ref, Category category,
      String currencySymbol) {
    final palette = NeoTheme.of(context);
    final isSimpleMode = ref.watch(isSimpleBudgetModeProvider);
    final items = category.items ?? [];
    final categoryTransactions = isSimpleMode
        ? ref.watch(transactionsByCategoryProvider(categoryId)).value ??
            const <Transaction>[]
        : const <Transaction>[];
    final groupedTransactions = _groupTransactionsByDate(categoryTransactions);
    final groupedDates = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: NeoTheme.of(context).appBg,
      body: NeoPageBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(categoryByIdProvider(categoryId));
            ref.invalidate(categoriesProvider);
            if (isSimpleMode) {
              ref.invalidate(transactionsByCategoryProvider(categoryId));
            }
          },
          child: CustomScrollView(
            slivers: [
              // App Bar
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
                          _showEditCategorySheet(context, ref, category);
                        case 'delete':
                          _showDeleteCategoryConfirmation(
                              context, ref, category);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(LucideIcons.pencil, size: 18),
                            SizedBox(width: 8),
                            Text('Edit Category'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(LucideIcons.trash2,
                                size: 18,
                                color: NeoTheme.negativeValue(context)),
                            const SizedBox(width: 8),
                            Text('Delete Category',
                                style: TextStyle(
                                  color: NeoTheme.negativeValue(context),
                                )),
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
                child:
                    _buildGlassSummaryCard(context, category, currencySymbol),
              ),

              if (isSimpleMode) ...[
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
                            '${categoryTransactions.length} ${categoryTransactions.length == 1 ? 'transaction' : 'transactions'}',
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
                if (categoryTransactions.isEmpty)
                  SliverToBoxAdapter(
                    child: _buildEmptyState(
                      context,
                      ref,
                      category,
                      isSimpleMode: true,
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final date = groupedDates[index];
                        final dayTransactions = groupedTransactions[date]!;
                        return _buildSimpleTransactionDateGroup(
                          context,
                          ref,
                          category,
                          date: date,
                          transactions: dayTransactions,
                          currencySymbol: currencySymbol,
                        );
                      },
                      childCount: groupedDates.length,
                    ),
                  ),
              ] else ...[
                // Items Section Title
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
                            text: 'Items',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            '${items.length} ${items.length == 1 ? 'item' : 'items'}',
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

                // Items List
                if (items.isEmpty)
                  SliverToBoxAdapter(
                    child: _buildEmptyState(
                      context,
                      ref,
                      category,
                      isSimpleMode: false,
                    ),
                  )
                else
                  SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = items[index];
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: _buildItemCard(
                              context,
                              ref,
                              category,
                              item,
                              currencySymbol,
                            ),
                          );
                        },
                        childCount: items.length,
                      ),
                    ),
                  ),
              ],

              // Add Button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: _buildAddButton(
                    context,
                    ref,
                    category,
                    isSimpleMode: isSimpleMode,
                  ),
                ),
              ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.xl),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassSummaryCard(
      BuildContext context, Category category, String currencySymbol) {
    final color = category.colorValue;
    final accentColor = NeoTheme.accentCardTone(context, color);
    final isOverBudget = category.isOverBudget;

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
            // Icon + Category name row
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
                    _getIcon(category.icon),
                    size: 18,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Amount
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$currencySymbol${category.totalActual.toStringAsFixed(0)}',
                  style:
                      AppTypography.amountMedium.copyWith(color: accentColor),
                ),
                if (category.isBudgeted)
                  Text(
                    ' / $currencySymbol${category.totalProjected.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: accentColor.withValues(alpha: 0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (!category.isBudgeted)
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
            if (category.isBudgeted) ...[
              const SizedBox(height: AppSpacing.sm),
              // Progress bar
              BudgetProgressBar(
                projected: category.totalProjected,
                actual: category.totalActual,
                color: accentColor,
                backgroundColor: accentColor.withValues(alpha: 0.28),
              ),
              const SizedBox(height: AppSpacing.xs),
              // Status text
              Text(
                isOverBudget
                    ? '$currencySymbol${category.difference.abs().toStringAsFixed(0)} over budget'
                    : '$currencySymbol${category.difference.abs().toStringAsFixed(0)} remaining',
                style: TextStyle(
                  fontSize: 12,
                  color: isOverBudget
                      ? NeoTheme.negativeValue(context)
                      : accentColor.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    WidgetRef ref,
    Category category,
    Item item,
    String currencySymbol,
  ) {
    final palette = NeoTheme.of(context);
    final color = category.colorValue;

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        decoration: BoxDecoration(
          color: NeoTheme.negativeValue(context),
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        ),
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmation(context, item);
      },
      onDismissed: (direction) {
        ref.read(itemNotifierProvider(categoryId).notifier).deleteItem(item.id);
        // Refresh the category data after delete
        ref.invalidate(categoryByIdProvider(categoryId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.name} deleted')),
        );
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          context.push('$routePrefix/category/${category.id}/item/${item.id}');
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: palette.surface1,
            borderRadius: BorderRadius.circular(AppSizing.radiusLg),
            border: Border.all(
              color: palette.stroke.withValues(alpha: 0.7),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                ),
                child: Icon(
                  _getItemIcon(item.name),
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: palette.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        _buildItemStatusBadge(context, item),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$currencySymbol${item.actual.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: color,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'spent',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: palette.textSecondary,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.actual.toStringAsFixed(0)} total spent',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Chevron
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: palette.textMuted.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemStatusBadge(BuildContext context, Item item) {
    final palette = NeoTheme.of(context);
    final label = item.actual > 0 ? 'Spent' : 'No spending';
    final color =
        item.actual > 0 ? NeoTheme.warningValue(context) : palette.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizing.radiusFull),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
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

  Widget _buildSimpleTransactionDateGroup(
    BuildContext context,
    WidgetRef ref,
    Category category, {
    required DateTime date,
    required List<Transaction> transactions,
    required String currencySymbol,
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
              final txIndex = entry.key;
              final tx = entry.value;
              final isLast = txIndex == transactions.length - 1;

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
                    confirmDismiss: (_) =>
                        _showDeleteTransactionConfirmation(context),
                    onDismissed: (_) {
                      ref
                          .read(transactionNotifierProvider.notifier)
                          .deleteTransaction(tx.id);
                      _invalidateAfterTransactionChange(ref, category.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Transaction deleted')),
                      );
                    },
                    child: TransactionListItem(
                      transaction: tx,
                      currencySymbol: currencySymbol,
                      useSimpleLabel: true,
                      onTap: () => _showEditTransactionSheet(
                        context,
                        ref,
                        category.id,
                        tx,
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

  Future<void> _showEditTransactionSheet(
    BuildContext context,
    WidgetRef ref,
    String categoryId,
    Transaction tx,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionFormSheet(transaction: tx),
    );
    _invalidateAfterTransactionChange(ref, categoryId);
  }

  Future<bool> _showDeleteTransactionConfirmation(BuildContext context) async {
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

  void _invalidateAfterTransactionChange(WidgetRef ref, String categoryId) {
    ref.invalidate(transactionsByCategoryProvider(categoryId));
    ref.invalidate(transactionsProvider);
    ref.invalidate(categoryByIdProvider(categoryId));
    ref.invalidate(categoriesProvider);
  }
}
