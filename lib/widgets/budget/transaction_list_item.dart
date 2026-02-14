import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../models/transaction.dart';
import '../../utils/transaction_display_utils.dart';

/// List item widget for displaying a transaction.
class TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String currencySymbol;
  final bool useSimpleLabel;

  const TransactionListItem({
    super.key,
    required this.transaction,
    this.onTap,
    this.onLongPress,
    this.onEdit,
    this.onDelete,
    this.currencySymbol = '\u00A3',
    this.useSimpleLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);
    final isIncome = transaction.isIncome;
    final amountColor = isIncome
        ? NeoTheme.positiveValue(context)
        : NeoTheme.negativeValue(context);
    final categoryColor = _parseColor(transaction.categoryColor);
    final iconColor =
        isIncome ? NeoTheme.positiveValue(context) : categoryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: palette.surface2,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: palette.stroke),
                    ),
                    child: Icon(
                      isIncome
                          ? LucideIcons.arrowDownLeft
                          : _getCategoryIcon(transaction.categoryName),
                      color: iconColor,
                      size: NeoIconSizes.lg,
                    ),
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: amountColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: palette.surface1, width: 2),
                      ),
                      child: Center(
                        child: isIncome
                            ? const Icon(LucideIcons.plus,
                                size: NeoIconSizes.xxs, color: Colors.white)
                            : const Icon(LucideIcons.minus,
                                size: NeoIconSizes.xxs, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transactionPrimaryLabel(
                        transaction,
                        isSimpleMode: useSimpleLabel,
                      ),
                      style: NeoTypography.rowTitle(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildMetaChip(
                          context,
                          text: isIncome
                              ? 'Income'
                              : (transaction.categoryName ?? 'Expense'),
                          color: iconColor,
                        ),
                        if (transaction.accountName != null)
                          _buildMetaChip(
                            context,
                            text: transaction.accountName!,
                            color: NeoTheme.infoValue(context),
                            icon: LucideIcons.wallet,
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.calendar,
                              size: NeoIconSizes.xs,
                              color: palette.textMuted,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              DateFormat('MMM d, yyyy')
                                  .format(transaction.date),
                              style: NeoTypography.rowSecondary(context)
                                  .copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    transaction.formattedAmount(currencySymbol),
                    style: NeoTypography.rowAmount(context, amountColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isIncome ? 'Received' : 'Paid',
                    style: NeoTypography.rowSecondary(context)
                        .copyWith(fontSize: 11),
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
    if (hex == null) return NeoTheme.dark.accent;
    try {
      final hexCode = hex.replaceFirst('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (_) {
      return NeoTheme.dark.accent;
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

  Widget _buildMetaChip(
    BuildContext context, {
    required String text,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSizing.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: NeoIconSizes.xs, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
