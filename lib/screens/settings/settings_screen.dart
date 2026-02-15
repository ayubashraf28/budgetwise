import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/bug_report.dart';
import '../../providers/providers.dart';
import '../../utils/errors/error_mapper.dart';
import '../../widgets/common/neo_page_components.dart';
import 'bug_report_form_sheet.dart';
import 'currency_picker_sheet.dart';

part 'settings_screen_helpers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLinkingGoogle = false;
  bool _isDeletingAllData = false;

  void _setIsLinkingGoogle(bool value) {
    if (!mounted) {
      _isLinkingGoogle = value;
      return;
    }
    setState(() => _isLinkingGoogle = value);
  }

  void _setIsDeletingAllData(bool value) {
    if (!mounted) {
      _isDeletingAllData = value;
      return;
    }
    setState(() => _isDeletingAllData = value);
  }

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    final linkedProviders = ref.watch(linkedProvidersProvider);
    final linkedSet = linkedProviders.valueOrNull ?? <String>{};
    final hasGoogleLinked = linkedSet.contains('google');
    final hasEmailLinked = user?.email != null || linkedSet.contains('email');
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final notificationsEnabled = profile?.notificationsEnabled ?? true;
    final subscriptionRemindersEnabled =
        profile?.subscriptionRemindersEnabled ?? true;
    final budgetAlertsEnabled = profile?.budgetAlertsEnabled ?? true;
    final monthlyRemindersEnabled = profile?.monthlyRemindersEnabled ?? true;
    final linkedSummary = [
      if (hasEmailLinked) 'Email linked',
      if (hasGoogleLinked) 'Google linked',
      if (!hasEmailLinked && !hasGoogleLinked) 'No linked providers',
    ].join(' - ');
    final currentCurrency = ref.watch(currencyProvider);
    final currentSymbol = ref.watch(currencySymbolProvider);
    final currentThemeMode = ref.watch(themeModeProvider);
    final currentAppFontSize = ref.watch(appFontSizeProvider);
    final currentBudgetStructure = ref.watch(budgetStructureProvider);

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
                      profile?.displayName ?? user?.email ?? 'Not signed in',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.push('/settings/profile');
                  },
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: LucideIcons.link2,
                  title: 'Linked Accounts',
                  subtitle: linkedSummary,
                  trailing: linkedProviders.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : hasGoogleLinked
                          ? Icon(
                              LucideIcons.checkCircle2,
                              size: NeoIconSizes.lg,
                              color: NeoTheme.positiveValue(context),
                            )
                          : null,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _showLinkedAccountsDialog(
                      context,
                      hasEmailLinked: hasEmailLinked,
                      hasGoogleLinked: hasGoogleLinked,
                    );
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
                _SettingsTile(
                  icon: LucideIcons.layers,
                  title: 'Budget Structure',
                  trailing: Text(
                    currentBudgetStructure == BudgetStructure.simple
                        ? 'Simple'
                        : 'Detailed',
                    style: NeoTypography.rowSecondary(context),
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _showBudgetStructureSheet(
                      context,
                      ref,
                      currentBudgetStructure,
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
            _buildSectionHeader(context, 'Notifications'),
            const SizedBox(height: AppSpacing.sm),
            _buildSettingsCard(
              context,
              children: [
                _buildNotificationToggleTile(
                  context,
                  title: 'Enable Notifications',
                  subtitle: 'Master switch for all reminders and alerts',
                  icon: LucideIcons.bell,
                  value: notificationsEnabled,
                  onChanged: (enabled) =>
                      _updateNotificationPreferences(masterEnabled: enabled),
                ),
                const Divider(height: 1),
                _buildNotificationToggleTile(
                  context,
                  title: 'Subscription Reminders',
                  subtitle: 'Upcoming recurring payment alerts',
                  icon: LucideIcons.repeat,
                  value: notificationsEnabled && subscriptionRemindersEnabled,
                  enabled: notificationsEnabled,
                  onChanged: (enabled) => _updateNotificationPreferences(
                    subscriptionRemindersEnabled: enabled,
                  ),
                ),
                const Divider(height: 1),
                _buildNotificationToggleTile(
                  context,
                  title: 'Budget Alerts',
                  subtitle: 'Alerts when category spend exceeds budget',
                  icon: LucideIcons.alertTriangle,
                  value: notificationsEnabled && budgetAlertsEnabled,
                  enabled: notificationsEnabled,
                  onChanged: (enabled) => _updateNotificationPreferences(
                    budgetAlertsEnabled: enabled,
                  ),
                ),
                const Divider(height: 1),
                _buildNotificationToggleTile(
                  context,
                  title: 'Monthly Reminder',
                  subtitle: 'Nudge at the start of a new month',
                  icon: LucideIcons.calendar,
                  value: notificationsEnabled && monthlyRemindersEnabled,
                  enabled: notificationsEnabled,
                  onChanged: (enabled) => _updateNotificationPreferences(
                    monthlyRemindersEnabled: enabled,
                  ),
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
            _buildSectionHeader(context, 'Help & Support'),
            const SizedBox(height: AppSpacing.sm),
            _buildSettingsCard(
              context,
              children: [
                _SettingsTile(
                  icon: LucideIcons.bug,
                  title: 'Report a Bug',
                  subtitle: 'Share an issue with app and device details',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _showBugReportSheet(context);
                  },
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: LucideIcons.messageSquare,
                  title: 'Send Feedback',
                  subtitle: 'Share suggestions and product feedback',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _showFeedbackSheet(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: NeoLayout.sectionGap),
            _buildSectionHeader(context, 'Danger Zone'),
            const SizedBox(height: AppSpacing.sm),
            _buildSettingsCard(
              context,
              children: [
                _SettingsTile(
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
}
