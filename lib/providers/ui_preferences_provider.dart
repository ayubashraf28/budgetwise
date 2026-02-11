import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_provider.dart';

const int _uiPreferencesSchemaVersion = 1;
const String _uiPreferencesStoragePrefix = 'ui_preferences_v1';
const String _legacyThemeModePrefKey = 'app_theme_mode';
const String _anonymousUserBucket = '__anonymous__';

enum BudgetViewMode {
  month,
  year,
}

enum AppFontSize {
  small,
  medium,
  large,
  extraLarge;

  double get scaleFactor {
    switch (this) {
      case AppFontSize.small:
        return 0.85;
      case AppFontSize.medium:
        return 1.0;
      case AppFontSize.large:
        return 1.15;
      case AppFontSize.extraLarge:
        return 1.3;
    }
  }
}

class UiSectionKeys {
  static const String homeAccounts = 'home.accounts';
  static const String homeUpcoming = 'home.upcoming';
  static const String homeRecentTransactions = 'home.recent_transactions';
  static const String manageSubscriptions = 'manage.subscriptions';
  static const String manageBudgets = 'manage.budgets';
  static const String categoriesAccounts = 'categories.accounts';
  static const String categoriesExpense = 'categories.expense';
  static const String categoriesIncome = 'categories.income';
}

const Map<String, bool> _defaultExpandedSections = <String, bool>{
  UiSectionKeys.homeAccounts: true,
  UiSectionKeys.homeUpcoming: true,
  UiSectionKeys.homeRecentTransactions: true,
  UiSectionKeys.manageSubscriptions: true,
  UiSectionKeys.manageBudgets: true,
  UiSectionKeys.categoriesAccounts: true,
  UiSectionKeys.categoriesExpense: true,
  UiSectionKeys.categoriesIncome: true,
};

@immutable
class UiPreferencesState {
  final int schemaVersion;
  final bool isLoaded;
  final ThemeMode themeMode;
  final AppFontSize appFontSize;
  final bool hideSensitiveAmounts;
  final BudgetViewMode budgetViewMode;
  final Map<String, bool> expandedSections;

  const UiPreferencesState({
    required this.schemaVersion,
    required this.isLoaded,
    required this.themeMode,
    required this.appFontSize,
    required this.hideSensitiveAmounts,
    required this.budgetViewMode,
    required this.expandedSections,
  });

  factory UiPreferencesState.initial({
    ThemeMode themeMode = ThemeMode.system,
  }) {
    return UiPreferencesState(
      schemaVersion: _uiPreferencesSchemaVersion,
      isLoaded: false,
      themeMode: themeMode,
      appFontSize: AppFontSize.medium,
      hideSensitiveAmounts: false,
      budgetViewMode: BudgetViewMode.month,
      expandedSections: Map<String, bool>.from(_defaultExpandedSections),
    );
  }

  UiPreferencesState copyWith({
    int? schemaVersion,
    bool? isLoaded,
    ThemeMode? themeMode,
    AppFontSize? appFontSize,
    bool? hideSensitiveAmounts,
    BudgetViewMode? budgetViewMode,
    Map<String, bool>? expandedSections,
  }) {
    return UiPreferencesState(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      isLoaded: isLoaded ?? this.isLoaded,
      themeMode: themeMode ?? this.themeMode,
      appFontSize: appFontSize ?? this.appFontSize,
      hideSensitiveAmounts: hideSensitiveAmounts ?? this.hideSensitiveAmounts,
      budgetViewMode: budgetViewMode ?? this.budgetViewMode,
      expandedSections: expandedSections ?? this.expandedSections,
    );
  }

  bool sectionExpanded(String sectionKey) {
    return expandedSections[sectionKey] ??
        _defaultExpandedSections[sectionKey] ??
        true;
  }

  Map<String, dynamic> toJson() {
    final persistedSections = <String, bool>{};
    for (final key in _defaultExpandedSections.keys) {
      persistedSections[key] = sectionExpanded(key);
    }

    return <String, dynamic>{
      'version': _uiPreferencesSchemaVersion,
      'themeMode': _themeModeToStoredValue(themeMode),
      'appFontSize': _appFontSizeToStoredValue(appFontSize),
      'hideSensitiveAmounts': hideSensitiveAmounts,
      'budgetViewMode': _budgetViewModeToStoredValue(budgetViewMode),
      'expandedSections': persistedSections,
    };
  }

