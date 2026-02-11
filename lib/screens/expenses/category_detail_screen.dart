import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../models/category.dart';
import '../../models/item.dart';
import '../../providers/providers.dart';
import '../../utils/app_icon_registry.dart';
import '../../widgets/budget/budget_widgets.dart';
import '../../widgets/common/neo_page_components.dart';
import 'category_form_sheet.dart';
import 'item_form_sheet.dart';

class CategoryDetailScreen extends ConsumerWidget {
  final String categoryId;
  final bool yearMode;
  final String routePrefix;

  const CategoryDetailScreen({
    super.key,
    required this.categoryId,
    this.yearMode = false,
    this.routePrefix = '/budget',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencySymbol = ref.watch(currencySymbolProvider);

    if (yearMode) {
      return _buildYearMode(context, ref, currencySymbol);
    }

    final categoryAsync = ref.watch(categoryByIdProvider(categoryId));

    return categoryAsync.when(
      data: (category) {
        if (category == null) {
          return Scaffold(
            backgroundColor: NeoTheme.of(context).appBg,
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: const [NeoSettingsAppBarAction()],
            ),
            body: const Center(
              child: Text('Category not found'),
            ),
          );
        }
        return _buildScreen(context, ref, category, currencySymbol);
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

  Widget _buildYearMode(
      BuildContext context, WidgetRef ref, String currencySymbol) {
    final palette = NeoTheme.of(context);
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
                if (category.items != null && category.items!.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.md,
                        AppSpacing.xs,
                      ),
                      child: const AdaptiveHeadingText(text: 'Items'),
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
                                        tx.displayName,
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
      error: (error, _) => Scaffold(
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

  Widget _buildScreen(BuildContext context, WidgetRef ref, Category category,
      String currencySymbol) {
    final palette = NeoTheme.of(context);
    final items = category.items ?? [];

    return Scaffold(
      backgroundColor: NeoTheme.of(context).appBg,
      body: NeoPageBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(categoryByIdProvider(categoryId));
            ref.invalidate(categoriesProvider);
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
                            SizedBox(width: 8),
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
                  child: _buildEmptyState(context, ref, category),
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
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _buildItemCard(
                              context, ref, category, item, currencySymbol),
                        );
                      },
                      childCount: items.length,
                    ),
                  ),
                ),

              // Add Button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: _buildAddButton(context, ref, category),
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
            color: (item.isOverBudget)
                ? NeoTheme.negativeValue(context).withValues(alpha: 0.08)
                : palette.surface1,
            borderRadius: BorderRadius.circular(AppSizing.radiusLg),
            border: Border.all(
              color: (item.isOverBudget)
                  ? NeoTheme.negativeValue(context).withValues(alpha: 0.2)
                  : palette.stroke.withValues(alpha: 0.7),
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
                        _buildItemStatusBadge(context, item, currencySymbol),
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
                        if (category.isBudgeted && item.isBudgeted) ...[
                          const SizedBox(width: 4),
                          Text(
                            '/ $currencySymbol${item.projected.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: palette.textSecondary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                        if (!item.isBudgeted && category.isBudgeted) ...[
                          const SizedBox(width: 4),
                          Text(
                            'spending only',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (category.isBudgeted && item.isBudgeted) ...[
                      const SizedBox(height: 8),
                      BudgetProgressBar(
                        projected: item.projected,
                        actual: item.actual,
                        color: color,
                      ),
                    ],
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

  Widget _buildItemStatusBadge(
      BuildContext context, Item item, String currencySymbol) {
    final palette = NeoTheme.of(context);
    String label;
    Color color;

    if (!item.isBudgeted || item.projected <= 0) {
      label = item.actual > 0
          ? '${item.actual.toStringAsFixed(0)} spent'
          : 'No spending';
      color = palette.textMuted;
    } else if (item.isOverBudget) {
      label =
          '+$currencySymbol${(item.actual - item.projected).toStringAsFixed(0)}';
      color = NeoTheme.negativeValue(context);
    } else if (item.actual == item.projected) {
      label = 'On budget';
      color = NeoTheme.positiveValue(context);
    } else if (item.actual == 0) {
      label = 'Pending';
      color = palette.textMuted;
    } else {
      label = 'Under budget';
      color = NeoTheme.positiveValue(context);
    }

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

  Widget _buildAddButton(
      BuildContext context, WidgetRef ref, Category category) {
    final palette = NeoTheme.of(context);
    final color = category.colorValue;

    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAddSheet(context, ref, category),
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md + 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSizing.radiusSm),
                  ),
                  child: Icon(
                    LucideIcons.plus,
                    size: 12,
                    color: color,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Add Item',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: color,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, WidgetRef ref, Category category) {
    final palette = NeoTheme.of(context);
    final color = category.colorValue;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.xl),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSizing.radiusMd),
            ),
            child: Icon(
              _getIcon(category.icon),
              size: 28,
              color: color,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No items yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Add budget items to track your spending in this category',
            style: TextStyle(
              fontSize: 13,
              color: palette.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
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
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showAddSheet(context, ref, category),
                borderRadius: BorderRadius.circular(AppSizing.radiusLg),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md + 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(AppSizing.radiusSm),
                        ),
                        child: Icon(
                          LucideIcons.plus,
                          size: 12,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Add Item',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: color,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddSheet(
      BuildContext context, WidgetRef ref, Category category) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ItemFormSheet(
        categoryId: category.id,
        categoryIsBudgeted: category.isBudgeted,
      ),
    );
    // Refresh the category data after adding item
    ref.invalidate(categoryByIdProvider(categoryId));
  }

  Future<bool> _showDeleteConfirmation(BuildContext context, Item item) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: NeoTheme.of(context).surface1,
            title: const Text('Delete Item?'),
            content: Text(
              'This will delete "${item.name}" and all its transactions. This action cannot be undone.',
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

  void _showEditCategorySheet(
      BuildContext context, WidgetRef ref, Category category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryFormSheet(category: category),
    );
  }

  Future<void> _showDeleteCategoryConfirmation(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NeoTheme.of(context).surface1,
        title: const Text('Delete Category?'),
        content: Text(
          'This will permanently delete "${category.name}" and all its items and transactions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: NeoTheme.negativeValue(context),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref
          .read(categoryNotifierProvider.notifier)
          .deleteCategory(category.id);
      if (context.mounted) {
        Navigator.of(context).pop(); // Navigate back after deletion
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${category.name} deleted')),
        );
      }
    }
  }

  IconData _getIcon(String iconName) {
    return resolveAppIcon(iconName, fallback: LucideIcons.wallet);
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
