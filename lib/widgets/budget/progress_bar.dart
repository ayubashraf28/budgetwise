import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// A progress bar widget that shows actual vs projected budget
class BudgetProgressBar extends StatelessWidget {
  final double projected;
  final double actual;
  final Color color;
  final double height;
  final Color? backgroundColor;

  const BudgetProgressBar({
    super.key,
    required this.projected,
    required this.actual,
    required this.color,
    this.height = 8,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final percentage =
        projected > 0 ? (actual / projected).clamp(0.0, 1.0) : 0.0;
    final isOver = actual > projected;
    final trackColor = backgroundColor ?? color.withValues(alpha: 0.2);
    final danger = NeoTheme.negativeValue(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: trackColor,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                color: isOver ? danger : color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
