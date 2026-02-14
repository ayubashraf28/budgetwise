part of 'category_detail_screen.dart';

extension _CategoryDetailYearMode on CategoryDetailScreen {
  Widget _buildYearMode(
      BuildContext context, WidgetRef ref, String currencySymbol) {
    final palette = NeoTheme.of(context);
    final isSimpleMode = ref.watch(isSimpleBudgetModeProvider);
    final yearDataAsync = ref.watch(yearlyCategoryDetailProvider(categoryId));
    final activeMonth = ref.watch(activeMonthProvider);
    final yearLabel = activeMonth.value?.startDate.year.toString() ?? '';

    return yearDataAsync.when(
      data: (data) {
        if (data == null) {
          return Scaffold(
            backgroundColor: NeoTheme.of(context).appBg,
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: const [NeoSettingsAppBarAction()],
            ),
            body: const Center(child: Text('Category not found')),
          );
        }

        final category = data.category;
        final transactions = data.transactions;
        final color = category.colorValue;
        final accentColor = NeoTheme.accentCardTone(context, color);

        return Scaffold(
          backgroundColor: NeoTheme.of(context).appBg,
          body: NeoPageBackground(
            child: CustomScrollView(
              slivers: [
                // Header
                SliverAppBar(
                  leading: IconButton(
                    icon: const Icon(LucideIcons.arrowLeft),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: Text('${category.name} — $yearLabel'),
                  actions: const [NeoSettingsAppBarAction()],
                  floating: true,
                  backgroundColor: palette.appBg,
                ),
                // Summary card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: NeoTheme.accentCardSurface(context, color),
                        borderRadius: BorderRadius.circular(AppSizing.radiusXl),
                        border: Border.all(
                          color: NeoTheme.accentCardBorder(context, color),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Year Total',
                            style: TextStyle(
                              color: accentColor.withValues(alpha: 0.82),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '$currencySymbol${category.totalActual.toStringAsFixed(0)}',
                            style: AppTypography.amountMedium
                                .copyWith(color: accentColor),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${transactions.length} transactions',
                            style: TextStyle(
                              color: accentColor.withValues(alpha: 0.74),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Items
                if (!isSimpleMode &&
                    category.items != null &&
                    category.items!.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.md,
                        AppSpacing.xs,
                      ),
                      child: AdaptiveHeadingText(text: 'Items'),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = category.items![index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: palette.surface1,
                              borderRadius:
                                  BorderRadius.circular(AppSizing.radiusLg),
                              border: Border.all(
                                color: palette.stroke.withValues(alpha: 0.7),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: palette.textPrimary,
                                    ),
                                  ),
                                ),
                                Text(
                                  '$currencySymbol${item.actual.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: category.items!.length,
                    ),
                  ),
                ],
                // Transactions header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.xs,
                    ),
                    child: AdaptiveHeadingText(
                      text: 'Transactions (${transactions.length})',
                    ),
                  ),
                ),
                // Transaction list
                if (transactions.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Center(
                        child: Text(
                          'No transactions yet',
                          style: NeoTypography.rowSecondary(context),
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final tx = transactions[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: palette.surface1,
                              borderRadius:
                                  BorderRadius.circular(AppSizing.radiusLg),
                              border: Border.all(color: palette.stroke),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        transactionPrimaryLabel(
                                          tx,
                                          isSimpleMode: isSimpleMode,
                                        ),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: palette.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${tx.date.day}/${tx.date.month}/${tx.date.year}',
                                        style:
                                            NeoTypography.rowSecondary(context),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  tx.formattedAmount(currencySymbol),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: tx.isExpense
                                        ? NeoTheme.negativeValue(context)
                                        : NeoTheme.positiveValue(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: transactions.length,
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxl),
                ),
              ],
            ),
          ),
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
      error: (error, stackTrace) => Scaffold(
        backgroundColor: NeoTheme.of(context).appBg,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: const [NeoSettingsAppBarAction()],
        ),
        body: Center(
          child: Text(
            ErrorMapper.toUserMessage(error, stackTrace: stackTrace),
          ),
        ),
      ),
    );
  }
}
