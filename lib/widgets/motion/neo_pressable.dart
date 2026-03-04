import 'package:flutter/material.dart';

import '../../config/motion.dart';

class NeoPressable extends StatefulWidget {
  const NeoPressable({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final bool enabled;

  @override
  State<NeoPressable> createState() => _NeoPressableState();
}

class _NeoPressableState extends State<NeoPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled || !mounted || _pressed == value) {
      return;
    }
    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final shouldAnimate = widget.enabled && neoAnimationsEnabled(context);
    final scaledChild = AnimatedScale(
      scale: shouldAnimate && _pressed ? 0.985 : 1,
      duration:
          _pressed ? NeoMotionDuration.pressIn : NeoMotionDuration.pressOut,
      curve: NeoMotionCurve.emphasis,
      child: widget.onTap == null
          ? widget.child
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.enabled ? widget.onTap : null,
                borderRadius: widget.borderRadius,
                child: widget.child,
              ),
            ),
    );

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: scaledChild,
    );
  }
}
