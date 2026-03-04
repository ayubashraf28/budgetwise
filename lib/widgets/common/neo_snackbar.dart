import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/motion.dart';
import '../../config/theme.dart';

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showNeoSnackBar(
  BuildContext context,
  SnackBar snackBar,
) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  return messenger.showSnackBar(
    snackBar,
    snackBarAnimationStyle: neoAnimationStyle(
      context,
      duration: NeoMotionDuration.standard,
      reverseDuration: NeoMotionDuration.fast,
    ),
  );
}

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showNeoErrorSnackBar(
  BuildContext context,
  String message,
) {
  return showNeoSnackBar(
    context,
    _buildIconSnackBar(
      context,
      message: message,
      icon: LucideIcons.alertCircle,
      backgroundColor: NeoTheme.negativeValue(context),
    ),
  );
}

ScaffoldFeatureController<SnackBar, SnackBarClosedReason>
    showNeoSuccessSnackBar(
  BuildContext context,
  String message,
) {
  return showNeoSnackBar(
    context,
    _buildIconSnackBar(
      context,
      message: message,
      icon: LucideIcons.checkCircle,
      backgroundColor: NeoTheme.positiveValue(context),
    ),
  );
}

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showNeoInfoSnackBar(
  BuildContext context,
  String message,
) {
  return showNeoSnackBar(
    context,
    _buildIconSnackBar(
      context,
      message: message,
      icon: LucideIcons.info,
      backgroundColor: NeoTheme.infoValue(context),
    ),
  );
}

SnackBar _buildIconSnackBar(
  BuildContext context, {
  required String message,
  required IconData icon,
  required Color backgroundColor,
}) {
  return SnackBar(
    content: Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(message)),
      ],
    ),
    backgroundColor: backgroundColor,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizing.radiusSm),
    ),
  );
}