  static UiPreferencesState fromJson(
    Map<String, dynamic> json, {
    required ThemeMode fallbackThemeMode,
  }) {
    final sections = Map<String, bool>.from(_defaultExpandedSections);
    final dynamic rawSections = json['expandedSections'];
    if (rawSections is Map) {
      for (final entry in rawSections.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (_defaultExpandedSections.containsKey(key) && value is bool) {
          sections[key] = value;
        }
      }
    }

    final dynamic versionValue = json['version'];
    final int version =
        versionValue is int ? versionValue : _uiPreferencesSchemaVersion;

    return UiPreferencesState(
      schemaVersion: version,
      isLoaded: false,
      themeMode: _themeModeFromStoredValue(json['themeMode'] as String?) ??
          fallbackThemeMode,
      appFontSize:
          _appFontSizeFromStoredValue(json['appFontSize'] as String?) ??
              AppFontSize.medium,
      hideSensitiveAmounts: json['hideSensitiveAmounts'] as bool? ?? false,
      budgetViewMode:
          _budgetViewModeFromStoredValue(json['budgetViewMode'] as String?) ??
              BudgetViewMode.month,
      expandedSections: sections,
    );
  }
}

final uiPreferencesProvider =
    StateNotifierProvider<UiPreferencesNotifier, UiPreferencesState>((ref) {
  final notifier = UiPreferencesNotifier(ref);
  ref.listen(currentUserProvider, (previous, next) {
    notifier.onUserChanged(previous?.id, next?.id);
  });
  notifier.loadForCurrentUser();
  return notifier;
});

final hideSensitiveAmountsProvider = Provider<bool>((ref) {
  final prefs = ref.watch(uiPreferencesProvider);
  // Avoid leaking visible amounts before the persisted preference is loaded.
  if (!prefs.isLoaded) return true;
  return prefs.hideSensitiveAmounts;
});

final uiSectionExpandedProvider = Provider.family<bool, String>((ref, section) {
  return ref.watch(
    uiPreferencesProvider.select((prefs) => prefs.sectionExpanded(section)),
  );
});

final budgetViewModeProvider = Provider<BudgetViewMode>((ref) {
  return ref
      .watch(uiPreferencesProvider.select((prefs) => prefs.budgetViewMode));
});

final appFontSizeProvider = Provider<AppFontSize>((ref) {
  return ref.watch(uiPreferencesProvider.select((prefs) => prefs.appFontSize));
});

final budgetYearViewEnabledProvider = Provider<bool>((ref) {
  return ref.watch(budgetViewModeProvider) == BudgetViewMode.year;
});

class UiPreferencesNotifier extends StateNotifier<UiPreferencesState> {
  final Ref _ref;
  int _loadSequence = 0;
  String? _currentUserId;
  Future<void> _persistQueue = Future<void>.value();

  UiPreferencesNotifier(this._ref) : super(UiPreferencesState.initial());

  void loadForCurrentUser() {
    _loadForUser(_ref.read(currentUserProvider)?.id);
  }

  void onUserChanged(String? previousUserId, String? nextUserId) {
    if (previousUserId == nextUserId) return;
    _loadForUser(nextUserId);
  }

  Future<void> setThemeMode(ThemeMode mode) {
    if (state.themeMode == mode) return Future<void>.value();
    return _updateAndPersist(state.copyWith(themeMode: mode));
  }

  Future<void> setHideSensitiveAmounts(bool hidden) {
    if (state.hideSensitiveAmounts == hidden) return Future<void>.value();
    return _updateAndPersist(state.copyWith(hideSensitiveAmounts: hidden));
  }

  Future<void> setSectionExpanded(String sectionKey, bool expanded) {
    if (!_defaultExpandedSections.containsKey(sectionKey)) {
      return Future<void>.value();
    }
    if (state.sectionExpanded(sectionKey) == expanded) {
      return Future<void>.value();
    }
    final updated = Map<String, bool>.from(state.expandedSections)
      ..[sectionKey] = expanded;
    return _updateAndPersist(state.copyWith(expandedSections: updated));
  }

