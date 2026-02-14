part of 'home_screen.dart';

extension _HomeScreenRecent on _HomeScreenState {
  Widget _buildRecentTransactions(
    AsyncValue<List<Transaction>> transactions,
    String currencySymbol,
    bool isExpanded,
  ) {
    final isSimpleMode = ref.watch(isSimpleBudgetModeProvider);
    return transactions.when(
      data: (list) {
        final recent = [...list]..sort((a, b) => b.date.compareTo(a.date));
        final visible = recent.take(5).toList();

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            _HomeScreenState._homeHorizontalPadding,
            0,
            _HomeScreenState._homeHorizontalPadding,
            _HomeScreenState._homeSectionSpacing,
          ),
          child: _buildGlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            tintColor: _neoSurface1,
            borderColor: _neoStroke,
            borderRadius:
                BorderRadius.circular(_HomeScreenState._homeCardRadius),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AdaptiveHeadingText(
                        text: 'Recent transactions',
                        style: _sectionTitleStyle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildSectionActionButton(
                      label: 'View all',
                      icon: LucideIcons.list,
                      onPressed: () => context.push('/transactions'),
                    ),
                    const SizedBox(width: 8),
                    _buildSectionChevronButton(
                      expanded: isExpanded,
                      onPressed: () {
                        ref
                            .read(uiPreferencesProvider.notifier)
                            .setSectionExpanded(
                              UiSectionKeys.homeRecentTransactions,
                              !isExpanded,
                            );
                      },
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const SizedBox(height: AppSpacing.sm),
                  if (visible.isEmpty)
                    _buildEmptyRecentTransactions()
                  else
                    Column(
                      children: [
                        for (var index = 0;
                            index < visible.length;
                            index++) ...[
                          _buildRecentTransactionRow(
                            visible[index],
                            currencySymbol,
                            isSimpleMode: isSimpleMode,
                          ),
                          if (index < visible.length - 1)
                            Divider(
                              height: 16,
                              color: _neoStroke.withValues(alpha: 0.85),
                            ),
                        ],
                      ],
                    ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.fromLTRB(
          _HomeScreenState._homeHorizontalPadding,
          0,
          _HomeScreenState._homeHorizontalPadding,
          _HomeScreenState._homeSectionSpacing,
        ),
        child: _buildGlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          tintColor: _neoSurface1,
          borderColor: _neoStroke,
          borderRadius: BorderRadius.circular(_HomeScreenState._homeCardRadius),
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildGlassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(AppSpacing.md),
    BorderRadius? borderRadius,
    Color? borderColor,
    Color? tintColor,
    List<Color>? gradientColors,
  }) {
    final radius =
        borderRadius ?? BorderRadius.circular(_HomeScreenState._homeCardRadius);
    final resolvedBorderColor = borderColor ?? _neoStroke;
    final resolvedTintColor = tintColor ?? _neoSurface1;
    final shadowColor = _isLightMode(context)
        ? Colors.black.withValues(alpha: 0.16)
        : _neoAppBg.withValues(alpha: 0.9);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: resolvedTintColor,
        gradient: gradientColors == null
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
        borderRadius: radius,
        border: Border.all(color: resolvedBorderColor),
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

  Widget _buildEmptyRecentTransactions() {
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
              LucideIcons.receipt,
              color: _neoTextSecondary,
              size: NeoIconSizes.xl,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No transactions yet',
            style: _rowTitleStyle,
          ),
          const SizedBox(height: 2),
          Text(
            'Start by adding your first transaction',
            style: _rowSecondaryStyle,
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: () => _showAddTransaction(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _neoLime,
              foregroundColor:
                  _isLightMode(context) ? _neoTextPrimary : _neoSurface1,
            ),
            icon: const Icon(LucideIcons.plus, size: NeoIconSizes.md),
            label: const Text('Add transaction'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionRow(
    Transaction transaction,
    String currencySymbol, {
    required bool isSimpleMode,
  }) {
    final amountColor = transaction.isIncome ? _positiveColor : _negativeColor;

    return InkWell(
      onTap: () => context.push('/transactions'),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: _HomeScreenState._homeRowVerticalPadding),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _neoSurface2,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: _neoStroke),
              ),
              child: Icon(
                _getTransactionIcon(transaction),
                size: NeoIconSizes.lg,
                color: amountColor,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transactionPrimaryLabel(
                      transaction,
                      isSimpleMode: isSimpleMode,
                    ),
                    style: _rowTitleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${transaction.isIncome ? 'Income' : (transaction.categoryName ?? 'Expense')} • ${DateFormat('MMM d, yyyy').format(transaction.date)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _rowSecondaryStyle,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  transaction.formattedAmount(currencySymbol),
                  style: _rowAmountStyle(amountColor),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.isIncome ? 'Received' : 'Paid',
                  style: _rowSecondaryStyle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount.abs() >= 100000) {
      return NumberFormat('#,##0').format(amount.round());
    }
    if (amount == amount.roundToDouble()) {
      return NumberFormat('#,##0').format(amount.round());
    }
    return NumberFormat('#,##0.##').format(amount);
  }

  IconData _getTransactionIcon(Transaction transaction) {
    if (transaction.isIncome) {
      return LucideIcons.arrowDownLeft;
    }

    final iconName = transaction.subscriptionIcon ?? transaction.categoryIcon;
    if (iconName != null && iconName.trim().isNotEmpty) {
      return resolveAppIcon(iconName, fallback: LucideIcons.receipt);
    }

    final name = (transaction.categoryName ??
            transaction.subscriptionName ??
            transaction.displayName)
        .toLowerCase();

    if (name.contains('food') || name.contains('restaurant')) {
      return LucideIcons.utensils;
    }
    if (name.contains('transport') || name.contains('car')) {
      return LucideIcons.car;
    }
    if (name.contains('home') || name.contains('housing')) {
      return LucideIcons.home;
    }
    if (name.contains('entertainment') || name.contains('game')) {
      return LucideIcons.gamepad2;
    }
    if (name.contains('shopping')) {
      return LucideIcons.shoppingBag;
    }
    if (name.contains('health')) {
      return LucideIcons.heart;
    }
    if (name.contains('gift')) {
      return LucideIcons.gift;
    }
    if (name.contains('subscription') || name.contains('membership')) {
      return LucideIcons.repeat;
    }

    return LucideIcons.receipt;
  }

  IconData _getAccountTypeIcon(AccountType type) {
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

  IconData _getIcon(String iconName) {
    return resolveAppIcon(iconName, fallback: LucideIcons.creditCard);
  }

  void _showAddTransaction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TransactionFormSheet(),
    );
  }
}
