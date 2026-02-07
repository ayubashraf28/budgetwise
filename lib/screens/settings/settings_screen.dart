import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../providers/providers.dart';
import 'currency_picker_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    final currentCurrency = ref.watch(currencyProvider);
    final currentSymbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Account Section
            _buildSectionHeader('Account'),
            const SizedBox(height: AppSpacing.sm),
            _buildSettingsCard([
              _SettingsTile(
                icon: LucideIcons.user,
                title: 'Profile',
                subtitle: ref.watch(userProfileProvider).valueOrNull?.displayName ?? user?.email ?? 'Not signed in',
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.push('/settings/profile');
                },
              ),
            ]),
            const SizedBox(height: AppSpacing.lg),

            // Budget Section
            _buildSectionHeader('Budget'),
            const SizedBox(height: AppSpacing.sm),
            _buildSettingsCard([
              _SettingsTile(
                icon: LucideIcons.calendar,
                title: 'Month History',
                onTap: () {
                  HapticFeedback.selectionClick();
                  // TODO: Navigate to month history
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Month history coming soon')),
                  );
                },
              ),
              const Divider(height: 1, color: AppColors.border),
              _SettingsTile(
                icon: LucideIcons.poundSterling,
                title: 'Currency',
                trailing: Text(
                  '$currentSymbol $currentCurrency',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                onTap: () {
                  HapticFeedback.selectionClick();
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const CurrencyPickerSheet(),
                  );
                },
              ),
            ]),
            const SizedBox(height: AppSpacing.lg),

            // App Section
            _buildSectionHeader('App'),
            const SizedBox(height: AppSpacing.sm),
            _buildSettingsCard([
              _SettingsTile(
                icon: LucideIcons.info,
                title: 'About',
                onTap: () {
                  HapticFeedback.selectionClick();
                  _showAboutDialog(context);
                },
              ),
              const Divider(height: 1, color: AppColors.border),
              _SettingsTile(
                icon: LucideIcons.download,
                title: 'Export Data',
                onTap: () {
                  HapticFeedback.selectionClick();
                  // TODO: Implement data export
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export feature coming soon')),
                  );
                },
              ),
            ]),
            const SizedBox(height: AppSpacing.lg),

            // Sign Out Button
            _buildSettingsCard([
              _SettingsTile(
                icon: LucideIcons.logOut,
                title: 'Sign Out',
                titleColor: AppColors.error,
                showChevron: false,
                onTap: () => _handleSignOut(context, ref),
              ),
            ]),
            const SizedBox(height: AppSpacing.xl),

            // Version
            const Center(
              child: Text(
                'Version 0.0.5',
                style: AppTypography.bodySmall,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.labelMedium.copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        ),
        title: const Text(
          'BudgetWise',
          style: AppTypography.h3,
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal budgeting made simple.',
              style: AppTypography.bodyLarge,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Plan your spending, track your expenses, and build better financial habits.',
              style: AppTypography.bodyMedium,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Version 1.0.0',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    HapticFeedback.mediumImpact();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        ),
        title: const Text(
          'Sign Out',
          style: AppTypography.h3,
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: AppTypography.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(authNotifierProvider.notifier).signOut();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? titleColor;
  final bool showChevron;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.titleColor,
    this.showChevron = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: titleColor ?? AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyLarge.copyWith(
                        color: titleColor ?? AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: AppTypography.bodySmall,
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (showChevron)
                const Icon(
                  LucideIcons.chevronRight,
                  size: 20,
                  color: AppColors.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
