import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// Card showing a quick stat with actual vs projected
class QuickStatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final double actual;
  final double projected;
  final Color color;
  final String currencySymbol;
  final VoidCallback? onTap;

  const QuickStatCard({
    super.key,
    required this.title,
    required this.icon,
    required this.actual,
    required this.projected,
    required this.color,
    this.currencySymbol = '\u00A3',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
          child: Container(
            padding: AppSpacing.cardPaddingCompact,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizing.radiusLg),
              border: Border(
                left: BorderSide(color: color, width: 4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: AppSizing.iconMd, color: color),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      title,
                      style: AppTypography.labelMedium,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '$currencySymbol${actual.toStringAsFixed(0)}',
                  style: AppTypography.amountSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'of $currencySymbol${projected.toStringAsFixed(0)}',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
