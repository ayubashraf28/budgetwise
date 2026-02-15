part of 'settings_screen.dart';

extension _SettingsScreenHelpers on _SettingsScreenState {
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: NeoTypography.sectionAction(context).copyWith(
        color: NeoTheme.of(context).textMuted,
      ),
    );
  }

  void _showBugReportSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BugReportFormSheet(),
    );
  }

  void _showFeedbackSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BugReportFormSheet(
        feedbackMode: true,
        initialCategory: BugReportCategory.feedback,
      ),
    );
  }

  Widget _buildNotificationToggleTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    final palette = NeoTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: NeoIconSizes.xl,
            color: enabled ? palette.textSecondary : palette.textMuted,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: NeoTypography.rowTitle(context).copyWith(
                    color: enabled ? palette.textPrimary : palette.textMuted,
                  ),
                ),
                Text(
                  subtitle,
                  style: NeoTypography.rowSecondary(context).copyWith(
                    color: enabled ? palette.textSecondary : palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeTrackColor: palette.accent,
          ),
        ],
      ),
    );
  }

  Future<void> _updateNotificationPreferences({
    bool? masterEnabled,
    bool? subscriptionRemindersEnabled,
    bool? budgetAlertsEnabled,
    bool? monthlyRemindersEnabled,
  }) async {
    final current = ref.read(userProfileProvider).valueOrNull;
    final currentMaster = current?.notificationsEnabled ?? true;

    try {
      if (masterEnabled != null) {
        if (masterEnabled && !currentMaster) {
          final granted = await ref
              .read(notificationServiceProvider)
              .requestPermissionIfNeeded();
          if (!granted) {
            await ref.read(profileNotifierProvider.notifier).updateProfile(
                  notificationsEnabled: false,
                  subscriptionRemindersEnabled: false,
                  budgetAlertsEnabled: false,
                  monthlyRemindersEnabled: false,
                );
            ref.invalidate(userProfileProvider);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Notification permission denied. You can enable it later in system settings.',
                ),
                backgroundColor: NeoTheme.warningValue(context),
              ),
            );
            return;
          }
        }

        await ref.read(profileNotifierProvider.notifier).updateProfile(
              notificationsEnabled: masterEnabled,
              subscriptionRemindersEnabled: masterEnabled ? true : false,
              budgetAlertsEnabled: masterEnabled ? true : false,
              monthlyRemindersEnabled: masterEnabled ? true : false,
            );
      } else {
        await ref.read(profileNotifierProvider.notifier).updateProfile(
              subscriptionRemindersEnabled: subscriptionRemindersEnabled,
              budgetAlertsEnabled: budgetAlertsEnabled,
              monthlyRemindersEnabled: monthlyRemindersEnabled,
            );
      }

      ref.invalidate(userProfileProvider);
      ref.invalidate(notificationNotifierProvider);
    } catch (error, stackTrace) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ErrorMapper.toUserMessage(error, stackTrace: stackTrace),
          ),
          backgroundColor: NeoTheme.negativeValue(context),
        ),
      );
    }
  }

  void _showLinkedAccountsDialog(
    BuildContext context, {
    required bool hasEmailLinked,
    required bool hasGoogleLinked,
  }) {
    final palette = NeoTheme.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: palette.surface1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
          side: BorderSide(color: palette.stroke),
        ),
        title: Text(
          'Linked Accounts',
          style: AppTypography.h3.copyWith(color: palette.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _linkedProviderRow(
              context,
              provider: 'Email',
              linked: hasEmailLinked,
            ),
            const SizedBox(height: AppSpacing.sm),
            _linkedProviderRow(
              context,
              provider: 'Google',
              linked: hasGoogleLinked,
            ),
            if (!hasGoogleLinked) ...[
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLinkingGoogle
                      ? null
                      : () async {
                          await _handleLinkGoogle();
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.accent,
                    foregroundColor: NeoTheme.isLight(context)
                        ? palette.textPrimary
                        : palette.surface1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                    ),
                  ),
                  child: _isLinkingGoogle
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Link Google Account'),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _linkedProviderRow(
    BuildContext context, {
    required String provider,
    required bool linked,
  }) {
    final palette = NeoTheme.of(context);
    return Row(
      children: [
        Icon(
          linked ? LucideIcons.checkCircle2 : LucideIcons.circle,
          size: NeoIconSizes.lg,
          color: linked ? NeoTheme.positiveValue(context) : palette.textMuted,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            provider,
            style: AppTypography.bodyLarge.copyWith(color: palette.textPrimary),
          ),
        ),
        Text(
          linked ? 'Linked' : 'Not linked',
          style: AppTypography.bodySmall.copyWith(
            color: linked ? NeoTheme.positiveValue(context) : palette.textMuted,
          ),
        ),
      ],
    );
  }

  Future<void> _handleLinkGoogle() async {
    if (_isLinkingGoogle) return;
    _setIsLinkingGoogle(true);

    try {
      await ref.read(authNotifierProvider.notifier).linkGoogleAccount();
      ref.invalidate(linkedProvidersProvider);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Google account linked successfully'),
          backgroundColor: NeoTheme.positiveValue(context),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ErrorMapper.toUserMessage(
              e,
              fallbackMessage: 'Unable to link Google account right now.',
            ),
          ),
          backgroundColor: NeoTheme.negativeValue(context),
        ),
      );
    } finally {
      if (mounted) {
        _setIsLinkingGoogle(false);
      }
    }
  }

  Future<void> _confirmDeleteAllData() async {
    final palette = NeoTheme.of(context);
    final controller = TextEditingController();
    bool canDelete = false;

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
                color: NeoTheme.negativeValue(context),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This will permanently delete all app data in Supabase while keeping your auth account.',
                  style: AppTypography.bodyMedium
                      .copyWith(color: palette.textSecondary),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Type DELETE to confirm:',
                  style: AppTypography.bodySmall
                      .copyWith(color: palette.textMuted),
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
                  foregroundColor: NeoTheme.negativeValue(context),
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
      await _deleteAllData();
    }
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
        builder: (dialogContext) => const Center(
          child: CircularProgressIndicator(),
        ),
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
    } catch (e) {
      if (!mounted) return;
      if (loadingDialogShown) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ErrorMapper.toUserMessage(
              e,
              fallbackMessage: 'Failed to delete data. Please try again.',
            ),
          ),
          backgroundColor: NeoTheme.negativeValue(context),
        ),
      );
    } finally {
      if (mounted) {
        _setIsDeletingAllData(false);
      }
    }
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

  void _showBudgetStructureSheet(
    BuildContext context,
    WidgetRef ref,
    BudgetStructure currentStructure,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final palette = NeoTheme.of(sheetContext);

        Future<void> setStructure(BudgetStructure structure) async {
          await ref
              .read(uiPreferencesProvider.notifier)
              .setBudgetStructure(structure);
          if (sheetContext.mounted) {
            Navigator.of(sheetContext).pop();
          }
        }

        Widget option({
          required BudgetStructure structure,
          required String label,
          required String description,
        }) {
          final isSelected = currentStructure == structure;
          return ListTile(
            onTap: () => setStructure(structure),
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
            subtitle: Text(
              description,
              style: AppTypography.bodySmall.copyWith(
                color: palette.textMuted,
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
                    'Budget Structure',
                    style: NeoTypography.sectionTitle(sheetContext),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  option(
                    structure: BudgetStructure.simple,
                    label: 'Simple',
                    description:
                        'Track spending by category. Best for straightforward budgets.',
                  ),
                  option(
                    structure: BudgetStructure.detailed,
                    label: 'Detailed',
                    description:
                        'Break categories into items for granular tracking.',
                  ),
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
      } catch (error, stackTrace) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ErrorMapper.toUserMessage(error, stackTrace: stackTrace),
              ),
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
