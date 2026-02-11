import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Data for a single segment in the donut chart.
class DonutSegment {
  final Color color;
  final double value;
  final String name;
  final String icon;

  const DonutSegment({
    required this.color,
    required this.value,
    this.name = '',
    this.icon = '',
  });
}

/// An interactive donut chart widget.
///
/// Displays segments as a ring chart. Tapping a segment selects it;
/// tapping outside or tapping the same segment deselects.
/// The [centerBuilder] callback is used to render content in the center
/// based on the current selection.
class DonutChart extends StatefulWidget {
  final List<DonutSegment> segments;
  final double total;
  final Widget Function(int? selectedIndex) centerBuilder;
  final double strokeWidth;
  final double selectedStrokeWidth;
  final double gapDegrees;
  final double height;
  final int? initialSelectedIndex;
  final ValueChanged<int?>? onSelectionChanged;

  const DonutChart({
    super.key,
    required this.segments,
    required this.total,
    required this.centerBuilder,
    this.strokeWidth = 20,
    this.selectedStrokeWidth = 26,
    this.gapDegrees = 10.0,
    this.height = 280,
    this.initialSelectedIndex,
    this.onSelectionChanged,
  });

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart> {
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialSelectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.segments.isEmpty) {
      return SizedBox(height: widget.height);
    }

    final chartTextScale = _safeChartTextScale(context);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(chartTextScale),
      ),
      child: SizedBox(
        width: double.infinity,
        height: widget.height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = math
                .min(constraints.maxWidth, constraints.maxHeight)
                .toDouble();
            final segmentTotal =
                widget.segments.fold<double>(0, (sum, s) => sum + s.value);

            return Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapDown: (details) {
                    _handleChartTap(details, size, segmentTotal);
                  },
                  child: CustomPaint(
                    size: Size(size, size),
                    painter: _DonutChartPainter(
                      segments: widget.segments,
                      strokeWidth: widget.strokeWidth,
                      gapDegrees: widget.gapDegrees,
                      selectedIndex: _selectedIndex,
                      selectedStrokeWidth: widget.selectedStrokeWidth,
                    ),
                  ),
                ),
                IgnorePointer(
                  child: widget.centerBuilder(_selectedIndex),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Charts should respect accessibility settings, but with a moderated scale
  // to avoid clipping/overlap in constrained chart layouts.
  double _safeChartTextScale(BuildContext context) {
    final appScale = MediaQuery.textScalerOf(context).scale(1.0).toDouble();
    final moderated = 1.0 + (appScale - 1.0) * 0.75;
    return moderated.clamp(0.9, 1.22).toDouble();
  }

  void _handleChartTap(
    TapDownDetails details,
    double size,
    double totalActual,
  ) {
    if (totalActual <= 0) {
      setState(() => _selectedIndex = null);
      widget.onSelectionChanged?.call(null);
      return;
    }

    final center = Offset(size / 2, size / 2);
    final tapOffset = details.localPosition - center;
    final distance = tapOffset.distance;

    final radius = (size - widget.selectedStrokeWidth) / 2;
    final ringHalfWidth = widget.selectedStrokeWidth / 2;
    const hitPadding = 8.0;
    final minRadius = radius - ringHalfWidth - hitPadding;
    final maxRadius = radius + ringHalfWidth + hitPadding;
    if (distance < minRadius || distance > maxRadius) {
      setState(() => _selectedIndex = null);
      widget.onSelectionChanged?.call(null);
      return;
    }

    var angle = math.atan2(tapOffset.dy, tapOffset.dx);
    angle = angle + (math.pi / 2);
    if (angle < 0) angle += 2 * math.pi;

    final gapRad = widget.gapDegrees * math.pi / 180;
    final totalGap = gapRad * widget.segments.length;
    final availableSweep = 2 * math.pi - totalGap;

    double startAngle = 0;

    for (int i = 0; i < widget.segments.length; i++) {
      final fraction = widget.segments[i].value / totalActual;
      final sweepAngle = fraction * availableSweep;
      final segmentEnd = startAngle + sweepAngle;

      bool isInSegment = false;

      if (segmentEnd <= 2 * math.pi) {
        isInSegment = angle >= startAngle && angle < segmentEnd;
      } else {
        isInSegment = (angle >= startAngle && angle < 2 * math.pi) ||
            (angle >= 0 && angle < (segmentEnd - 2 * math.pi));
      }

      if (isInSegment) {
        setState(() {
          _selectedIndex = (_selectedIndex == i) ? null : i;
        });
        widget.onSelectionChanged?.call(_selectedIndex);
        return;
      }

      startAngle = segmentEnd + gapRad;
      if (startAngle >= 2 * math.pi) startAngle -= 2 * math.pi;
    }

    setState(() => _selectedIndex = null);
    widget.onSelectionChanged?.call(null);
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<DonutSegment> segments;
  final double strokeWidth;
  final double gapDegrees;
  final int? selectedIndex;
  final double selectedStrokeWidth;

  _DonutChartPainter({
    required this.segments,
    this.strokeWidth = 22,
    this.gapDegrees = 3.0,
    this.selectedIndex,
    this.selectedStrokeWidth = 28,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        (math.min(size.width, size.height) - selectedStrokeWidth) / 2;

    final total = segments.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0) return;

    final gapRad = gapDegrees * math.pi / 180;
    final totalGap = gapRad * segments.length;
    final availableSweep = 2 * math.pi - totalGap;

    double startAngle = -math.pi / 2;

    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final fraction = segment.value / total;
      final sweepAngle = fraction * availableSweep;
      final isSelected = i == selectedIndex;

      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? selectedStrokeWidth : strokeWidth
        ..strokeCap = StrokeCap.round;

      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

      startAngle += sweepAngle + gapRad;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.segments.length != segments.length;
  }
}
