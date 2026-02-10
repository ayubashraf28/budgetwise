import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// Shared dropdown item label that avoids flex-based children.
///
/// Using [Expanded]/[Flexible] inside `DropdownMenuItem` can trigger
/// "RenderFlex children have non-zero flex but incoming constraints are
/// unbounded" during intrinsic measurement.
class DropdownMenuItemLabel extends StatelessWidget {
  final Widget leading;
  final String text;
  final TextStyle? textStyle;
  final double leadingWidth;

  const DropdownMenuItemLabel({
    super.key,
    required this.leading,
    required this.text,
    this.textStyle,
    this.leadingWidth = 24,
  });

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);
    final effectiveTextStyle = textStyle ??
        AppTypography.bodyLarge.copyWith(
          color: palette.textPrimary,
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final fallbackWidth =
            MediaQuery.sizeOf(context).width - (AppSpacing.md * 2);
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : fallbackWidth;
        final textWidth =
            (maxWidth - leadingWidth - AppSpacing.sm).clamp(72.0, 520.0);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: leadingWidth, child: Center(child: leading)),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: textWidth.toDouble(),
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: effectiveTextStyle,
              ),
            ),
          ],
        );
      },
    );
  }
}
