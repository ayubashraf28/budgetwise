import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../widgets/common/neo_page_components.dart';
import 'settings_screen_helpers.dart';

class SettingsSupportPage extends ConsumerWidget {
  const SettingsSupportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = NeoTheme.of(context);

    return Scaffold(
      backgroundColor: palette.appBg,
      appBar: AppBar(
        backgroundColor: palette.appBg,
        title: const Text('Help & Support'),
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
                  icon: LucideIcons.bug,
                  title: 'Report a Bug',
                  subtitle: 'Share an issue with app and device details',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    showBugReportSheet(context);
                  },
                ),
                const Divider(height: 1),
                SettingsTile(
                  icon: LucideIcons.messageSquare,
                  title: 'Send Feedback',
                  subtitle: 'Share suggestions and product feedback',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    showFeedbackSheet(context);
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
