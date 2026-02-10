import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui_preferences_provider.dart';

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(uiPreferencesProvider.select((prefs) => prefs.themeMode));
});

Future<void> setThemeModePreference(WidgetRef ref, ThemeMode mode) async {
  await ref.read(uiPreferencesProvider.notifier).setThemeMode(mode);
}

String themeModeLabel(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.system:
      return 'System default';
    case ThemeMode.light:
      return 'Light';
    case ThemeMode.dark:
      return 'Dark';
  }
}
