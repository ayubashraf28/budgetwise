import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';

/// Reusable empty state widget for when lists have no data
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    this.icon = LucideIcons.inbox,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  /// Creates an empty state for transactions
  factory EmptyState.transactions({VoidCallback? onAdd}) {
    return EmptyState(
      icon: LucideIcons.creditCard,
      title: 'No transactions yet',
      message: 'Start tracking your spending by adding your first transaction',
      actionLabel: 'Add Transaction',
      onAction: onAdd,
    );
  }

  /// Creates an empty state for categories
  factory EmptyState.categories({VoidCallback? onAdd}) {
    return EmptyState(
      icon: LucideIcons.folderOpen,
      title: 'No categories yet',
      message: 'Create categories to organize your budget',
      actionLabel: 'Add Category',
      onAction: onAdd,
    );
  }

  /// Creates an empty state for items
  factory EmptyState.items({VoidCallback? onAdd}) {
    return EmptyState(
      icon: LucideIcons.listTodo,
      title: 'No items yet',
      message: 'Add budget items to track your spending',
      actionLabel: 'Add Item',
      onAction: onAdd,
    );
  }

  /// Creates an empty state for income sources
  factory EmptyState.incomeSources({VoidCallback? onAdd}) {
    return EmptyState(
      icon: LucideIcons.wallet,
      title: 'No income sources yet',
      message: 'Add your income sources to start planning your budget',
      actionLabel: 'Add Income',
      onAction: onAdd,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppSizing.radiusXl),
              ),
              child: Icon(
                icon,
                size: 40,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTypography.h3.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(LucideIcons.plus, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
