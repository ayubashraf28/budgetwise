import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../models/category.dart';
import '../../models/item.dart';
import '../../providers/providers.dart';
import '../../widgets/budget/budget_widgets.dart';
import 'category_form_sheet.dart';
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
    final currencySymbol = ref.watch(currencySymbolProvider);

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
        return _buildScreen(context, ref, category, currencySymbol);
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

  Widget _buildScreen(BuildContext context, WidgetRef ref, Category category,
      String currencySymbol) {
    final items = category.items ?? [];

    final color = category.colorValue;

    return Scaffold(
      body: RefreshIndicator(
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
                  color: AppColors.surface,
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditCategorySheet(context, ref, category);
                      case 'delete':
                        _showDeleteCategoryConfirmation(context, ref, category);
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
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(LucideIcons.trash2,
                              size: 18, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Delete Category',
                              style: TextStyle(color: AppColors.error)),
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
              child: _buildGlassSummaryCard(category, currencySymbol),
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
    );
  }

  Widget _buildGlassSummaryCard(Category category, String currencySymbol) {
    final color = category.colorValue;
    final isOverBudget = category.isOverBudget;

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
            // Icon + Category name row
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
                    _getIcon(category.icon),
                    size: 18,
                    color: color,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
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
                  style: AppTypography.amountMedium.copyWith(color: color),
                ),
                Text(
                  ' / $currencySymbol${category.totalProjected.toStringAsFixed(0)}',
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
              projected: category.totalProjected,
              actual: category.totalActual,
              color: color,
              backgroundColor: color.withValues(alpha: 0.3),
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

  Widget _buildItemCard(
    BuildContext context,
    WidgetRef ref,
    Category category,
    Item item,
    String currencySymbol,
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
        // Refresh the category data after delete
        ref.invalidate(categoryByIdProvider(categoryId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.name} deleted')),
        );
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          context.push('/budget/category/${category.id}/item/${item.id}');
        },
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
                  _buildItemStatusBadge(item, currencySymbol),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '$currencySymbol${item.actual.toStringAsFixed(0)} / $currencySymbol${item.projected.toStringAsFixed(0)}',
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
              const SizedBox(height: AppSpacing.sm),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap:
                    () {}, // Consume tap to prevent parent onTap from triggering
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () async {
                        await _showEditSheet(context, ref, category, item);
                        // Refresh the category data after edit
                        ref.invalidate(categoryByIdProvider(categoryId));
                      },
                      borderRadius: BorderRadius.circular(AppSizing.radiusSm),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.pencil,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Edit',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    InkWell(
                      onTap: () async {
                        final confirmed =
                            await _showDeleteConfirmation(context, item);
                        if (confirmed && context.mounted) {
                          await ref
                              .read(itemNotifierProvider(categoryId).notifier)
                              .deleteItem(item.id);
                          // Refresh the category data after delete
                          ref.invalidate(categoryByIdProvider(categoryId));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${item.name} deleted')),
                            );
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(AppSizing.radiusSm),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.trash2,
                              size: 14,
                              color: AppColors.error,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Delete',
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemStatusBadge(Item item, String currencySymbol) {
    String label;
    Color color;

    if (item.projected <= 0) {
      label = 'No budget';
      color = AppColors.textMuted;
    } else if (item.isOverBudget) {
      label =
          '+$currencySymbol${(item.actual - item.projected).toStringAsFixed(0)}';
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

  Widget _buildAddButton(
      BuildContext context, WidgetRef ref, Category category) {
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

  Widget _buildEmptyState(
      BuildContext context, WidgetRef ref, Category category) {
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

  Future<void> _showAddSheet(
      BuildContext context, WidgetRef ref, Category category) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ItemFormSheet(categoryId: category.id),
    );
    // Refresh the category data after adding item
    ref.invalidate(categoryByIdProvider(categoryId));
  }

  Future<void> _showEditSheet(
    BuildContext context,
    WidgetRef ref,
    Category category,
    Item item,
  ) async {
    await showModalBottomSheet(
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
        backgroundColor: AppColors.surface,
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
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
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