  Future<void> setBudgetViewMode(BudgetViewMode mode) {
    if (state.budgetViewMode == mode) return Future<void>.value();
    return _updateAndPersist(state.copyWith(budgetViewMode: mode));
  }

  Future<void> setAppFontSize(AppFontSize size) {
    if (state.appFontSize == size) return Future<void>.value();
    return _updateAndPersist(state.copyWith(appFontSize: size));
  }

  Future<void> _loadForUser(String? userId) async {
    final loadSequence = ++_loadSequence;
    _currentUserId = userId;

    final prefs = await SharedPreferences.getInstance();
    final fallbackThemeMode =
        _themeModeFromStoredValue(prefs.getString(_legacyThemeModePrefKey)) ??
            ThemeMode.system;

    UiPreferencesState next = UiPreferencesState.initial(
      themeMode: fallbackThemeMode,
    ).copyWith(
      isLoaded: true,
    );

    final rawJson = prefs.getString(_storageKeyForUser(userId));
    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawJson);
        if (decoded is Map<String, dynamic>) {
          next = UiPreferencesState.fromJson(
            decoded,
            fallbackThemeMode: fallbackThemeMode,
          ).copyWith(
            isLoaded: true,
          );
        }
      } catch (_) {
        // Keep defaults if parsing fails.
      }
    }

    if (loadSequence != _loadSequence) return;
    state = next;
  }

  Future<void> _updateAndPersist(UiPreferencesState next) async {
    state = next;
    await _persistState(next, _currentUserId);
  }

  Future<void> _persistState(UiPreferencesState snapshot, String? userId) {
    final payload = jsonEncode(snapshot.toJson());
    final storageKey = _storageKeyForUser(userId);
    _persistQueue = _persistQueue.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(storageKey, payload);
        await prefs.setString(
          _legacyThemeModePrefKey,
          _themeModeToStoredValue(snapshot.themeMode),
        );
      } catch (_) {
        // Keep in-memory state even if local persistence temporarily fails.
      }
    });
    return _persistQueue;
  }
}

String _storageKeyForUser(String? userId) {
  final bucket =
      (userId == null || userId.isEmpty) ? _anonymousUserBucket : userId;
  return '$_uiPreferencesStoragePrefix::$bucket';
}

ThemeMode? _themeModeFromStoredValue(String? value) {
  switch (value) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    case 'system':
      return ThemeMode.system;
    default:
      return null;
  }
}

String _themeModeToStoredValue(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'light';
    case ThemeMode.dark:
      return 'dark';
    case ThemeMode.system:
      return 'system';
  }
}

BudgetViewMode? _budgetViewModeFromStoredValue(String? value) {
  switch (value) {
    case 'month':
      return BudgetViewMode.month;
    case 'year':
      return BudgetViewMode.year;
    default:
      return null;
  }
}

String _budgetViewModeToStoredValue(BudgetViewMode mode) {
  switch (mode) {
    case BudgetViewMode.month:
      return 'month';
    case BudgetViewMode.year:
      return 'year';
  }
}

AppFontSize? _appFontSizeFromStoredValue(String? value) {
  switch (value) {
    case 'small':
      return AppFontSize.small;
    case 'medium':
      return AppFontSize.medium;
    case 'large':
      return AppFontSize.large;
    case 'extra_large':
      return AppFontSize.extraLarge;
    default:
      return null;
  }
}

String _appFontSizeToStoredValue(AppFontSize size) {
  switch (size) {
    case AppFontSize.small:
      return 'small';
    case AppFontSize.medium:
      return 'medium';
    case AppFontSize.large:
      return 'large';
    case AppFontSize.extraLarge:
      return 'extra_large';
  }
}

String appFontSizeLabel(AppFontSize size) {
  switch (size) {
    case AppFontSize.small:
      return 'Small';
    case AppFontSize.medium:
      return 'Medium';
    case AppFontSize.large:
      return 'Large';
    case AppFontSize.extraLarge:
      return 'Extra Large';
  }
}
