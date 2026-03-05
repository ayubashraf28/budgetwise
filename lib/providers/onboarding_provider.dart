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

  Future<Month> applySelectedCategories(List<String> categoryNames) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      throw const AppError.unauthenticated();
    }

    final selectedCategoryTemplates = _resolveSelectedCategoryTemplates(
      categoryNames,
    );
    if (selectedCategoryTemplates.isEmpty) {
      throw const AppError.validation(
        technicalMessage: 'No onboarding categories were selected.',
        userMessage: 'Select at least one category to continue.',
      );
    }

    state = const AsyncLoading();

    try {
      final monthService = ref.read(monthServiceProvider);
      final categoryService = ref.read(categoryServiceProvider);
      final itemService = ref.read(itemServiceProvider);

      final month = await monthService.getOrCreateCurrentMonth();
      final existingCategories =
          await categoryService.getCategoriesForMonth(month.id);
      final existingCategoryNames = existingCategories
          .map((category) => category.name.trim().toLowerCase())
          .toSet();

      for (final categoryTemplate in selectedCategoryTemplates) {
        final categoryName = categoryTemplate['name'] as String;
        if (isReservedCategoryName(categoryName) ||
            existingCategoryNames.contains(categoryName.trim().toLowerCase())) {
          continue;
        }

        final category = await categoryService.createCategory(
          monthId: month.id,
          name: categoryName,
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

  List<Map<String, dynamic>> _resolveSelectedCategoryTemplates(
    List<String> categoryNames,
  ) {
    final availableTemplates = <String, Map<String, dynamic>>{
      for (final category in defaultCategories)
        (category['name'] as String).trim().toLowerCase(): category,
    };

    final selectedTemplates = <Map<String, dynamic>>[];
    final unknownCategoryNames = <String>[];
    final seenCategoryNames = <String>{};

    for (final rawName in categoryNames) {
      final normalizedName = rawName.trim().toLowerCase();
      if (normalizedName.isEmpty || !seenCategoryNames.add(normalizedName)) {
        continue;
      }

      final categoryTemplate = availableTemplates[normalizedName];
      if (categoryTemplate == null) {
        unknownCategoryNames.add(rawName.trim());
        continue;
      }

      selectedTemplates.add(categoryTemplate);
    }

    if (unknownCategoryNames.isNotEmpty) {
      throw AppError.validation(
        technicalMessage:
            'Unknown onboarding categories: ${unknownCategoryNames.join(', ')}',
        userMessage: 'One or more selected categories are invalid.',
      );
    }

    return selectedTemplates;
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

  Future<void> completeOnboarding() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      throw const AppError.unauthenticated();
    }

    state = const AsyncLoading();

    try {
      final profileService = ref.read(profileServiceProvider);
      await profileService.completeOnboarding();
      _invalidateOnboardingDependencies();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      final mappedError = ErrorMapper.toAppError(
        error,
        stackTrace: stackTrace,
      );
      state = AsyncError(mappedError, stackTrace);
      rethrow;
    }
  }
}

final onboardingNotifierProvider =
    AsyncNotifierProvider<OnboardingNotifier, void>(OnboardingNotifier.new);
