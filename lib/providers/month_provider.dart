import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/month.dart';
import '../services/month_service.dart';
import 'auth_provider.dart';

/// Month service provider
final monthServiceProvider = Provider<MonthService>((ref) {
  return MonthService();
});

/// Active month for the current user
final activeMonthProvider = FutureProvider<Month?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final service = ref.read(monthServiceProvider);
  return service.getActiveMonth();
});

/// All months for the current user
final userMonthsProvider = FutureProvider<List<Month>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final service = ref.read(monthServiceProvider);
  return service.getAllMonths();
});

/// Month notifier for mutations
class MonthNotifier extends AsyncNotifier<Month?> {
  @override
  Future<Month?> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return null;

    final service = ref.read(monthServiceProvider);
    return service.getActiveMonth();
  }

  MonthService get _service => ref.read(monthServiceProvider);

  /// Create a new month
  Future<Month> createMonth({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw Exception('Not authenticated');

    final month = await _service.createMonth(
      name: name,
      startDate: startDate,
      endDate: endDate,
      notes: notes,
    );

    ref.invalidateSelf();
    ref.invalidate(userMonthsProvider);
    return month;
  }

  /// Get or create the current calendar month
  Future<Month> getOrCreateCurrentMonth() async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw Exception('Not authenticated');

    final month = await _service.createCurrentMonth();

    ref.invalidateSelf();
    ref.invalidate(userMonthsProvider);
    return month;
  }

  /// Set a month as active
  Future<void> setActiveMonth(String monthId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    await _service.updateMonth(
      monthId: monthId,
      isActive: true,
    );

    ref.invalidateSelf();
    ref.invalidate(userMonthsProvider);
  }

  /// Update a month
  Future<Month> updateMonth({
    required String monthId,
    String? name,
    String? notes,
    bool? isActive,
  }) async {
    final month = await _service.updateMonth(
      monthId: monthId,
      name: name,
      notes: notes,
      isActive: isActive,
    );

    ref.invalidateSelf();
    ref.invalidate(userMonthsProvider);
    return month;
  }

  /// Delete a month
  Future<void> deleteMonth(String monthId) async {
    await _service.deleteMonth(monthId);

    ref.invalidateSelf();
    ref.invalidate(userMonthsProvider);
  }
}

final monthNotifierProvider =
    AsyncNotifierProvider<MonthNotifier, Month?>(() => MonthNotifier());
