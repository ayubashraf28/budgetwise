import 'package:budgetwise/providers/ui_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UiPreferencesState defaults budget structure to detailed', () {
    final state = UiPreferencesState.initial();
    expect(state.budgetStructure, BudgetStructure.detailed);
  });

  test('UiPreferencesState JSON round-trip preserves budget structure', () {
    final original = UiPreferencesState.initial().copyWith(
      budgetStructure: BudgetStructure.simple,
      isLoaded: true,
    );

    final restored = UiPreferencesState.fromJson(
      original.toJson(),
      fallbackThemeMode: ThemeMode.system,
    );

    expect(restored.budgetStructure, BudgetStructure.simple);
  });
}
