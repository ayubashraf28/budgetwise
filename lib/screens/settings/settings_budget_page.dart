import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/common/neo_page_components.dart';
import 'settings_screen_helpers.dart';

class SettingsBudgetPage extends ConsumerWidget {
  const SettingsBudgetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentBudgetStructure = ref.watch(budgetStructureProvider);
    final palette = NeoTheme.of(context);

    return Scaffold(
      backgroundColor: palette.appBg,
      appBar: AppBar(
        backgroundColor: palette.appBg,
        title: const Text('Budget'),
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
                    showBudgetStructureSheet(
                      context,
                      ref,
                      currentBudgetStructure,
                    );
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
