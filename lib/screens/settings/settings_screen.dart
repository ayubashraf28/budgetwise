import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/constants.dart';
import '../../config/supabase_config.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../utils/errors/error_mapper.dart';
import '../../widgets/common/neo_page_components.dart';
import '../../widgets/common/neo_snackbar.dart';
import 'settings_screen_helpers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isDeletingAllData = false;
  bool _isDeletingAccount = false;

  void _setIsDeletingAllData(bool value) {
    if (!mounted) {
      _isDeletingAllData = value;
      return;
    }
    setState(() => _isDeletingAllData = value);
  }

  void _setIsDeletingAccount(bool value) {
    if (!mounted) {
      _isDeletingAccount = value;
      return;
    }
    setState(() => _isDeletingAccount = value);
  }

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final currentThemeMode = ref.watch(themeModeProvider);
    final currentBudgetStructure = ref.watch(budgetStructureProvider);
    final isAnonymous = ref.watch(isAnonymousProvider);

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
            if (isAnonymous) ...[
              _buildAnonymousBanner(context),
              const SizedBox(height: NeoLayout.sectionGap),
            ],
            buildSettingsCard(
              context,
              children: [
                SettingsGroupTile(
                  icon: LucideIcons.user,
                  title: 'Account & Profile',
                  subtitle:
                      profile?.displayName ?? user?.email ?? 'Not signed in',
                  onTap: () => context.push('/settings/account'),
                ),
                const Divider(height: 1),
                SettingsGroupTile(
                  icon: LucideIcons.wallet,
                  title: 'Budget',
                  subtitle: currentBudgetStructure == BudgetStructure.simple
                      ? 'Simple mode'
                      : 'Detailed mode',
                  onTap: () => context.push('/settings/budget'),
                ),
                const Divider(height: 1),
                SettingsGroupTile(
                  icon: LucideIcons.palette,
                  title: 'Appearance',
                  subtitle: themeModeLabel(currentThemeMode),
                  onTap: () => context.push('/settings/appearance'),
                ),
                const Divider(height: 1),
                SettingsGroupTile(
                  icon: LucideIcons.bell,
                  title: 'Notifications',
                  subtitle:
                      (profile?.notificationsEnabled ?? true) ? 'On' : 'Off',
                  onTap: () => context.push('/settings/notifications-settings'),
                ),
                const Divider(height: 1),
                SettingsGroupTile(
                  icon: LucideIcons.info,
                  title: 'About & Legal',
                  onTap: () => context.push('/settings/about'),
                ),
                const Divider(height: 1),
                SettingsGroupTile(
                  icon: LucideIcons.helpCircle,
                  title: 'Help & Support',
                  onTap: () => context.push('/settings/support'),
                ),
              ],
            ),
            const SizedBox(height: NeoLayout.sectionGap),
            buildSettingsSectionHeader(context, 'Danger Zone'),
            const SizedBox(height: AppSpacing.sm),
            buildSettingsCard(
              context,
              children: [
                SettingsTile(
                  icon: LucideIcons.trash2,
                  title: 'Delete All Data',
                  subtitle: 'Permanently remove your app data',
                  titleColor: NeoTheme.negativeValue(context),
                  showChevron: false,
                  trailing: _isDeletingAllData
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: NeoTheme.negativeValue(context),
                          ),
                        )
                      : null,
                  onTap: _isDeletingAllData ? () {} : _confirmDeleteAllData,
                ),
                const Divider(height: 1),
                SettingsTile(
                  icon: LucideIcons.userX,
                  title: 'Delete Account',
                  subtitle: 'Permanently delete your account and all data',
                  titleColor: NeoTheme.negativeValue(context),
                  showChevron: false,
                  trailing: _isDeletingAccount
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: NeoTheme.negativeValue(context),
                          ),
                        )
                      : null,
                  onTap: _isDeletingAccount ? () {} : _confirmDeleteAccount,
                ),
              ],
            ),
            const SizedBox(height: NeoLayout.sectionGap),
            buildSettingsCard(
              context,
              children: [
                SettingsTile(
                  icon: LucideIcons.logOut,
                  title: 'Sign Out',
                  titleColor: NeoTheme.negativeValue(context),
                  showChevron: false,
                  onTap: () => handleSettingsSignOut(context, ref),
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

  Future<void> _confirmDeleteAccount() async {
    final palette = NeoTheme.of(context);
    final controller = TextEditingController();
    var canDelete = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            backgroundColor: palette.surface1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizing.radiusLg),
              side: BorderSide(color: palette.stroke),
            ),
            title: Text(
              'Delete Account',
              style: AppTypography.h3.copyWith(
                color: NeoTheme.negativeValue(dialogContext),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This will permanently delete your account and all associated data. This action cannot be undone.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'You will be signed out and will not be able to recover your data.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: NeoTheme.negativeValue(dialogContext),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Type DELETE to confirm:',
                  style: AppTypography.bodySmall.copyWith(
                    color: palette.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  controller: controller,
                  onChanged: (value) {
                    setDialogState(() => canDelete = value.trim() == 'DELETE');
                  },
                  decoration: InputDecoration(
                    hintText: 'DELETE',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: _isDeletingAccount
                    ? null
                    : () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: (!canDelete || _isDeletingAccount)
                    ? null
                    : () => Navigator.of(dialogContext).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: NeoTheme.negativeValue(dialogContext),
                ),
                child: const Text('Delete Account'),
              ),
            ],
          );
        },
      ),
    );

    controller.dispose();

    if (!mounted) return;
    if (confirmed == true) {
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    if (_isDeletingAccount) return;
    _setIsDeletingAccount(true);

    var loadingDialogShown = false;
    if (mounted) {
      loadingDialogShown = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      await SupabaseConfig.client.functions.invoke('delete-user');

      if (!mounted) return;
      if (loadingDialogShown) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      await ref.read(authNotifierProvider.notifier).signOut();

      if (!mounted) return;
      context.go('/login');
    } catch (error, stackTrace) {
      if (!mounted) return;
      if (loadingDialogShown) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      showNeoErrorSnackBar(
        context,
        ErrorMapper.toUserMessage(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Failed to delete account. Please try again.',
        ),
      );
    } finally {
      if (mounted) {
        _setIsDeletingAccount(false);
      }
    }
  }

  Future<void> _confirmDeleteAllData() async {
    final palette = NeoTheme.of(context);
    final controller = TextEditingController();
    var canDelete = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            backgroundColor: palette.surface1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizing.radiusLg),
              side: BorderSide(color: palette.stroke),
            ),
            title: Text(
              'Delete All Data',
              style: AppTypography.h3.copyWith(
                color: NeoTheme.negativeValue(dialogContext),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This will permanently delete all app data in Supabase while keeping your auth account.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Type DELETE to confirm:',
                  style: AppTypography.bodySmall.copyWith(
                    color: palette.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  controller: controller,
                  onChanged: (value) {
                    setDialogState(() => canDelete = value.trim() == 'DELETE');
                  },
                  decoration: InputDecoration(
                    hintText: 'DELETE',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: _isDeletingAllData
                    ? null
                    : () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: (!canDelete || _isDeletingAllData)
                    ? null
                    : () => Navigator.of(dialogContext).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: NeoTheme.negativeValue(dialogContext),
                ),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      ),
    );

    controller.dispose();

    if (!mounted) return;
    if (confirmed == true) {
      final finalConfirmation = await _showFinalDeleteAllDataConfirmation();
      if (!mounted || !finalConfirmation) return;
      await _deleteAllData();
    }
  }

  Future<bool> _showFinalDeleteAllDataConfirmation() async {
    final palette = NeoTheme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: palette.surface1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
          side: BorderSide(color: palette.stroke),
        ),
        title: Text(
          'Final Confirmation',
          style: AppTypography.h3.copyWith(
            color: NeoTheme.negativeValue(dialogContext),
          ),
        ),
        content: Text(
          'This will permanently delete all categories, items, transactions, accounts, subscriptions, and reports. This cannot be undone.',
          style: AppTypography.bodyMedium.copyWith(
            color: palette.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: NeoTheme.negativeValue(dialogContext),
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    return confirmed == true;
  }

  Future<void> _deleteAllData() async {
    if (_isDeletingAllData) return;
    _setIsDeletingAllData(true);

    var loadingDialogShown = false;
    if (mounted) {
      loadingDialogShown = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      await ref
          .read(profileResetNotifierProvider.notifier)
          .deleteAllDataAndSignOut();
      if (!mounted) return;

      if (loadingDialogShown) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      context.go('/login');
    } catch (error, stackTrace) {
      if (!mounted) return;
      if (loadingDialogShown) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      showNeoErrorSnackBar(
        context,
        ErrorMapper.toUserMessage(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Failed to delete data. Please try again.',
        ),
      );
    } finally {
      if (mounted) {
        _setIsDeletingAllData(false);
      }
    }
  }

  Widget _buildAnonymousBanner(BuildContext context) {
    final warningColor = NeoTheme.warningValue(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        border: Border.all(color: warningColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.alertTriangle, color: warningColor, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Guest Mode',
                  style: TextStyle(
                    color: warningColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your data is not saved to an account. Create an account to keep your budget data.',
                  style: TextStyle(
                    color: warningColor.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => context.push('/register'),
                  style: TextButton.styleFrom(
                    foregroundColor: warningColor,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 28),
                  ),
                  child: const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
