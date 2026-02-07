import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/month.dart';
import '../services/category_service.dart';
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

/// Ensures all 12 months exist for the current year,
/// auto-sets active month to current calendar month,
/// and copies categories to the current month if empty.
/// Call this once on app startup (e.g., in ExpensesOverviewScreen.initState).
final ensureMonthSetupProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return;

  final monthService = ref.read(monthServiceProvider);
  final categoryService = CategoryService();
  final now = DateTime.now();

  // 1. Ensure all 12 months exist for current year
  await monthService.ensureYearMonths(now.year);

  // 2. Get the current calendar month and ensure it's active
  final currentMonth = await monthService.getMonthByDate(now);
  if (currentMonth != null) {
    final activeMonth = await monthService.getActiveMonth();
    if (activeMonth == null || activeMonth.id != currentMonth.id) {
      await monthService.setActiveMonth(currentMonth.id);
    }

    // 3. Ensure current month has categories (copy from previous if empty)
    await categoryService.ensureCategoriesForMonth(currentMonth.id);
  }

  // 4. Invalidate dependent providers to pick up new data
  ref.invalidate(activeMonthProvider);
  ref.invalidate(userMonthsProvider);
});

/// Budget screen's selected month ID.
/// Independent from the global activeMonthProvider so that browsing months
/// in the budget screen doesn't affect the home / transactions screens.
/// null = not yet initialized (will be set from activeMonthProvider on first load).
final budgetSelectedMonthIdProvider = StateProvider<String?>((ref) => null);

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

  /// Set a month as active (also ensures categories exist for it)
  Future<void> setActiveMonth(String monthId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    await _service.updateMonth(
      monthId: monthId,
      isActive: true,
    );

    // Ensure the newly active month has categories
    final categoryService = CategoryService();
    await categoryService.ensureCategoriesForMonth(monthId);

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
