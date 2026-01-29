import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../models/transaction.dart';

/// List item widget for displaying a transaction
class TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const TransactionListItem({
    super.key,
    required this.transaction,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.isIncome;
    final amountColor = isIncome ? AppColors.success : AppColors.error;
    final categoryColor = _parseColor(transaction.categoryColor);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isIncome
                      ? AppColors.success.withValues(alpha: 0.15)
                      : categoryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                ),
                child: Icon(
                  isIncome ? LucideIcons.trendingUp : _getCategoryIcon(transaction.categoryName),
                  color: isIncome ? AppColors.success : categoryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.displayName,
                      style: AppTypography.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _buildSubtitle(),
                      style: AppTypography.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Amount
              Text(
                transaction.formattedAmount('\u00A3'),
                style: TextStyle(
                  color: amountColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];

    if (transaction.isIncome) {
      parts.add('Income');
    } else if (transaction.categoryName != null) {
      parts.add(transaction.categoryName!);
    }

    if (transaction.note != null && transaction.note!.isNotEmpty) {
      parts.add(transaction.note!);
    }

    return parts.join(' \u2022 ');
  }

  Color _parseColor(String? hex) {
    if (hex == null) return AppColors.primary;
    try {
      final hexCode = hex.replaceFirst('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (e) {
      return AppColors.primary;
    }
  }

  IconData _getCategoryIcon(String? categoryName) {
    if (categoryName == null) return LucideIcons.receipt;

    final iconMap = {
      'housing': LucideIcons.home,
      'food': LucideIcons.utensils,
      'transport': LucideIcons.car,
      'subscriptions': LucideIcons.tv,
      'personal': LucideIcons.shoppingBag,
      'entertainment': LucideIcons.gamepad2,
      'savings': LucideIcons.piggyBank,
      'education': LucideIcons.graduationCap,
      'health': LucideIcons.heart,
      'business': LucideIcons.briefcase,
      'travel': LucideIcons.plane,
      'gifts': LucideIcons.gift,
    };

    final lowerName = categoryName.toLowerCase();
    for (final entry in iconMap.entries) {
      if (lowerName.contains(entry.key)) {
        return entry.value;
      }
    }

    return LucideIcons.receipt;
  }
}
