import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/common/neo_modal_sheet.dart';
import '../../widgets/common/neo_page_components.dart';
import 'currency_picker_sheet.dart';
import 'settings_screen_helpers.dart';

class SettingsAccountPage extends ConsumerWidget {
  const SettingsAccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    final linkedProviders = ref.watch(linkedProvidersProvider);
    final linkedSet = linkedProviders.valueOrNull ?? <String>{};
    final hasGoogleLinked = linkedSet.contains('google');
    final hasEmailLinked = user?.email != null || linkedSet.contains('email');
    final linkedSummary = [
      if (hasEmailLinked) 'Email linked',
      if (hasGoogleLinked) 'Google linked',
      if (!hasEmailLinked && !hasGoogleLinked) 'No linked providers',
    ].join(' - ');
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final stayLoggedIn = ref.watch(stayLoggedInProvider);
    final currentCurrency = ref.watch(currencyProvider);
    final currentSymbol = ref.watch(currencySymbolProvider);
    final palette = NeoTheme.of(context);

    return Scaffold(
      backgroundColor: palette.appBg,
      appBar: AppBar(
        backgroundColor: palette.appBg,
        title: const Text('Account & Profile'),
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
                  icon: LucideIcons.user,
                  title: 'Profile',
                  subtitle:
                      profile?.displayName ?? user?.email ?? 'Not signed in',
                  onTap: () => context.push('/settings/profile'),
                ),
                const Divider(height: 1),
                SettingsTile(
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
                    showLinkedAccountsDialog(
                      context,
                      ref,
                      hasEmailLinked: hasEmailLinked,
                      hasGoogleLinked: hasGoogleLinked,
                    );
                  },
                ),
                const Divider(height: 1),
                SettingsTile(
                  icon: LucideIcons.poundSterling,
                  title: 'Currency',
                  trailing: Text(
                    '$currentSymbol $currentCurrency',
                    style: NeoTypography.rowSecondary(context),
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    showNeoModalBottomSheet<void>(
                      context: context,
                      builder: (context) => const CurrencyPickerSheet(),
                    );
                  },
                ),
                const Divider(height: 1),
                buildNotificationToggleTile(
                  context,
                  title: 'Stay Logged In',
                  subtitle: stayLoggedIn
                      ? 'Auto-logout disabled on inactivity'
                      : 'Auto-logout after 15 minutes of inactivity',
                  icon: LucideIcons.shield,
                  value: stayLoggedIn,
                  onChanged: (enabled) {
                    ref
                        .read(uiPreferencesProvider.notifier)
                        .setStayLoggedIn(enabled);
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
