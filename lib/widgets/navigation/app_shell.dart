import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

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

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final width = MediaQuery.sizeOf(context).width;
    final textScale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.15).toDouble();

    final centerGap = (width * 0.19).clamp(74.0, 86.0).toDouble();
    final iconSize = width < 360 ? 22.0 : 24.0;
    final labelSize = (width < 360 ? 11.0 : 12.0) * textScale;
    final barCoreHeight = (60.0 + (textScale - 1.0) * 10.0).clamp(60.0, 66.0);
    final totalHeight = barCoreHeight + bottomInset;
    final navBg = isLight ? const Color(0xFFF8FAFD) : const Color(0xFF2B2F36);
    final navStroke =
        isLight ? const Color(0xFFD5DCE8) : const Color(0xFF3A3F4B);

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
              padding: EdgeInsets.fromLTRB(12, 10, 12, 8 + bottomInset),
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
                            isSelected: location.startsWith('/manage') ||
                                location.startsWith('/subscriptions') ||
                                location.startsWith('/settings/accounts'),
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
            child: _AddButton(
              onTap: () {
                HapticFeedback.mediumImpact();
                context.go('/transactions/new');
              },
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final buttonBg =
        isLight ? const Color(0xFFFFFFFF) : const Color(0xFFF5F7FC);
    final buttonStroke =
        isLight ? const Color(0xFFD0D8E5) : const Color(0xFF3A3F4B);
    final iconColor =
        isLight ? const Color(0xFF1A202A) : const Color(0xFF202631);

    return Material(
      color: Colors.transparent,
      child: InkWell(
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
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final double iconSize;
  final double labelSize;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.iconSize,
    required this.labelSize,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final color = isSelected
        ? (isLight ? const Color(0xFF708225) : const Color(0xFFD8E37A))
        : (isLight ? const Color(0xFF7C8698) : const Color(0xFFA3AAB8));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 42,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: iconSize),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: labelSize,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
