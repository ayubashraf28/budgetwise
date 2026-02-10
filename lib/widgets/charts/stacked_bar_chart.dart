import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../providers/yearly_provider.dart';

/// A stacked bar chart widget showing monthly expense data.
///
/// When [interactive] is true, bars can be tapped to select them.
/// The [onBarSelected] callback fires with the selected index (or null).
class StackedBarChart extends StatelessWidget {
  final List<MonthlyBarData> monthlyData;
  final String currencySymbol;
  final double height;
  final bool interactive;
  final int? selectedBarIndex;
  final ValueChanged<int?>? onBarSelected;

  const StackedBarChart({
    super.key,
    required this.monthlyData,
    required this.currencySymbol,
    this.height = 280,
    this.interactive = true,
    this.selectedBarIndex,
    this.onBarSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (monthlyData.isEmpty) {
      return SizedBox(height: height);
    }
    final palette = NeoTheme.of(context);
    final accent = NeoTheme.positiveValue(context);

    final maxExpense =
        monthlyData.map((d) => d.totalExpenses).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxExpense > 0 ? maxExpense * 1.2 : 100,
          barTouchData: BarTouchData(
            enabled: interactive,
            touchCallback: interactive
                ? (FlTouchEvent event, barTouchResponse) {
                    if (event is FlTapUpEvent &&
                        barTouchResponse != null &&
                        barTouchResponse.spot != null) {
                      final tappedIndex =
                          barTouchResponse.spot!.touchedBarGroupIndex;
                      final newIndex =
                          selectedBarIndex == tappedIndex ? null : tappedIndex;
                      onBarSelected?.call(newIndex);
                    }
                  }
                : null,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => palette.surface2,
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final data = monthlyData[group.x.toInt()];
                return BarTooltipItem(
                  '$currencySymbol${_formatAmount(data.totalExpenses)}',
                  TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= monthlyData.length) {
                    return const SizedBox.shrink();
                  }
                  final name = monthlyData[index].monthName;
                  final abbr = name.length >= 3 ? name.substring(0, 3) : name;
                  final isSelected = selectedBarIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      abbr,
                      style: TextStyle(
                        color: isSelected
                            ? accent
                            : selectedBarIndex != null
                                ? palette.textMuted.withValues(alpha: 0.4)
                                : palette.textMuted,
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: monthlyData.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            final barWidth = monthlyData.length <= 6 ? 28.0 : 16.0;
            final isDimmed =
                selectedBarIndex != null && selectedBarIndex != index;
            final dimAlpha = 0.25;

            if (data.segments.isEmpty) {
              final barColor =
                  isDimmed ? accent.withValues(alpha: dimAlpha) : accent;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: data.totalExpenses,
                    color: barColor,
                    width: barWidth,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                  ),
                ],
              );
            }

            double runningY = 0;
            final rodStackItems = <BarChartRodStackItem>[];
            final sortedSegments = List.of(data.segments)
              ..sort((a, b) => b.amount.compareTo(a.amount));
            for (final segment in sortedSegments.reversed) {
              rodStackItems.add(BarChartRodStackItem(
                runningY,
                runningY + segment.amount,
                isDimmed
                    ? segment.color.withValues(alpha: dimAlpha)
                    : segment.color,
              ));
              runningY += segment.amount;
            }

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: data.totalExpenses,
                  rodStackItems: rodStackItems,
                  color: Colors.transparent,
                  width: barWidth,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return NumberFormat('#,##,###').format(amount.toInt());
    }
    return amount.toStringAsFixed(amount == amount.roundToDouble() ? 0 : 2);
  }
}
