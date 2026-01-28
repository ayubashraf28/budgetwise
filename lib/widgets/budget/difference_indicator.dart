import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';

/// Indicator showing the difference between projected and actual amounts
class DifferenceIndicator extends StatelessWidget {
  final double projected;
  final double actual;
  final bool showAmount;
  final String currencySymbol;

  const DifferenceIndicator({
    super.key,
    required this.projected,
    required this.actual,
    this.showAmount = true,
    this.currencySymbol = '\u00A3',
  });

  @override
  Widget build(BuildContext context) {
    final difference = projected - actual;

    if (difference.abs() < 0.01) {
      return const Text(
        'On track',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      );
    }

    final isUnder = difference > 0;
    final color = isUnder ? AppColors.success : AppColors.error;
    final icon = isUnder ? LucideIcons.trendingDown : LucideIcons.trendingUp;
    final label = isUnder ? 'under' : 'over';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        if (showAmount)
          Text(
            '$currencySymbol${difference.abs().toStringAsFixed(0)} $label',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}
