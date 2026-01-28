import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/income_source.dart';
import '../services/income_service.dart';
import 'auth_provider.dart';
import 'month_provider.dart';

/// Income service provider
final incomeServiceProvider = Provider<IncomeService>((ref) {
  return IncomeService();
});

/// Income sources for the active month
final incomeSourcesProvider = FutureProvider<List<IncomeSource>>((ref) async {
  final month = ref.watch(activeMonthProvider).value;
  if (month == null) return [];

  final service = ref.read(incomeServiceProvider);
  return service.getIncomeSourcesForMonth(month.id);
});

/// Total projected income for active month
final totalProjectedIncomeProvider = Provider<double>((ref) {
  final sources = ref.watch(incomeSourcesProvider).value ?? [];
  return sources.fold<double>(0.0, (sum, s) => sum + s.projected);
});

/// Total actual income for active month
final totalActualIncomeProvider = Provider<double>((ref) {
  final sources = ref.watch(incomeSourcesProvider).value ?? [];
  return sources.fold<double>(0.0, (sum, s) => sum + s.actual);
});

/// Income difference (actual - projected)
final incomeDifferenceProvider = Provider<double>((ref) {
  final projected = ref.watch(totalProjectedIncomeProvider);
  final actual = ref.watch(totalActualIncomeProvider);
  return actual - projected;
});

/// Whether income has met projections
final incomeMetProjectionProvider = Provider<bool>((ref) {
  final projected = ref.watch(totalProjectedIncomeProvider);
  final actual = ref.watch(totalActualIncomeProvider);
  return actual >= projected;
});

/// Income notifier for mutations
class IncomeNotifier extends AsyncNotifier<List<IncomeSource>> {
  @override
  Future<List<IncomeSource>> build() async {
    final month = ref.watch(activeMonthProvider).value;
    if (month == null) return [];

    final service = ref.read(incomeServiceProvider);
    return service.getIncomeSourcesForMonth(month.id);
  }

  IncomeService get _service => ref.read(incomeServiceProvider);

  /// Add a new income source
  Future<IncomeSource> addIncomeSource({
    required String name,
    double projected = 0,
    bool isRecurring = false,
    String? notes,
  }) async {
    final user = ref.read(currentUserProvider);
    final month = ref.read(activeMonthProvider).value;
    if (user == null || month == null) throw Exception('Not ready');

    final source = await _service.createIncomeSource(
      monthId: month.id,
      name: name,
      projected: projected,
      isRecurring: isRecurring,
      notes: notes,
    );

    ref.invalidateSelf();
    ref.invalidate(incomeSourcesProvider);
    return source;
  }

  /// Update an income source
  Future<IncomeSource> updateIncomeSource({
    required String incomeSourceId,
    String? name,
    double? projected,
    double? actual,
    bool? isRecurring,
    String? notes,
  }) async {
    final source = await _service.updateIncomeSource(
      incomeSourceId: incomeSourceId,
      name: name,
      projected: projected,
      actual: actual,
      isRecurring: isRecurring,
      notes: notes,
    );

    ref.invalidateSelf();
    ref.invalidate(incomeSourcesProvider);
    return source;
  }

  /// Delete an income source
  Future<void> deleteIncomeSource(String incomeSourceId) async {
    await _service.deleteIncomeSource(incomeSourceId);

    ref.invalidateSelf();
    ref.invalidate(incomeSourcesProvider);
  }

  /// Reorder income sources
  Future<void> reorderIncomeSources(List<String> incomeSourceIds) async {
    await _service.reorderIncomeSources(incomeSourceIds);

    ref.invalidateSelf();
    ref.invalidate(incomeSourcesProvider);
  }

  /// Copy income sources from another month
  Future<List<IncomeSource>> copyFromMonth({
    required String sourceMonthId,
    bool copyProjectedAmounts = true,
  }) async {
    final month = ref.read(activeMonthProvider).value;
    if (month == null) throw Exception('No active month');

    final sources = await _service.copyIncomeSourcesFromMonth(
      sourceMonthId: sourceMonthId,
      targetMonthId: month.id,
      copyProjectedAmounts: copyProjectedAmounts,
    );

    ref.invalidateSelf();
    ref.invalidate(incomeSourcesProvider);
    return sources;
  }
}

final incomeNotifierProvider =
    AsyncNotifierProvider<IncomeNotifier, List<IncomeSource>>(
        () => IncomeNotifier());
