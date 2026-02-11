import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';

class NeoPageBackground extends StatelessWidget {
  final Widget child;

  const NeoPageBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);
    final isLight = NeoTheme.isLight(context);
    final textureColor = isLight
        ? Colors.black.withValues(alpha: 0.018)
        : Colors.white.withValues(alpha: 0.025);

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [palette.appBg, palette.appBg],
            ),
          ),
        ),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.85, -0.95),
                radius: 1.25,
                colors: [textureColor, Colors.transparent],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class NeoPageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showSettingsAction;

  const NeoPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showSettingsAction = true,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: NeoTypography.pageTitle(context),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: NeoTypography.pageContext(context),
                ),
              ],
            ),
          ),
          if (showSettingsAction) ...[
            const SizedBox(width: AppSpacing.sm),
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: NeoSettingsHeaderButton(),
            ),
          ],
        ],
      ),
    );
  }
}

class NeoGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const NeoGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);
    final shadowColor = NeoTheme.isLight(context)
        ? Colors.black.withValues(alpha: 0.14)
        : palette.appBg.withValues(alpha: 0.86);

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(NeoLayout.cardRadius),
        border: Border.all(color: palette.stroke),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class NeoSectionActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  const NeoSectionActionButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);
    final isLight = NeoTheme.isLight(context);
    final textScale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(0.85, 1.3).toDouble();
    final minHeight = (34.0 + (textScale - 1.0) * 10.0).clamp(34.0, 44.0);
    final verticalPadding = (8.0 + (textScale - 1.0) * 4.0).clamp(8.0, 12.0);
    final style = OutlinedButton.styleFrom(
      foregroundColor: palette.accent,
      padding: EdgeInsets.symmetric(
        horizontal: icon == null ? 10 : 12,
        vertical: verticalPadding,
      ),
      minimumSize: Size(0, minHeight),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      backgroundColor:
          isLight ? palette.accent.withValues(alpha: 0.10) : Colors.transparent,
      side: BorderSide(
        color: palette.accent.withValues(alpha: isLight ? 0.55 : 0.4),
        width: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
      ),
    );

    if (icon == null) {
      return OutlinedButton(
        onPressed: onPressed,
        style: style,
        child: Text(label, style: NeoTypography.sectionAction(context)),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      style: style,
      icon: Icon(icon, size: NeoIconSizes.sm, color: palette.accent),
      label: Text(label, style: NeoTypography.sectionAction(context)),
    );
  }
}

class NeoCircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? semanticLabel;
  final double size;
  final double iconSize;

  const NeoCircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.semanticLabel,
    this.size = NeoControlSizing.compactActionSize,
    this.iconSize = NeoControlSizing.compactActionIconSize,
  });

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);
    final isLight = NeoTheme.isLight(context);

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSizing.radiusFull),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isLight
                ? palette.accent.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizing.radiusFull),
            border: Border.all(
              color: palette.accent.withValues(alpha: isLight ? 0.55 : 0.4),
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              size: iconSize,
              color: palette.accent,
            ),
          ),
        ),
      ),
    );

    if (semanticLabel == null) return button;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: button,
    );
  }
}

class NeoSettingsHeaderButton extends StatelessWidget {
  final double size;

  const NeoSettingsHeaderButton({
    super.key,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);

    return Semantics(
      button: true,
      label: 'Open settings',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final location = GoRouterState.of(context).matchedLocation;
            if (location == '/settings') return;
            context.push('/settings');
          },
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: palette.surface2,
              borderRadius: BorderRadius.circular(AppSizing.radiusMd),
              border: Border.all(color: palette.stroke),
            ),
            child: Icon(
              LucideIcons.settings,
              size: NeoIconSizes.lg,
              color: palette.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class NeoSettingsAppBarAction extends StatelessWidget {
  const NeoSettingsAppBarAction({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(right: AppSpacing.xs),
      child: Center(
        child: NeoSettingsHeaderButton(size: 36),
      ),
    );
  }
}

class NeoSectionChevronButton extends StatelessWidget {
  final bool expanded;
  final VoidCallback onPressed;

  const NeoSectionChevronButton({
    super.key,
    required this.expanded,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppSizing.radiusFull),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: palette.surface2,
          borderRadius: BorderRadius.circular(AppSizing.radiusFull),
          border: Border.all(color: palette.stroke),
        ),
        child: Icon(
          expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
          size: NeoIconSizes.md,
          color: palette.textSecondary,
        ),
      ),
    );
  }
}

class NeoHubRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? trailingTop;
  final String? trailingBottom;
  final Color? trailingColor;
  final VoidCallback onTap;

  const NeoHubRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingTop,
    this.trailingBottom,
    this.trailingColor,
  });

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: palette.surface2,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: palette.stroke),
              ),
              child: Icon(
                icon,
                size: NeoIconSizes.lg,
                color: iconColor,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: NeoTypography.rowTitle(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: NeoTypography.rowSecondary(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (trailingTop == null && trailingBottom == null)
              Icon(
                LucideIcons.chevronRight,
                size: NeoIconSizes.lg,
                color: palette.textSecondary,
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (trailingTop != null)
                    Text(
                      trailingTop!,
                      style: NeoTypography.rowAmount(
                        context,
                        trailingColor ?? palette.textPrimary,
                      ),
                    ),
                  if (trailingBottom != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      trailingBottom!,
                      style: NeoTypography.rowSecondary(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}
