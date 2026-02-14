part of 'analysis_screen.dart';

class _RowCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color leadingColor;
  final IconData? leadingIcon;
  final String amount;
  final String meta;
  final VoidCallback onTap;

  const _RowCard({
    required this.title,
    required this.subtitle,
    required this.leadingColor,
    this.leadingIcon,
    required this.amount,
    required this.meta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);
    final isLight = NeoTheme.isLight(context);
    final surface = isLight ? palette.surface1 : palette.surface2;
    final stroke = isLight
        ? palette.stroke.withValues(alpha: 0.75)
        : palette.stroke.withValues(alpha: 0.9);
    final cardShadow =
        isLight ? Colors.black.withValues(alpha: 0.06) : Colors.transparent;
    final textPrimary = palette.textPrimary;
    final textSecondary = palette.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: stroke),
              boxShadow: [
                BoxShadow(
                  color: cardShadow,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color:
                        leadingColor.withValues(alpha: isLight ? 0.14 : 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: leadingIcon != null
                        ? Icon(
                            leadingIcon,
                            size: 18,
                            color: leadingColor,
                          )
                        : Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: leadingColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelLarge.copyWith(
                            color: textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          )),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amount,
                      style: AppTypography.amountSmall.copyWith(
                        color: textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      style: AppTypography.bodySmall.copyWith(
                        color: textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartCenter extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String amount;
  final String label;
  final String meta;

  const _ChartCenter({
    this.icon,
    this.iconColor,
    required this.amount,
    required this.label,
    required this.meta,
  });

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);
    final textPrimary = palette.textPrimary;
    final textSecondary = palette.textSecondary;

    return SizedBox(
      width: 164,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: iconColor ?? textPrimary,
            ),
            const SizedBox(height: 6),
          ],
          Text(
            amount,
            style: AppTypography.amountSmall.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 17,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            meta,
            style: AppTypography.bodySmall.copyWith(
              color: textSecondary,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Insight extends StatelessWidget {
  final String title;
  final String value;

  const _Insight({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);
    final isLight = NeoTheme.isLight(context);
    final surface = isLight ? palette.surface1 : palette.surface2;
    final stroke =
        isLight ? palette.stroke.withValues(alpha: 0.75) : palette.stroke;
    final textPrimary = palette.textPrimary;
    final textSecondary = palette.textSecondary;

    return Container(
      constraints: const BoxConstraints(minWidth: 170),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.labelMedium.copyWith(
              color: textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountsChart extends StatelessWidget {
  final List<AccountMovementSummary> rows;
  final String currency;

  const _AccountsChart({
    required this.rows,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox(height: 220);
    final palette = NeoTheme.of(context);
    final positive = NeoTheme.positiveValue(context);
    final negative = NeoTheme.negativeValue(context);
    final muted = palette.textSecondary;
    final stroke = palette.stroke;
    final maxValue = rows.fold<double>(
        0, (m, r) => math.max(m, math.max(r.income, r.expense)));
    final maxY = maxValue <= 0 ? 100.0 : maxValue * 1.2;

    return SizedBox(
      height: 210,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: stroke.withValues(alpha: 0.7), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= rows.length) return const SizedBox.shrink();
                  final name = rows[i].accountName;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      name.length > 6 ? '${name.substring(0, 6)}..' : name,
                      style: TextStyle(fontSize: 10, color: muted),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => palette.surface2,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                if (rodIndex == 1) return null;
                final row = rows[group.x.toInt()];
                return BarTooltipItem(
                  '${row.accountName}\n+$currency${_fmt(row.income)}  /  -$currency${_fmt(row.expense)}',
                  TextStyle(color: palette.textPrimary, fontSize: 11),
                );
              },
            ),
          ),
          barGroups: rows.asMap().entries.map((e) {
            final row = e.value;
            return BarChartGroupData(
              x: e.key,
              barsSpace: 4,
              barRods: [
                BarChartRodData(toY: row.income, width: 10, color: positive),
                BarChartRodData(toY: row.expense, width: 10, color: negative),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v == v.roundToDouble()) {
      return NumberFormat('#,##0').format(v);
    }
    return NumberFormat('#,##0.##').format(v);
  }
}

class _TrendChart extends StatelessWidget {
  final List<TrendPoint> points;
  final AnalysisTrendMetric metric;
  final String currency;

  const _TrendChart({
    required this.points,
    required this.metric,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox(height: 240);
    final palette = NeoTheme.of(context);
    final muted = palette.textSecondary;
    final stroke = palette.stroke;
    final values = points.map(_value).toList();
    var minY =
        metric == AnalysisTrendMetric.net ? values.reduce(math.min) : 0.0;
    var maxY = values.reduce(math.max);
    if (metric == AnalysisTrendMetric.net) {
      minY = math.min(minY, 0);
      maxY = math.max(maxY, 0);
    }
    if (maxY == minY) {
      maxY += 50;
      if (metric == AnalysisTrendMetric.net) minY -= 50;
    }
    final color = metric == AnalysisTrendMetric.expense
        ? NeoTheme.negativeValue(context)
        : metric == AnalysisTrendMetric.income
            ? NeoTheme.positiveValue(context)
            : NeoTheme.infoValue(context);

    final includeZeroLine = metric == AnalysisTrendMetric.net;
    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY * 1.2,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: ((maxY - minY) / 4).clamp(1, double.infinity),
            getDrawingHorizontalLine: (_) =>
                FlLine(color: stroke.withValues(alpha: 0.7), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(points[i].monthLabel,
                        style: TextStyle(fontSize: 11, color: muted)),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => palette.surface2,
              getTooltipItems: (spots) => spots.map((s) {
                final p = points[s.x.toInt()];
                final sign =
                    metric == AnalysisTrendMetric.net && s.y < 0 ? '-' : '';
                return LineTooltipItem(
                  '${p.monthLabel} ${p.year}\n$sign$currency${_fmt(s.y.abs())}',
                  TextStyle(color: palette.textPrimary, fontSize: 11),
                );
              }).toList(),
            ),
          ),
          extraLinesData: includeZeroLine
              ? ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: 0,
                      color: stroke.withValues(alpha: 0.9),
                      strokeWidth: 1,
                    ),
                  ],
                )
              : const ExtraLinesData(),
          lineBarsData: [
            LineChartBarData(
              spots: points
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), _value(e.value)))
                  .toList(),
              isCurved: true,
              color: color,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(colors: [
                  color.withValues(alpha: 0.25),
                  color.withValues(alpha: 0.03)
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _value(TrendPoint p) => metric == AnalysisTrendMetric.expense
      ? p.expense
      : metric == AnalysisTrendMetric.income
          ? p.income
          : p.net;

  String _fmt(double v) {
    if (v == v.roundToDouble()) {
      return NumberFormat('#,##0').format(v);
    }
    return NumberFormat('#,##0.##').format(v);
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary = NeoTheme.of(context).textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ModeLoading extends StatelessWidget {
  final Color color;

  const _ModeLoading({required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: CircularProgressIndicator(color: color),
      ),
    );
  }
}

class _ModeError extends StatelessWidget {
  final String error;

  const _ModeError({required this.error});

  @override
  Widget build(BuildContext context) {
    final danger = NeoTheme.negativeValue(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final errorBg = isLight
        ? const HSLColor.fromAHSL(1, 355.7, 0.700, 0.961).toColor()
        : danger.withValues(alpha: 0.12);
    final errorStroke = isLight
        ? const HSLColor.fromAHSL(1, 352.0, 0.634, 0.861).toColor()
        : danger.withValues(alpha: 0.35);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: errorBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: errorStroke),
      ),
      child: Text(
        'Failed to load analysis data: $error',
        style: AppTypography.bodyMedium.copyWith(color: danger),
      ),
    );
  }
}
