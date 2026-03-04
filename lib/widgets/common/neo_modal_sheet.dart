import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/motion.dart';

Future<T?> showNeoModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool useSafeArea = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool showDragHandle = false,
  Color backgroundColor = Colors.transparent,
  Color? barrierColor,
  Clip? clipBehavior,
  ShapeBorder? shape,
  BoxConstraints? constraints,
  RouteSettings? routeSettings,
  AnimationController? transitionAnimationController,
  Offset? anchorPoint,
  bool? requestFocus,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    showDragHandle: showDragHandle,
    backgroundColor: backgroundColor,
    barrierColor: barrierColor,
    clipBehavior: clipBehavior,
    shape: shape,
    constraints: constraints,
    routeSettings: routeSettings,
    transitionAnimationController: transitionAnimationController,
    anchorPoint: anchorPoint,
    requestFocus: requestFocus,
    sheetAnimationStyle: neoAnimationStyle(
      context,
      duration: NeoMotionDuration.medium,
      reverseDuration: const Duration(milliseconds: 220),
    ),
    builder: (sheetContext) {
      final child = builder(sheetContext);
      if (!neoAnimationsEnabled(sheetContext)) {
        return child;
      }

      return child
          .animate()
          .fadeIn(
            duration: const Duration(milliseconds: 220),
            curve: NeoMotionCurve.entrance,
          )
          .slideY(
            begin: 0.06,
            end: 0,
            duration: const Duration(milliseconds: 220),
            curve: NeoMotionCurve.entrance,
          );
    },
  );
}
