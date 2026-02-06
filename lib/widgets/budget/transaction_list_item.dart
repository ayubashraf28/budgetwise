import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../models/transaction.dart';

/// List item widget for displaying a transaction
class TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String currencySymbol;

  const TransactionListItem({
    super.key,
    required this.transaction,
    this.onTap,
    this.onLongPress,
    this.onEdit,
    this.onDelete,
    this.currencySymbol = '\u00A3',
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.isIncome;
    final amountColor = isIncome ? AppColors.success : AppColors.error;
    final categoryColor = _parseColor(transaction.categoryColor);
    final iconBgColor = isIncome ? AppColors.success : categoryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            children: [
              // Icon with status indicator dot
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconBgColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                    ),
                    child: Icon(
                      isIncome
                          ? LucideIcons.trendingDown
                          : _getCategoryIcon(transaction.categoryName),
                      color: iconBgColor,
                      size: 20,
                    ),
                  ),
                  // Status dot — top-right corner
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isIncome ? AppColors.success : AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                      child: Center(
                        child: isIncome
                            ? const Icon(LucideIcons.plus, size: 8, color: Colors.white)
                            : const Icon(LucideIcons.minus, size: 8, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),

              // Name + category badge + date
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Category/type badge chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isIncome
                                ? AppColors.success.withValues(alpha: 0.15)
                                : categoryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppSizing.radiusFull),
                          ),
                          child: Text(
                            isIncome ? 'Income' : (transaction.categoryName ?? 'Expense'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isIncome ? AppColors.success : categoryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // Calendar icon + date
                        const Icon(
                          LucideIcons.calendar,
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          DateFormat('MMM d, yyyy').format(transaction.date),
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount + status text
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    transaction.formattedAmount(currencySymbol),
                    style: TextStyle(
                      color: amountColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isIncome ? 'Received' : 'Paid',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
      'charity': LucideIcons.heart,
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
