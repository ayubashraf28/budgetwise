import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AnalysisMode {
  spending,
  income,
  accounts,
  trends;

  String get label {
    switch (this) {
      case AnalysisMode.spending:
        return 'Spending';
      case AnalysisMode.income:
        return 'Income';
      case AnalysisMode.accounts:
        return 'Accounts';
      case AnalysisMode.trends:
        return 'Trends';
    }
  }
}

enum AnalysisTrendMetric {
  expense,
  income,
  net;

  String get label {
    switch (this) {
      case AnalysisTrendMetric.expense:
        return 'Expense';
      case AnalysisTrendMetric.income:
        return 'Income';
      case AnalysisTrendMetric.net:
        return 'Net';
    }
  }
}

enum AnalysisTrendRange {
  oneMonth,
  threeMonths,
  sixMonths,
  twelveMonths,
  year;

  String get label {
    switch (this) {
      case AnalysisTrendRange.oneMonth:
        return '1M';
      case AnalysisTrendRange.threeMonths:
        return '3M';
      case AnalysisTrendRange.sixMonths:
        return '6M';
      case AnalysisTrendRange.twelveMonths:
        return '12M';
      case AnalysisTrendRange.year:
        return 'Year';
    }
  }

  int? get windowSize {
    switch (this) {
      case AnalysisTrendRange.oneMonth:
        return 1;
      case AnalysisTrendRange.threeMonths:
        return 3;
      case AnalysisTrendRange.sixMonths:
        return 6;
      case AnalysisTrendRange.twelveMonths:
        return 12;
      case AnalysisTrendRange.year:
        return null;
    }
  }
}

const _analysisModePrefKey = 'analysis_mode';
const _analysisMonthIdPrefKey = 'analysis_month_id';
const _analysisYearPrefKey = 'analysis_year';
const _analysisTrendMetricPrefKey = 'analysis_trend_metric';
const _analysisTrendRangePrefKey = 'analysis_trend_range';

final analysisModeProvider =
    StateNotifierProvider<AnalysisModeNotifier, AnalysisMode>((ref) {
  final notifier = AnalysisModeNotifier();
  notifier.load();
  return notifier;
});

final analysisSelectedMonthIdProvider =
    StateNotifierProvider<AnalysisSelectedMonthNotifier, String?>((ref) {
  final notifier = AnalysisSelectedMonthNotifier();
  notifier.load();
  return notifier;
});

final analysisSelectedYearProvider =
    StateNotifierProvider<AnalysisSelectedYearNotifier, int?>((ref) {
  final notifier = AnalysisSelectedYearNotifier();
  notifier.load();
  return notifier;
});

final analysisTrendMetricProvider =
    StateNotifierProvider<AnalysisTrendMetricNotifier, AnalysisTrendMetric>(
        (ref) {
  final notifier = AnalysisTrendMetricNotifier();
  notifier.load();
  return notifier;
});

final analysisTrendRangeProvider =
    StateNotifierProvider<AnalysisTrendRangeNotifier, AnalysisTrendRange>(
        (ref) {
  final notifier = AnalysisTrendRangeNotifier();
  notifier.load();
  return notifier;
});

class AnalysisModeNotifier extends StateNotifier<AnalysisMode> {
  AnalysisModeNotifier() : super(AnalysisMode.spending);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = _fromStoredValue(prefs.getString(_analysisModePrefKey));
  }

  Future<void> setMode(AnalysisMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_analysisModePrefKey, mode.name);
  }

  AnalysisMode _fromStoredValue(String? value) {
    return AnalysisMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => AnalysisMode.spending,
    );
  }
}

class AnalysisSelectedMonthNotifier extends StateNotifier<String?> {
  AnalysisSelectedMonthNotifier() : super(null);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_analysisMonthIdPrefKey);
  }

  Future<void> setMonthId(String? monthId) async {
    state = monthId;
    final prefs = await SharedPreferences.getInstance();
    if (monthId == null || monthId.isEmpty) {
      await prefs.remove(_analysisMonthIdPrefKey);
      return;
    }
    await prefs.setString(_analysisMonthIdPrefKey, monthId);
  }
}

class AnalysisTrendMetricNotifier extends StateNotifier<AnalysisTrendMetric> {
  AnalysisTrendMetricNotifier() : super(AnalysisTrendMetric.expense);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_analysisTrendMetricPrefKey);
    state = AnalysisTrendMetric.values.firstWhere(
      (metric) => metric.name == stored,
      orElse: () => AnalysisTrendMetric.expense,
    );
  }

  Future<void> setMetric(AnalysisTrendMetric metric) async {
    state = metric;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_analysisTrendMetricPrefKey, metric.name);
  }
}

class AnalysisTrendRangeNotifier extends StateNotifier<AnalysisTrendRange> {
  AnalysisTrendRangeNotifier() : super(AnalysisTrendRange.year);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_analysisTrendRangePrefKey);
    state = AnalysisTrendRange.values.firstWhere(
      (range) => range.name == stored,
      orElse: () => AnalysisTrendRange.year,
    );
  }

  Future<void> setRange(AnalysisTrendRange range) async {
    state = range;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_analysisTrendRangePrefKey, range.name);
  }
}

class AnalysisSelectedYearNotifier extends StateNotifier<int?> {
  AnalysisSelectedYearNotifier() : super(null);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt(_analysisYearPrefKey);
  }

  Future<void> setYear(int? year) async {
    state = year;
    final prefs = await SharedPreferences.getInstance();
    if (year == null) {
      await prefs.remove(_analysisYearPrefKey);
      return;
    }
    await prefs.setInt(_analysisYearPrefKey, year);
  }
}
