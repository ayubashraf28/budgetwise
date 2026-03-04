import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/motion.dart';
import '../../providers/motion_provider.dart';

class NeoStaggeredReveal extends ConsumerStatefulWidget {
  const NeoStaggeredReveal({
    super.key,
    required this.revealKey,
    required this.index,
    required this.child,
    this.maxAnimatedItems = 8,
    this.baseDelay = const Duration(milliseconds: 30),
  });

  final String revealKey;
  final int index;
  final Widget child;
  final int maxAnimatedItems;
  final Duration baseDelay;

  @override
  ConsumerState<NeoStaggeredReveal> createState() => _NeoStaggeredRevealState();
}

class _NeoStaggeredRevealState extends ConsumerState<NeoStaggeredReveal> {
  late final bool _shouldAnimate;

  @override
  void initState() {
    super.initState();
    final hasSeen = ref.read(motionSeenProvider).contains(widget.revealKey);
    _shouldAnimate = !hasSeen && widget.index < widget.maxAnimatedItems;

    if (_shouldAnimate && widget.index == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        ref.read(motionSeenProvider.notifier).markSeen(widget.revealKey);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldAnimate || !neoAnimationsEnabled(context)) {
      return widget.child;
    }

    final delay = Duration(
      milliseconds: widget.baseDelay.inMilliseconds * widget.index,
    );

    return widget.child
        .animate()
        .fadeIn(
          delay: delay,
          duration: const Duration(milliseconds: 260),
          curve: NeoMotionCurve.entrance,
        )
        .slideY(
          begin: 0.04,
          end: 0,
          delay: delay,
          duration: const Duration(milliseconds: 260),
          curve: NeoMotionCurve.entrance,
        );
  }
}
