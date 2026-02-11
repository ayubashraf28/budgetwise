import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../models/category.dart';
import '../../utils/app_icon_registry.dart';
import 'progress_bar.dart';
import 'difference_indicator.dart';

/// List item widget for displaying a budget category
class CategoryListItem extends StatelessWidget {
  final Category category;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String currencySymbol;

  const CategoryListItem({
    super.key,
    required this.category,
    this.onTap,
    this.onLongPress,
    this.currencySymbol = '\u00A3',
  });

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);
    final danger = NeoTheme.negativeValue(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        child: Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: (category.isBudgeted && category.isOverBudget)
                ? danger.withValues(alpha: 0.1)
                : palette.surface1,
            borderRadius: BorderRadius.circular(AppSizing.radiusLg),
            border: (category.isBudgeted && category.isOverBudget)
                ? Border.all(color: danger.withValues(alpha: 0.3))
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: category.colorValue,
                  borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: category.colorValue.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _getIcon(category.icon),
                  color: Colors.white,
                  size: AppSizing.iconLg,
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
                            category.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: palette.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            category.isBudgeted
                                ? '$currencySymbol${category.totalActual.toStringAsFixed(0)} / $currencySymbol${category.totalProjected.toStringAsFixed(0)}'
                                : '$currencySymbol${category.totalActual.toStringAsFixed(0)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              color: palette.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (category.isBudgeted) ...[
                      const SizedBox(height: AppSpacing.sm),
                      BudgetProgressBar(
                        projected: category.totalProjected,
                        actual: category.totalActual,
                        color: category.colorValue,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      DifferenceIndicator(
                        projected: category.totalProjected,
                        actual: category.totalActual,
                        currencySymbol: currencySymbol,
                      ),
                    ] else ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Spending only',
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                LucideIcons.chevronRight,
                color: palette.textMuted,
                size: AppSizing.iconMd,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String iconName) {
    return resolveAppIcon(iconName, fallback: LucideIcons.wallet);
  }
}
