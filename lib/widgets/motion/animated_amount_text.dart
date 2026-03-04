import 'package:flutter/material.dart';

import '../../config/motion.dart';

class AnimatedAmountText extends StatefulWidget {
  const AnimatedAmountText({
    super.key,
    required this.value,
    required this.formatter,
    required this.style,
    this.animateWhenChangedAbove = 0.5,
    this.textAlign,
    this.maxLines = 1,
    this.overflow = TextOverflow.visible,
  });

  final double value;
  final String Function(double value) formatter;
  final TextStyle style;
  final double animateWhenChangedAbove;
  final TextAlign? textAlign;
  final int maxLines;
  final TextOverflow overflow;

  @override
  State<AnimatedAmountText> createState() => _AnimatedAmountTextState();
}

class _AnimatedAmountTextState extends State<AnimatedAmountText> {
  late double _fromValue;
  late double _toValue;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _fromValue = widget.value;
    _toValue = widget.value;
    _initialized = true;
  }

  @override
  void didUpdateWidget(covariant AnimatedAmountText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == _toValue) {
      return;
    }

    if ((widget.value - _toValue).abs() < widget.animateWhenChangedAbove) {
      _fromValue = widget.value;
      _toValue = widget.value;
      return;
    }

    _fromValue = _toValue;
    _toValue = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || !neoAnimationsEnabled(context)) {
      return Text(
        widget.formatter(widget.value),
        style: widget.style,
        textAlign: widget.textAlign,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _fromValue, end: _toValue),
      duration: NeoMotionDuration.slow,
      curve: NeoMotionCurve.entrance,
      builder: (context, animatedValue, _) {
        return Text(
          widget.formatter(animatedValue),
          style: widget.style,
          textAlign: widget.textAlign,
          maxLines: widget.maxLines,
          overflow: widget.overflow,
        );
      },
    );
  }
}
