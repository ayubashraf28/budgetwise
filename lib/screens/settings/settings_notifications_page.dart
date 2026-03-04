import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/common/neo_page_components.dart';
import 'settings_screen_helpers.dart';

class SettingsNotificationsPage extends ConsumerWidget {
  const SettingsNotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = NeoTheme.of(context);
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final notificationsEnabled = profile?.notificationsEnabled ?? true;
    final subscriptionRemindersEnabled =
        profile?.subscriptionRemindersEnabled ?? true;
    final budgetAlertsEnabled = profile?.budgetAlertsEnabled ?? true;
    final monthlyRemindersEnabled = profile?.monthlyRemindersEnabled ?? true;

    return Scaffold(
      backgroundColor: palette.appBg,
      appBar: AppBar(
        backgroundColor: palette.appBg,
        title: const Text('Notifications'),
      ),
      body: NeoPageBackground(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            NeoLayout.screenPadding,
            AppSpacing.md,
            NeoLayout.screenPadding,
            AppSpacing.xl +
                MediaQuery.paddingOf(context).bottom +
                NeoLayout.bottomNavSafeBuffer,
          ),
          children: [
            buildSettingsCard(
              context,
              children: [
                buildNotificationToggleTile(
                  context,
                  title: 'Enable Notifications',
                  subtitle: 'Master switch for all reminders and alerts',
                  icon: LucideIcons.bell,
                  value: notificationsEnabled,
                  onChanged: (enabled) => updateNotificationPreferences(
                    context,
                    ref,
                    masterEnabled: enabled,
                  ),
                ),
                const Divider(height: 1),
                buildNotificationToggleTile(
                  context,
                  title: 'Subscription Reminders',
                  subtitle: 'Upcoming recurring payment alerts',
                  icon: LucideIcons.repeat,
                  value:
                      notificationsEnabled && subscriptionRemindersEnabled,
                  enabled: notificationsEnabled,
                  onChanged: (enabled) => updateNotificationPreferences(
                    context,
                    ref,
                    subscriptionRemindersEnabled: enabled,
                  ),
                ),
                const Divider(height: 1),
                buildNotificationToggleTile(
                  context,
                  title: 'Budget Alerts',
                  subtitle: 'Alerts when category spend exceeds budget',
                  icon: LucideIcons.alertTriangle,
                  value: notificationsEnabled && budgetAlertsEnabled,
                  enabled: notificationsEnabled,
                  onChanged: (enabled) => updateNotificationPreferences(
                    context,
                    ref,
                    budgetAlertsEnabled: enabled,
                  ),
                ),
                const Divider(height: 1),
                buildNotificationToggleTile(
                  context,
                  title: 'Monthly Reminder',
                  subtitle: 'Nudge at the start of a new month',
                  icon: LucideIcons.calendar,
                  value: notificationsEnabled && monthlyRemindersEnabled,
                  enabled: notificationsEnabled,
                  onChanged: (enabled) => updateNotificationPreferences(
                    context,
                    ref,
                    monthlyRemindersEnabled: enabled,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
