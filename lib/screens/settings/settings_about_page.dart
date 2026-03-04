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
          ],
        ),
      ),
    );
  }
}
