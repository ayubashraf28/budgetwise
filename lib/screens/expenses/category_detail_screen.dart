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
    final color = category.colorValue;

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
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: item.isOverBudget
                ? AppColors.error.withValues(alpha: 0.08)
                : AppColors.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(AppSizing.radiusLg),
            border: Border.all(
              color: item.isOverBudget
                  ? AppColors.error.withValues(alpha: 0.2)
                  : AppColors.border.withValues(alpha: 0.5),
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
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        _buildItemStatusBadge(item, currencySymbol),
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
                          '/ $currencySymbol${item.projected.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    BudgetProgressBar(
                      projected: item.projected,
                      actual: item.actual,
                      color: color,
                      backgroundColor: color.withValues(alpha: 0.15),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Chevron
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: AppColors.textMuted.withValues(alpha: 0.4),
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
    final color = category.colorValue;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
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
    final color = category.colorValue;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
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
          const Text(
            'No items yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Add budget items to track your spending in this category',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(AppSizing.radiusLg),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.5),
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
    if (name.contains('internet') || name.contains('wifi') || name.contains('broadband')) {
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
    if (name.contains('grocery') || name.contains('groceries') || name.contains('food')) {
      return LucideIcons.shoppingCart;
    }
    if (name.contains('dining') || name.contains('restaurant') || name.contains('eat out')) {
      return LucideIcons.utensilsCrossed;
    }
    if (name.contains('coffee') || name.contains('cafe')) {
      return LucideIcons.coffee;
    }
    if (name.contains('takeaway') || name.contains('takeout') || name.contains('delivery')) {
      return LucideIcons.package;
    }

    // Transport
    if (name.contains('fuel') || name.contains('petrol') || name.contains('gasoline')) {
      return LucideIcons.fuel;
    }
    if (name.contains('public transport') || name.contains('bus') || name.contains('train') || name.contains('metro')) {
      return LucideIcons.bus;
    }
    if (name.contains('uber') || name.contains('taxi') || name.contains('cab')) {
      return LucideIcons.car;
    }
    if (name.contains('parking')) {
      return LucideIcons.parkingCircle;
    }

    // Subscriptions & Services
    if (name.contains('netflix') || name.contains('streaming') || name.contains('video')) {
      return LucideIcons.tv;
    }
    if (name.contains('spotify') || name.contains('music') || name.contains('audio')) {
      return LucideIcons.music;
    }
    if (name.contains('gym') || name.contains('fitness') || name.contains('workout')) {
      return LucideIcons.dumbbell;
    }
    if (name.contains('phone') || name.contains('mobile')) {
      return LucideIcons.smartphone;
    }
    if (name.contains('cloud') || name.contains('storage')) {
      return LucideIcons.cloud;
    }

    // Personal & Shopping
    if (name.contains('clothing') || name.contains('clothes') || name.contains('apparel')) {
      return LucideIcons.shirt;
    }
    if (name.contains('haircut') || name.contains('hair') || name.contains('salon')) {
      return LucideIcons.scissors;
    }
    if (name.contains('health') || name.contains('medicine') || name.contains('medical')) {
      return LucideIcons.heartPulse;
    }
    if (name.contains('personal care') || name.contains('hygiene')) {
      return LucideIcons.sparkles;
    }

    // Entertainment
    if (name.contains('game') || name.contains('gaming')) {
      return LucideIcons.gamepad2;
    }
    if (name.contains('movie') || name.contains('cinema') || name.contains('theater')) {
      return LucideIcons.film;
    }
    if (name.contains('event') || name.contains('concert') || name.contains('show')) {
      return LucideIcons.ticket;
    }
    if (name.contains('hobby') || name.contains('hobbies')) {
      return LucideIcons.palette;
    }

    // Savings & Investments
    if (name.contains('saving') || name.contains('emergency fund')) {
      return LucideIcons.piggyBank;
    }
    if (name.contains('investment') || name.contains('stock') || name.contains('crypto')) {
      return LucideIcons.trendingUp;
    }
    if (name.contains('holiday') || name.contains('vacation') || name.contains('travel')) {
      return LucideIcons.plane;
    }

    // Education
    if (name.contains('education') || name.contains('school') || name.contains('tuition')) {
      return LucideIcons.graduationCap;
    }
    if (name.contains('book') || name.contains('course') || name.contains('learning')) {
      return LucideIcons.bookOpen;
    }

    // Other common items
    if (name.contains('subscription') || name.contains('membership')) {
      return LucideIcons.repeat;
    }
    if (name.contains('bill') || name.contains('payment')) {
      return LucideIcons.fileText;
    }
    if (name.contains('bank') || name.contains('fee') || name.contains('charge')) {
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
