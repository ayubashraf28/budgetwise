import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/bug_report.dart';
import '../../providers/providers.dart';
import '../../utils/errors/error_mapper.dart';
import '../../widgets/common/neo_modal_sheet.dart';
import '../../widgets/common/neo_page_components.dart';
import '../../widgets/common/neo_snackbar.dart';
import '../../widgets/motion/neo_pressable.dart';
import 'bug_report_form_sheet.dart';

Widget buildSettingsSectionHeader(BuildContext context, String title) {
  return Text(
    title,
    style: NeoTypography.sectionAction(context).copyWith(
      color: NeoTheme.of(context).textMuted,
    ),
  );
}

Widget buildSettingsCard(
  BuildContext context, {
  required List<Widget> children,
}) {
  return NeoGlassCard(
    padding: EdgeInsets.zero,
    child: Column(children: children),
  );
}

Widget buildNotificationToggleTile(
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

void showBugReportSheet(BuildContext context) {
  showNeoModalBottomSheet<void>(
    context: context,
    builder: (context) => const BugReportFormSheet(),
  );
}

void showFeedbackSheet(BuildContext context) {
  showNeoModalBottomSheet<void>(
    context: context,
    builder: (context) => const BugReportFormSheet(
      feedbackMode: true,
      initialCategory: BugReportCategory.feedback,
    ),
  );
}

Future<void> updateNotificationPreferences(
  BuildContext context,
  WidgetRef ref, {
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
        if (!context.mounted) return;
        if (!granted) {
          await ref.read(profileNotifierProvider.notifier).updateProfile(
                notificationsEnabled: false,
                subscriptionRemindersEnabled: false,
                budgetAlertsEnabled: false,
                monthlyRemindersEnabled: false,
              );
          ref.invalidate(userProfileProvider);
          if (!context.mounted) return;
          showNeoSnackBar(
            context,
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
    if (!context.mounted) return;
    showNeoErrorSnackBar(
      context,
      ErrorMapper.toUserMessage(error, stackTrace: stackTrace),
    );
  }
}

Future<void> showLinkedAccountsDialog(
  BuildContext context,
  WidgetRef ref, {
  required bool hasEmailLinked,
  required bool hasGoogleLinked,
}) async {
  final palette = NeoTheme.of(context);
  var isLinkingGoogle = false;

  Widget linkedProviderRow({
    required BuildContext rowContext,
    required String provider,
    required bool linked,
  }) {
    return Row(
      children: [
        Icon(
          linked ? LucideIcons.checkCircle2 : LucideIcons.circle,
          size: NeoIconSizes.lg,
          color:
              linked ? NeoTheme.positiveValue(rowContext) : palette.textMuted,
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
            color:
                linked ? NeoTheme.positiveValue(rowContext) : palette.textMuted,
          ),
        ),
      ],
    );
  }

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
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
            linkedProviderRow(
                rowContext: dialogContext,
                provider: 'Email',
                linked: hasEmailLinked),
            const SizedBox(height: AppSpacing.sm),
            linkedProviderRow(
                rowContext: dialogContext,
                provider: 'Google',
                linked: hasGoogleLinked),
            if (!hasGoogleLinked) ...[
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLinkingGoogle
                      ? null
                      : () async {
                          setDialogState(() => isLinkingGoogle = true);
                          try {
                            await ref
                                .read(authNotifierProvider.notifier)
                                .linkGoogleAccount();
                            ref.invalidate(linkedProvidersProvider);
                            if (!context.mounted) return;
                            showNeoSuccessSnackBar(
                              context,
                              'Google account linked successfully',
                            );
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                          } catch (error, stackTrace) {
                            if (!context.mounted) return;
                            showNeoErrorSnackBar(
                              context,
                              ErrorMapper.toUserMessage(
                                error,
                                stackTrace: stackTrace,
                                fallbackMessage:
                                    'Unable to link Google account right now.',
                              ),
                            );
                          } finally {
                            if (dialogContext.mounted) {
                              setDialogState(() => isLinkingGoogle = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.accent,
                    foregroundColor: NeoTheme.isLight(dialogContext)
                        ? palette.textPrimary
                        : palette.surface1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                    ),
                  ),
                  child: isLinkingGoogle
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
    ),
  );
}

Future<void> launchSettingsUrl(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (!context.mounted) return;
    showNeoErrorSnackBar(context, 'Could not open link');
  }
}

void showBudgetWiseAboutDialog(BuildContext context) {
  final palette = NeoTheme.of(context);
  showDialog<void>(
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
            style: AppTypography.bodyLarge.copyWith(color: palette.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Plan your spending, track your expenses, and build better financial habits.',
            style:
                AppTypography.bodyMedium.copyWith(color: palette.textSecondary),
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

void showThemeModeSheet(
  BuildContext context,
  WidgetRef ref,
  ThemeMode currentMode,
) {
  showNeoModalBottomSheet<void>(
    context: context,
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

void showTextSizeSheet(
  BuildContext context,
  WidgetRef ref,
  AppFontSize currentSize,
) {
  showNeoModalBottomSheet<void>(
    context: context,
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

void showBudgetStructureSheet(
  BuildContext context,
  WidgetRef ref,
  BudgetStructure currentStructure,
) {
  showNeoModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      final palette = NeoTheme.of(sheetContext);

      Future<void> setStructure(BudgetStructure structure) async {
        await ref.read(uiPreferencesProvider.notifier).setBudgetStructure(
              structure,
            );
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

Future<void> handleSettingsSignOut(
  BuildContext context,
  WidgetRef ref,
) async {
  HapticFeedback.mediumImpact();
  final palette = NeoTheme.of(context);

  // Anonymous guest-session warning
  final isAnonymous = ref.read(isAnonymousProvider);
  if (isAnonymous) {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: palette.surface1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
          side: BorderSide(color: palette.stroke),
        ),
        title: Text(
          'Sign out of guest session?',
          style: AppTypography.h3.copyWith(color: palette.textPrimary),
        ),
        content: Text(
          'Your guest data stays stored for now, but signing out may make this session unrecoverable unless you create an account first. Inactive guest accounts may be deleted after 90 days.',
          style: AppTypography.bodyMedium.copyWith(
            color: palette.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: palette.accent),
            child: const Text('Create Account'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(foregroundColor: palette.textPrimary),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;

    if (result == true) {
      context.push('/register');
      return;
    }
    if (result == null) {
      return;
    }
    // result == false: proceed to sign out below
  }

  final confirmed = isAnonymous ||
      await showDialog<bool>(
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
                style: AppTypography.bodyLarge
                    .copyWith(color: palette.textSecondary),
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
          ) ==
          true;

  if (confirmed && context.mounted) {
    try {
      await ref.read(authNotifierProvider.notifier).signOut();
    } catch (error, stackTrace) {
      if (!context.mounted) return;
      showNeoErrorSnackBar(
        context,
        ErrorMapper.toUserMessage(error, stackTrace: stackTrace),
      );
    }
  }
}

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.titleColor,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? titleColor;
  final bool showChevron;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);

    return NeoPressable(
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
    );
  }
}

class SettingsGroupTile extends StatelessWidget {
  const SettingsGroupTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
    );
  }
}
