import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';

/// Card showing projected and actual balance with difference indicator
class BalanceCard extends StatelessWidget {
  final double projectedBalance;
  final double actualBalance;
  final String currencySymbol;

  const BalanceCard({
    super.key,
    required this.projectedBalance,
    required this.actualBalance,
    this.currencySymbol = '\u00A3',
  });

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);
    final difference = actualBalance - projectedBalance;
    final isAhead = difference > 0;

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Projected Balance
          const Text(
            'Projected Balance',
            style: AppTypography.labelMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$currencySymbol${projectedBalance.toStringAsFixed(0)}',
            style: AppTypography.amountMedium.copyWith(
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Actual Balance
          const Text(
            'Actual Balance',
            style: AppTypography.labelMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '$currencySymbol${actualBalance.toStringAsFixed(0)}',
                style: AppTypography.amountLarge,
              ),
              const SizedBox(width: AppSpacing.md),
              if (difference.abs() >= 1)
                _buildDifferenceChip(context, difference, isAhead),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDifferenceChip(
      BuildContext context, double difference, bool isAhead) {
    final color = isAhead
        ? NeoTheme.positiveValue(context)
        : NeoTheme.negativeValue(context);
    final icon = isAhead ? LucideIcons.trendingUp : LucideIcons.trendingDown;
    final label = isAhead ? 'ahead' : 'behind';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$currencySymbol${difference.abs().toStringAsFixed(0)} $label',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
