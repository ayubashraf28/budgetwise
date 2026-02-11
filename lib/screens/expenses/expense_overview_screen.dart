import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../models/category.dart';
import '../../models/transaction.dart';
import '../../providers/providers.dart';
import '../../utils/app_icon_registry.dart';
import '../../widgets/common/neo_page_components.dart';
import 'category_form_sheet.dart';

class ExpenseOverviewScreen extends ConsumerStatefulWidget {
  const ExpenseOverviewScreen({super.key});

  @override
  ConsumerState<ExpenseOverviewScreen> createState() =>
      _ExpenseOverviewScreenState();
}

class _ExpenseOverviewScreenState extends ConsumerState<ExpenseOverviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(ensureMonthSetupProvider.future);
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);
    final activeMonth = ref.watch(activeMonthProvider);

    if (activeMonth.isLoading || activeMonth.valueOrNull == null) {
      return Scaffold(
        backgroundColor: palette.appBg,
        body: const NeoPageBackground(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final categories = ref.watch(categoriesProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final monthTx = ref.watch(transactionsProvider).valueOrNull ?? [];
    final expenseTransactions =
        monthTx.where((t) => t.type == TransactionType.expense).toList();

    final txCountByCategory = <String, int>{};
    for (final tx in expenseTransactions) {
      final categoryId = tx.categoryId;
      if (categoryId != null) {
        txCountByCategory[categoryId] =
            (txCountByCategory[categoryId] ?? 0) + 1;
      }
    }

    return Scaffold(
      backgroundColor: palette.appBg,
      body: NeoPageBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(categoriesProvider);
            ref.invalidate(transactionsProvider);
          },
          child: categories.when(
            data: (categoryList) {
              final totalActual = categoryList.fold<double>(
                  0.0, (sum, c) => sum + c.totalActual);

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildPageHeader(),
                  ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.sm,
                      ),
                      child: Text(
                        'Categories',
                        style: AppTypography.h3,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.sm,
                      ),
                      child: _buildAddButton(),
                    ),
                  ),
                  if (categoryList.isEmpty)
                    SliverToBoxAdapter(child: _buildEmptyState())
                  else
                    SliverToBoxAdapter(
                      child: _buildCategoryList(
                        categoryList,
                        totalActual,
                        currencySymbol,
                        txCountByCategory,
                      ),
                    ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xxl),
                  ),
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

  Widget _buildPageHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        NeoLayout.screenPadding,
        0,
        NeoLayout.screenPadding,
        AppSpacing.sm,
      ),
      child: NeoPageHeader(
        title: 'Expense Overview',
        subtitle: 'View spending by category',
      ),
    );
  }

  Widget _buildCategoryList(
    List<Category> categoryList,
    double totalActual,
    String currencySymbol,
    Map<String, int> txCountByCategory,
  ) {
    return Column(
      children: categoryList.map((category) {
        final percentage =
            totalActual > 0 ? (category.totalActual / totalActual * 100) : 0.0;
        final txCount = txCountByCategory[category.id] ?? 0;

        return Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.sm,
          ),
          child: _buildCategoryRow(
            category: category,
            percentage: percentage,
            txCount: txCount,
            currencySymbol: currencySymbol,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryRow({
    required Category category,
    required double percentage,
    required int txCount,
    required String currencySymbol,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/expenses/category/${category.id}'),
        onLongPress: () => _showEditSheet(category),
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        child: Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: NeoTheme.of(context).surface1,
            borderRadius: BorderRadius.circular(AppSizing.radiusLg),
            border: Border.all(color: NeoTheme.of(context).stroke),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: category.colorValue,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIcon(category.icon),
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: AppTypography.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$txCount ${txCount == 1 ? 'transaction' : 'transactions'}',
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$currencySymbol${_formatAmount(category.totalActual)}',
                    style: AppTypography.amountSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showAddSheet,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        child: Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizing.radiusLg),
            border: Border.all(color: NeoTheme.of(context).stroke),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.plus,
                color: NeoTheme.positiveValue(context),
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Add Category',
                style: TextStyle(
                  color: NeoTheme.positiveValue(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: NeoTheme.of(context).surface1,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.folderOpen,
            size: 48,
            color: NeoTheme.of(context).textMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'No expense categories yet',
            style: AppTypography.h3,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Add your first expense category to start tracking',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: _showAddSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: NeoTheme.positiveValue(context),
            ),
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('Add Category'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: NeoTheme.negativeValue(context).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.alertCircle,
              size: 48,
              color: NeoTheme.negativeValue(context),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Something went wrong', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return NumberFormat('#,##,###').format(amount.toInt());
    }
    return amount.toStringAsFixed(amount == amount.roundToDouble() ? 0 : 2);
  }

  IconData _getIcon(String iconName) {
    return resolveAppIcon(iconName, fallback: LucideIcons.wallet);
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CategoryFormSheet(),
    );
  }

  void _showEditSheet(Category category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryFormSheet(category: category),
    );
  }
}
