import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/common/neo_page_components.dart';
import 'currency_picker_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = NeoTheme.of(context);
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    final currentCurrency = ref.watch(currencyProvider);
    final currentSymbol = ref.watch(currencySymbolProvider);
    final currentThemeMode = ref.watch(themeModeProvider);
    final currentAppFontSize = ref.watch(appFontSizeProvider);

    return Scaffold(
      backgroundColor: palette.appBg,
      body: NeoPageBackground(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            NeoLayout.screenPadding,
            0,
            NeoLayout.screenPadding,
            AppSpacing.xl +
                MediaQuery.paddingOf(context).bottom +
                NeoLayout.bottomNavSafeBuffer,
          ),
          children: [
            const SizedBox(height: AppSpacing.sm),
            const NeoPageHeader(
              title: 'Settings',
              subtitle: 'Account, budget preferences, and app controls',
            ),
            const SizedBox(height: NeoLayout.sectionGap),
            _buildSectionHeader(context, 'Account'),
            const SizedBox(height: AppSpacing.sm),
            _buildSettingsCard(
              context,
              children: [
                _SettingsTile(
                  icon: LucideIcons.user,
                  title: 'Profile',
                  subtitle:
                      ref.watch(userProfileProvider).valueOrNull?.displayName ??
                          user?.email ??
                          'Not signed in',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.push('/settings/profile');
                  },
                ),
              ],
            ),
            const SizedBox(height: NeoLayout.sectionGap),
            _buildSectionHeader(context, 'Budget'),
            const SizedBox(height: AppSpacing.sm),
            _buildSettingsCard(
              context,
              children: [
                _SettingsTile(
                  icon: LucideIcons.poundSterling,
                  title: 'Currency',
                  trailing: Text(
                    '$currentSymbol $currentCurrency',
                    style: NeoTypography.rowSecondary(context),
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
              ],
            ),
            const SizedBox(height: NeoLayout.sectionGap),
            _buildSectionHeader(context, 'Appearance'),
            const SizedBox(height: AppSpacing.sm),
            _buildSettingsCard(
              context,
              children: [
                _SettingsTile(
                  icon: LucideIcons.palette,
                  title: 'Theme',
                  subtitle: 'System default, light, or dark',
                  trailing: Text(
                    themeModeLabel(currentThemeMode),
                    style: NeoTypography.rowSecondary(context),
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _showThemeModeSheet(context, ref, currentThemeMode);
                  },
                ),
                _SettingsTile(
                  icon: LucideIcons.type,
                  title: 'Text Size',
                  subtitle: 'Small, medium, large, or extra large',
                  trailing: Text(
                    appFontSizeLabel(currentAppFontSize),
                    style: NeoTypography.rowSecondary(context),
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _showTextSizeSheet(context, ref, currentAppFontSize);
                  },
                ),
              ],
            ),
            const SizedBox(height: NeoLayout.sectionGap),
            _buildSectionHeader(context, 'App'),
            const SizedBox(height: AppSpacing.sm),
            _buildSettingsCard(
              context,
              children: [
                _SettingsTile(
                  icon: LucideIcons.info,
                  title: 'About',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _showAboutDialog(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: NeoLayout.sectionGap),
            _buildSettingsCard(
              context,
              children: [
                _SettingsTile(
                  icon: LucideIcons.logOut,
                  title: 'Sign Out',
                  titleColor: NeoTheme.negativeValue(context),
                  showChevron: false,
                  onTap: () => _handleSignOut(context, ref),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                'Version ${AppConstants.appVersion}',
                style: NeoTypography.rowSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: NeoTypography.sectionAction(context).copyWith(
        color: NeoTheme.of(context).textMuted,
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context,
      {required List<Widget> children}) {
    return NeoGlassCard(
      padding: EdgeInsets.zero,
      child: Column(children: children),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final palette = NeoTheme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: palette.surface1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
          side: BorderSide(color: palette.stroke),
        ),
        title: Text(
          'BudgetWise',
          style: AppTypography.h3.copyWith(color: palette.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal budgeting made simple.',
              style:
                  AppTypography.bodyLarge.copyWith(color: palette.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Plan your spending, track your expenses, and build better financial habits.',
              style: AppTypography.bodyMedium
                  .copyWith(color: palette.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Version ${AppConstants.appVersion}',
              style: AppTypography.bodySmall.copyWith(color: palette.textMuted),
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

  void _showThemeModeSheet(
    BuildContext context,
    WidgetRef ref,
    ThemeMode currentMode,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final palette = NeoTheme.of(sheetContext);

        Future<void> setMode(ThemeMode mode) async {
          await setThemeModePreference(ref, mode);
          if (sheetContext.mounted) {
            Navigator.of(sheetContext).pop();
          }
        }

        Widget option(ThemeMode mode, String label) {
          final isSelected = currentMode == mode;
          return ListTile(
            onTap: () => setMode(mode),
            leading: Icon(
              isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
              color: isSelected ? palette.accent : palette.textMuted,
            ),
            title: Text(
              label,
              style: AppTypography.bodyLarge.copyWith(
                color: isSelected ? palette.textPrimary : palette.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: NeoGlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Choose theme',
                    style: NeoTypography.sectionTitle(sheetContext),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  option(ThemeMode.system, 'System default'),
                  option(ThemeMode.light, 'Light'),
                  option(ThemeMode.dark, 'Dark'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTextSizeSheet(
    BuildContext context,
    WidgetRef ref,
    AppFontSize currentSize,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final palette = NeoTheme.of(sheetContext);

        Future<void> setSize(AppFontSize size) async {
          await ref.read(uiPreferencesProvider.notifier).setAppFontSize(size);
          if (sheetContext.mounted) {
            Navigator.of(sheetContext).pop();
          }
        }

        Widget option(AppFontSize size) {
          final isSelected = currentSize == size;
          return ListTile(
            onTap: () => setSize(size),
            leading: Icon(
              isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
              color: isSelected ? palette.accent : palette.textMuted,
            ),
            title: Text(
              appFontSizeLabel(size),
              style: AppTypography.bodyLarge.copyWith(
                color: isSelected ? palette.textPrimary : palette.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            subtitle: MediaQuery(
              data: MediaQuery.of(sheetContext).copyWith(
                textScaler: TextScaler.linear(size.scaleFactor),
              ),
              child: Text(
                'The quick brown fox jumps over the lazy dog.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: palette.textMuted,
                ),
              ),
            ),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: NeoGlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Text size',
                    style: NeoTypography.sectionTitle(sheetContext),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final size in AppFontSize.values) option(size),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    HapticFeedback.mediumImpact();
    final palette = NeoTheme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: palette.surface1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
          side: BorderSide(color: palette.stroke),
        ),
        title: Text(
          'Sign Out',
          style: AppTypography.h3.copyWith(color: palette.textPrimary),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: AppTypography.bodyLarge.copyWith(color: palette.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: NeoTheme.negativeValue(context),
            ),
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
              backgroundColor: NeoTheme.negativeValue(context),
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
    final palette = NeoTheme.of(context);

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
                size: NeoIconSizes.xl,
                color: titleColor ?? palette.textSecondary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: NeoTypography.rowTitle(context).copyWith(
                        color: titleColor ?? palette.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: NeoTypography.rowSecondary(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (showChevron)
                Icon(
                  LucideIcons.chevronRight,
                  size: NeoIconSizes.lg,
                  color: palette.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
