import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/month.dart';
import '../services/account_service.dart';
import '../services/category_service.dart';
import '../services/income_service.dart';
import '../services/month_service.dart';
import '../services/item_service.dart';
import '../services/subscription_service.dart';
import 'account_provider.dart';
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
/// and copies categories + income sources to the current month if empty.
/// Call this once on app startup.
final ensureMonthSetupProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return;

  final monthService = ref.read(monthServiceProvider);
  final accountService = AccountService();
  final categoryService = CategoryService();
  final incomeService = IncomeService();
  final now = DateTime.now();

  // 1. Ensure at least one active account exists.
  await accountService.ensureDefaultAccount();

  // 2. Ensure all 12 months exist for current year
  await monthService.ensureYearMonths(now.year);

  // 3. Get the current calendar month and ensure it's active
  final currentMonth = await monthService.getMonthByDate(now);
  if (currentMonth != null) {
    final activeMonth = await monthService.getActiveMonth();
    if (activeMonth == null || activeMonth.id != currentMonth.id) {
      await monthService.setActiveMonth(currentMonth.id);
    }

    // 4. Ensure current month has categories AND income sources
    await categoryService.ensureCategoriesForMonth(currentMonth.id);
    await incomeService.ensureIncomeSourcesForMonth(currentMonth.id);

    // 5. Ensure Subscriptions category and items are synced
    final subscriptionService = SubscriptionService();
    final itemService = ItemService();
    final subsCat =
        await categoryService.ensureSubscriptionsCategory(currentMonth.id);
    final activeSubs = await subscriptionService.getActiveSubscriptions();
    await itemService.repairSubscriptionItemsForCategory(
      subscriptionsCategoryId: subsCat.id,
      activeSubscriptions: activeSubs,
    );
  }

  // 6. Invalidate dependent providers to pick up new data
  ref.invalidate(activeMonthProvider);
  ref.invalidate(userMonthsProvider);
  ref.invalidate(accountsProvider);
  ref.invalidate(allAccountsProvider);
  ref.invalidate(accountBalancesProvider);
  ref.invalidate(allAccountBalancesProvider);
  ref.invalidate(netWorthProvider);
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

  /// Set a month as active (also ensures categories + income sources exist)
  Future<void> setActiveMonth(String monthId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    await _service.updateMonth(
      monthId: monthId,
      isActive: true,
    );

    // Ensure the newly active month has categories AND income sources
    final categoryService = CategoryService();
    final incomeService = IncomeService();
    await categoryService.ensureCategoriesForMonth(monthId);
    await incomeService.ensureIncomeSourcesForMonth(monthId);

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
