part of 'category_detail_screen.dart';

extension _CategoryDetailActions on CategoryDetailScreen {
  Widget _buildAddButton(
    BuildContext context,
    WidgetRef ref,
    Category category, {
    required bool isSimpleMode,
  }) {
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
          onTap: () => _showAddSheet(
            context,
            ref,
            category,
            isSimpleMode: isSimpleMode,
          ),
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
                  isSimpleMode ? 'Add Transaction' : 'Add Item',
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
    BuildContext context,
    WidgetRef ref,
    Category category, {
    required bool isSimpleMode,
  }) {
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
            isSimpleMode ? 'No transactions yet' : 'No items yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isSimpleMode
                ? 'Add a transaction to start tracking spending in this category'
                : 'Add items to track spending in this category',
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
                onTap: () => _showAddSheet(
                  context,
                  ref,
                  category,
                  isSimpleMode: isSimpleMode,
                ),
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
                        isSimpleMode ? 'Add Transaction' : 'Add Item',
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
    BuildContext context,
    WidgetRef ref,
    Category category, {
    required bool isSimpleMode,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => isSimpleMode
          ? TransactionFormSheet(initialCategoryId: category.id)
          : ItemFormSheet(
              categoryId: category.id,
            ),
    );

    ref.invalidate(categoryByIdProvider(categoryId));
    ref.invalidate(categoriesProvider);
    ref.invalidate(transactionsByCategoryProvider(categoryId));
    ref.invalidate(transactionsProvider);
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
