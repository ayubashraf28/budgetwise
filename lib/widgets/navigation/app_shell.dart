import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/motion.dart';
import '../../config/theme.dart';
import '../motion/neo_pressable.dart';

/// Main app shell with bottom navigation bar.
class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const _BottomNavBar(),
    );
  }
}

class _BottomNavBar extends StatefulWidget {
  const _BottomNavBar();

  @override
  State<_BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<_BottomNavBar> {
  bool _showFab = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _showFab = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final palette = NeoTheme.of(context);
    final isLight = NeoTheme.isLight(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final width = MediaQuery.sizeOf(context).width;
    final textScale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(0.85, 1.3).toDouble();

    final centerGap = (width * 0.19).clamp(74.0, 86.0).toDouble();
    final iconSize = width < 360 ? 22.0 : 24.0;
    final labelSize = width < 360 ? 11.0 : 12.0;
    final navItemHeight = (42.0 + (textScale - 1.0) * 16.0).clamp(42.0, 52.0);
    final barCoreHeight = (60.0 + (textScale - 1.0) * 22.0).clamp(60.0, 72.0);
    final totalHeight = barCoreHeight + bottomInset;
    final navBg = palette.surface1;
    final navStroke = palette.stroke;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: barCoreHeight + bottomInset,
              padding: EdgeInsets.fromLTRB(12, 8, 12, 6 + bottomInset),
              decoration: BoxDecoration(
                color: navBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                border: Border(
                  top: BorderSide(color: navStroke),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withValues(alpha: isLight ? 0.14 : 0.32),
                    blurRadius: 20,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _NavItem(
                            icon: LucideIcons.home,
                            label: 'Home',
                            iconSize: iconSize,
                            labelSize: labelSize,
                            itemHeight: navItemHeight,
                            isSelected: location == '/home',
                            onTap: () {
                              HapticFeedback.selectionClick();
                              context.go('/home');
                            },
                          ),
                        ),
                        Expanded(
                          child: _NavItem(
                            icon: LucideIcons.pieChart,
                            label: 'Analysis',
                            iconSize: iconSize,
                            labelSize: labelSize,
                            itemHeight: navItemHeight,
                            isSelected: location.startsWith('/analysis') ||
                                location.startsWith('/budget') ||
                                location.startsWith('/expenses'),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              context.go('/analysis');
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: centerGap),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _NavItem(
                            icon: LucideIcons.layoutList,
                            label: 'Categories',
                            iconSize: iconSize,
                            labelSize: labelSize,
                            itemHeight: navItemHeight,
                            isSelected: location.startsWith('/categories') ||
                                location.startsWith('/income'),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              context.go('/categories');
                            },
                          ),
                        ),
                        Expanded(
                          child: _NavItem(
                            icon: LucideIcons.slidersHorizontal,
                            label: 'Manage',
                            iconSize: iconSize,
                            labelSize: labelSize,
                            itemHeight: navItemHeight,
                            isSelected: location.startsWith('/manage') ||
                                location.startsWith('/subscriptions') ||
                                location.startsWith('/accounts/') ||
                                location.startsWith('/settings') ||
                                location.startsWith('/budget-overview'),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              context.go('/manage');
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: -16,
            child: AnimatedScale(
              scale: _showFab && neoAnimationsEnabled(context) ? 1 : 0.92,
              duration: NeoMotionDuration.standard,
              curve: NeoMotionCurve.entrance,
              child: AnimatedOpacity(
                opacity: _showFab && neoAnimationsEnabled(context) ? 1 : 0,
                duration: NeoMotionDuration.standard,
                curve: NeoMotionCurve.entrance,
                child: _AddButton(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.go('/transactions/new');
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);
    final isLight = NeoTheme.isLight(context);
    final buttonBg = palette.surface2;
    final buttonStroke = palette.stroke;
    final iconColor = palette.textPrimary;

    return NeoPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: buttonBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: buttonStroke),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isLight ? 0.18 : 0.35),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          LucideIcons.plus,
          size: 26,
          color: iconColor,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final double iconSize;
  final double labelSize;
  final double itemHeight;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.iconSize,
    required this.labelSize,
    required this.itemHeight,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);
    final isLight = NeoTheme.isLight(context);
    final activeColor = palette.accent.withValues(alpha: isLight ? 0.92 : 0.88);
    final inactiveColor =
        palette.textMuted.withValues(alpha: isLight ? 0.82 : 0.9);
    final targetColor = isSelected ? activeColor : inactiveColor;

    return NeoPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: NeoMotionCurve.emphasis,
        height: itemHeight,
        decoration: BoxDecoration(
          color: isSelected
              ? palette.accent.withValues(alpha: isLight ? 0.12 : 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? palette.accent.withValues(alpha: isLight ? 0.30 : 0.24)
                : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: targetColor),
              duration: const Duration(milliseconds: 220),
              curve: NeoMotionCurve.emphasis,
              builder: (context, iconColor, _) {
                return AnimatedScale(
                  scale: isSelected ? 1.02 : 1,
                  duration: const Duration(milliseconds: 220),
                  curve: NeoMotionCurve.emphasis,
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: iconSize,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              curve: NeoMotionCurve.emphasis,
              style: TextStyle(
                color: targetColor,
                fontSize: labelSize,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                height: 1.0,
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
