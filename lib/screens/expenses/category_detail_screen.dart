import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../models/category.dart';
import '../../models/item.dart';
import '../../providers/providers.dart';
import '../../widgets/budget/budget_widgets.dart';
import 'item_form_sheet.dart';

class CategoryDetailScreen extends ConsumerWidget {
  final String categoryId;

  const CategoryDetailScreen({
    super.key,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryAsync = ref.watch(categoryByIdProvider(categoryId));

    return categoryAsync.when(
      data: (category) {
        if (category == null) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: const Center(
              child: Text('Category not found'),
            ),
          );
        }
        return _buildScreen(context, ref, category);
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

  Widget _buildScreen(BuildContext context, WidgetRef ref, Category category) {
    final items = category.items ?? [];

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categoryByIdProvider(categoryId));
          ref.invalidate(categoriesProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Colored Header
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              leading: IconButton(
                icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              backgroundColor: category.colorValue,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        category.colorValue,
                        category.colorValue.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                                ),
                                child: Icon(
                                  _getIcon(category.icon),
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  category.name,
                                  style: AppTypography.h2.copyWith(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildSummaryCard(category),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
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
                    const Text('Items', style: AppTypography.h3),
                    Text(
                      '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                      style: AppTypography.bodySmall,
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
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _buildItemCard(context, ref, category, item),
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
    );
  }

  Widget _buildSummaryCard(Category category) {
    final isOverBudget = category.isOverBudget;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Budget',
                style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
              ),
              Text(
                '\u00A3${category.totalProjected.toStringAsFixed(0)}',
                style: AppTypography.amountSmall.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent',
                style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
              ),
              Text(
                '\u00A3${category.totalActual.toStringAsFixed(0)}',
                style: AppTypography.amountSmall.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          BudgetProgressBar(
            projected: category.totalProjected,
            actual: category.totalActual,
            color: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isOverBudget ? 'Over budget' : 'Remaining',
                style: AppTypography.bodySmall.copyWith(color: Colors.white70),
              ),
              Text(
                '${isOverBudget ? '+' : ''}\u00A3${category.difference.abs().toStringAsFixed(0)}',
                style: TextStyle(
                  color: isOverBudget ? Colors.red.shade200 : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    WidgetRef ref,
    Category category,
    Item item,
  ) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        ),
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmation(context, item);
      },
      onDismissed: (direction) {
        ref.read(itemNotifierProvider(categoryId).notifier).deleteItem(item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.name} deleted')),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEditSheet(context, ref, category, item),
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
          child: Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: item.isOverBudget
                  ? AppColors.error.withValues(alpha: 0.1)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizing.radiusLg),
              border: item.isOverBudget
                  ? Border.all(color: AppColors.error.withValues(alpha: 0.3))
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: AppTypography.labelLarge,
                      ),
                    ),
                    _buildItemStatusBadge(item),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '\u00A3${item.actual.toStringAsFixed(0)} / \u00A3${item.projected.toStringAsFixed(0)}',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                BudgetProgressBar(
                  projected: item.projected,
                  actual: item.actual,
                  color: category.colorValue,
                ),
                if (item.notes != null && item.notes!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    item.notes!,
                    style: AppTypography.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemStatusBadge(Item item) {
    String label;
    Color color;

    if (item.projected <= 0) {
      label = 'No budget';
      color = AppColors.textMuted;
    } else if (item.isOverBudget) {
      label = '+\u00A3${(item.actual - item.projected).toStringAsFixed(0)}';
      color = AppColors.error;
    } else if (item.actual == item.projected) {
      label = 'On budget';
      color = AppColors.success;
    } else if (item.actual == 0) {
      label = 'Pending';
      color = AppColors.textMuted;
    } else {
      label = 'Under budget';
      color = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizing.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, WidgetRef ref, Category category) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showAddSheet(context, ref, category),
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        child: Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizing.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.plus, color: category.colorValue, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Add Item',
                style: TextStyle(
                  color: category.colorValue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, Category category) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(category.icon),
            size: 48,
            color: category.colorValue.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'No items yet',
            style: AppTypography.h3,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Add budget items to track your spending in this category',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: () => _showAddSheet(context, ref, category),
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('Add Item'),
          ),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref, Category category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ItemFormSheet(categoryId: category.id),
    );
  }

  void _showEditSheet(
    BuildContext context,
    WidgetRef ref,
    Category category,
    Item item,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ItemFormSheet(
        categoryId: category.id,
        item: item,
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context, Item item) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
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
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  IconData _getIcon(String iconName) {
    final icons = {
      'home': LucideIcons.home,
      'utensils': LucideIcons.utensils,
      'car': LucideIcons.car,
      'tv': LucideIcons.tv,
      'shopping-bag': LucideIcons.shoppingBag,
      'gamepad-2': LucideIcons.gamepad2,
      'piggy-bank': LucideIcons.piggyBank,
      'graduation-cap': LucideIcons.graduationCap,
      'heart': LucideIcons.heart,
      'wallet': LucideIcons.wallet,
      'briefcase': LucideIcons.briefcase,
      'plane': LucideIcons.plane,
      'gift': LucideIcons.gift,
      'credit-card': LucideIcons.creditCard,
      'landmark': LucideIcons.landmark,
      'baby': LucideIcons.baby,
      'dumbbell': LucideIcons.dumbbell,
      'music': LucideIcons.music,
      'book': LucideIcons.book,
    };
    return icons[iconName] ?? LucideIcons.wallet;
  }
}
