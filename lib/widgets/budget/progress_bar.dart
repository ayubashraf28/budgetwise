import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// A progress bar widget that shows actual vs projected budget
class BudgetProgressBar extends StatelessWidget {
  final double projected;
  final double actual;
  final Color color;
  final double height;

  const BudgetProgressBar({
    super.key,
    required this.projected,
    required this.actual,
    required this.color,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = projected > 0 ? (actual / projected).clamp(0.0, 1.0) : 0.0;
    final isOver = actual > projected;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: percentage,
        child: Container(
          decoration: BoxDecoration(
            color: isOver ? AppColors.error : color,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}
