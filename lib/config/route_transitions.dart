import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'motion.dart';

enum NeoRouteStyle {
  none,
  standard,
  modal,
}

Page<T> buildNeoPage<T>({
  required GoRouterState state,
  required Widget child,
  NeoRouteStyle style = NeoRouteStyle.standard,
}) {
  if (style == NeoRouteStyle.none || !neoPlatformAnimationsEnabled()) {
    return NoTransitionPage<T>(
      key: state.pageKey,
      name: state.name,
      child: child,
    );
  }

  final isModal = style == NeoRouteStyle.modal;
  final slideTween = Tween<Offset>(
    begin: isModal ? const Offset(0, 0.06) : const Offset(0, 0.02),
    end: Offset.zero,
  );

  return CustomTransitionPage<T>(
    key: state.pageKey,
    name: state.name,
    child: child,
    transitionDuration:
        isModal ? NeoMotionDuration.medium : NeoMotionDuration.standard,
    reverseTransitionDuration: isModal
        ? const Duration(milliseconds: 220)
        : const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: NeoMotionCurve.entrance,
        reverseCurve: NeoMotionCurve.exit,
      );

      return FadeTransition(
        opacity: curvedAnimation,
        child: SlideTransition(
          position: slideTween.animate(curvedAnimation),
          child: child,
        ),
      );
    },
  );
}
