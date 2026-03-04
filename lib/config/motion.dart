import 'package:flutter/material.dart';

abstract final class NeoMotionDuration {
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration standard = Duration(milliseconds: 240);
  static const Duration medium = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 320);
  static const Duration pressIn = Duration(milliseconds: 90);
  static const Duration pressOut = Duration(milliseconds: 140);
}

abstract final class NeoMotionCurve {
  static const Curve entrance = Curves.easeOutCubic;
  static const Curve emphasis = Curves.easeInOutCubic;
  static const Curve exit = Curves.easeInCubic;
}

bool neoPlatformAnimationsEnabled() {
  final dispatcher = WidgetsBinding.instance.platformDispatcher;
  return !dispatcher.accessibilityFeatures.disableAnimations;
}

bool neoAnimationsEnabled(BuildContext context) {
  final mediaQuery = MediaQuery.maybeOf(context);
  final disableAnimations = mediaQuery?.disableAnimations ?? false;
  return neoPlatformAnimationsEnabled() && !disableAnimations;
}

AnimationStyle neoAnimationStyle(
  BuildContext context, {
  Duration duration = NeoMotionDuration.standard,
  Duration reverseDuration = NeoMotionDuration.fast,
}) {
  if (!neoAnimationsEnabled(context)) {
    return AnimationStyle.noAnimation;
  }

  return AnimationStyle(
    duration: duration,
    reverseDuration: reverseDuration,
  );
}
