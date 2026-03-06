import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../widgets/common/neo_page_components.dart';
import 'settings_screen_helpers.dart';

class SettingsAboutPage extends ConsumerWidget {
  const SettingsAboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = NeoTheme.of(context);

    return Scaffold(
      backgroundColor: palette.appBg,
      appBar: AppBar(
        backgroundColor: palette.appBg,
        title: const Text('About & Legal'),
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
                SettingsTile(
                  icon: LucideIcons.info,
                  title: 'About',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    showBudgetWiseAboutDialog(context);
                  },
                ),
                const Divider(height: 1),
                SettingsTile(
                  icon: LucideIcons.shieldCheck,
                  title: 'Privacy Policy',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    launchSettingsUrl(context, AppConstants.privacyPolicyUrl);
                  },
                ),
                const Divider(height: 1),
                SettingsTile(
                  icon: LucideIcons.fileText,
                  title: 'Terms of Service',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    launchSettingsUrl(context, AppConstants.termsOfServiceUrl);
                  },
                ),
              ],
            ),
            const SizedBox(height: NeoLayout.sectionGap),
            buildSettingsCard(
              context,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        LucideIcons.clock3,
                        color: palette.accent,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Data Retention',
                              style: AppTypography.bodyLarge.copyWith(
                                color: palette.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Guest sessions may be deleted after 90 days of inactivity. Registered accounts may be deleted after 180 days of inactivity. Opening and using the app while signed in resets the timer.',
                              style: AppTypography.bodySmall.copyWith(
                                color: palette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
