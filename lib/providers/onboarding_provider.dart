import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/constants.dart';
import '../models/month.dart';
import '../utils/category_name_utils.dart';
import '../utils/errors/app_error.dart';
import '../utils/errors/error_mapper.dart';
import 'auth_provider.dart';
import 'category_provider.dart';
import 'income_provider.dart';
import 'item_provider.dart';
import 'month_provider.dart';
import 'profile_provider.dart';

final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  final profileService = ref.watch(profileServiceProvider);
  return profileService.isOnboardingCompleted();
});

class OnboardingNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Month> applyTemplate(String templateId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      throw const AppError.unauthenticated();
    }

    final templateCategories = budgetTemplates[templateId];
    if (templateCategories == null) {
      throw AppError.validation(
        technicalMessage: 'Unknown onboarding template id: $templateId',
        userMessage: 'The selected template is invalid.',
      );
    }

    state = const AsyncLoading();

    try {
      final monthService = ref.read(monthServiceProvider);
      final categoryService = ref.read(categoryServiceProvider);
      final itemService = ref.read(itemServiceProvider);
      final profileService = ref.read(profileServiceProvider);

      final month = await monthService.getOrCreateCurrentMonth();
      final existingCategories =
          await categoryService.getCategoriesForMonth(month.id);

      if (existingCategories.isEmpty) {
        for (final categoryName in templateCategories) {
          if (isReservedCategoryName(categoryName)) continue;

          final categoryTemplate = defaultCategories.firstWhere(
            (category) => category['name'] == categoryName,
            orElse: () => <String, dynamic>{
              'name': categoryName,
              'icon': 'wallet',
              'color': '#6366f1',
              'items': <Map<String, dynamic>>[],
            },
          );

          final category = await categoryService.createCategory(
            monthId: month.id,
            name: categoryTemplate['name'] as String,
            icon: categoryTemplate['icon'] as String? ?? 'wallet',
            color: categoryTemplate['color'] as String? ?? '#6366f1',
          );

          final items = categoryTemplate['items'] as List<dynamic>? ?? [];
          for (final itemData in items) {
            final itemMap = itemData as Map<String, dynamic>;
            await itemService.createItem(
              categoryId: category.id,
              name: itemMap['name'] as String,
              projected: (itemMap['projected'] as num?)?.toDouble() ?? 0,
            );
          }
        }
      }

      await profileService.completeOnboarding();
      _invalidateOnboardingDependencies();
      state = const AsyncData(null);
      return month;
    } catch (error, stackTrace) {
      final mappedError = ErrorMapper.toAppError(
        error,
        stackTrace: stackTrace,
      );
      state = AsyncError(mappedError, stackTrace);
      rethrow;
    }
  }

  void _invalidateOnboardingDependencies() {
    ref.invalidate(activeMonthProvider);
    ref.invalidate(userMonthsProvider);
    ref.invalidate(categoriesProvider);
    ref.invalidate(incomeSourcesProvider);
    ref.invalidate(userProfileProvider);
    ref.invalidate(isOnboardingCompletedProvider);
    ref.invalidate(onboardingCompletedProvider);
  }
}

final onboardingNotifierProvider =
    AsyncNotifierProvider<OnboardingNotifier, void>(OnboardingNotifier.new);
