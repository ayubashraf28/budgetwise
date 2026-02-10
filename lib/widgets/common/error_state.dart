import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';

/// Reusable error state widget
class ErrorState extends StatelessWidget {
  final String? message;
  final String? actionLabel;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    this.message,
    this.actionLabel,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);
    final danger = NeoTheme.negativeValue(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizing.radiusXl),
              ),
              child: Icon(
                LucideIcons.alertTriangle,
                size: 40,
                color: danger,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Something went wrong',
              style: AppTypography.h3.copyWith(color: palette.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(LucideIcons.refreshCw, size: 18),
                label: Text(actionLabel ?? 'Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shows an error snackbar with the given message
void showErrorSnackBar(BuildContext context, String message) {
  final danger = NeoTheme.negativeValue(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(LucideIcons.alertCircle, color: Colors.white, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizing.radiusSm),
      ),
    ),
  );
}

/// Shows a success snackbar with the given message
void showSuccessSnackBar(BuildContext context, String message) {
  final success = NeoTheme.positiveValue(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(LucideIcons.checkCircle, color: Colors.white, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizing.radiusSm),
      ),
    ),
  );
}

/// Shows an info snackbar with the given message
void showInfoSnackBar(BuildContext context, String message) {
  final info = NeoTheme.infoValue(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(LucideIcons.info, color: Colors.white, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: info,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizing.radiusSm),
      ),
    ),
  );
}
