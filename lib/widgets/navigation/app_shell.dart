import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';

/// Main app shell with bottom navigation bar
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

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: LucideIcons.home,
                label: 'Home',
                isSelected: location == '/home',
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.go('/home');
                },
              ),
              _NavItem(
                icon: LucideIcons.creditCard,
                label: 'Transactions',
                isSelected: location == '/transactions',
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.go('/transactions');
                },
              ),
              _NavItem(
                icon: LucideIcons.pieChart,
                label: 'Budget',
                isSelected: location.startsWith('/budget') || location.startsWith('/expenses'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.go('/budget');
                },
              ),
              _NavItem(
                icon: LucideIcons.repeat,
                label: 'Subscriptions',
                isSelected: location == '/subscriptions',
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.go('/subscriptions');
                },
              ),
              _NavItem(
                icon: LucideIcons.settings,
                label: 'Settings',
                isSelected: location == '/settings',
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.go('/settings');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
