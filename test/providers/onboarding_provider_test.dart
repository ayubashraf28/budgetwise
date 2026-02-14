import 'package:budgetwise/models/category.dart';
import 'package:budgetwise/models/item.dart';
import 'package:budgetwise/models/month.dart';
import 'package:budgetwise/models/user_profile.dart';
import 'package:budgetwise/providers/auth_provider.dart';
import 'package:budgetwise/providers/category_provider.dart';
import 'package:budgetwise/providers/item_provider.dart';
import 'package:budgetwise/providers/month_provider.dart';
import 'package:budgetwise/providers/onboarding_provider.dart';
import 'package:budgetwise/providers/profile_provider.dart';
import 'package:budgetwise/services/category_service.dart';
import 'package:budgetwise/services/item_service.dart';
import 'package:budgetwise/services/month_service.dart';
import 'package:budgetwise/services/profile_service.dart';
import 'package:budgetwise/utils/category_name_utils.dart';
import 'package:budgetwise/utils/errors/app_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    try {
      await Supabase.initialize(
        url: 'https://example.supabase.co',
        anonKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIn0.c2lnbmF0dXJl',
      );
    } catch (_) {
      // Already initialized in another test run.
    }
  });

  test('onboardingCompletedProvider returns false when user is not signed in',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final result = await container.read(onboardingCompletedProvider.future);
    expect(result, isFalse);
  });

  test('applyTemplate throws unauthenticated when no current user', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(onboardingNotifierProvider.notifier);

    await expectLater(
      () => notifier.applyTemplate('individual'),
      throwsA(
        isA<AppError>().having(
          (error) => error.code,
          'code',
          AppErrorCode.unauthenticated,
        ),
      ),
    );
  });

  test('applyTemplate creates categories and completes onboarding', () async {
    final month = _fakeMonth();
    final monthService = _FakeMonthService(month);
    final categoryService = _FakeCategoryService(existingCategories: []);
    final itemService = _FakeItemService();
    final profileService = _FakeProfileService();

    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith((ref) => _fakeUser()),
        monthServiceProvider.overrideWithValue(monthService),
        categoryServiceProvider.overrideWithValue(categoryService),
        itemServiceProvider.overrideWithValue(itemService),
        profileServiceProvider.overrideWithValue(profileService),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(onboardingNotifierProvider.notifier);
    final result = await notifier.applyTemplate('individual');

    expect(result.id, month.id);
    expect(monthService.getOrCreateCalls, 1);
    expect(categoryService.createdNames, isNotEmpty);
    expect(
      categoryService.createdNames.any(isReservedCategoryName),
      isFalse,
    );
    expect(profileService.completeCalls, 1);
  });

  test('applyTemplate is idempotent when categories already exist', () async {
    final month = _fakeMonth();
    final existingCategory = Category(
      id: 'existing-cat',
      userId: 'user-1',
      monthId: month.id,
      name: 'Housing',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      items: const [],
    );
    final monthService = _FakeMonthService(month);
    final categoryService = _FakeCategoryService(
      existingCategories: [existingCategory],
    );
    final itemService = _FakeItemService();
    final profileService = _FakeProfileService();

    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith((ref) => _fakeUser()),
        monthServiceProvider.overrideWithValue(monthService),
        categoryServiceProvider.overrideWithValue(categoryService),
        itemServiceProvider.overrideWithValue(itemService),
        profileServiceProvider.overrideWithValue(profileService),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(onboardingNotifierProvider.notifier);
    final result = await notifier.applyTemplate('individual');

    expect(result.id, month.id);
    expect(monthService.getOrCreateCalls, 1);
    expect(categoryService.createdNames, isEmpty);
    expect(itemService.createdItems, isEmpty);
    expect(profileService.completeCalls, 1);
  });
}

User _fakeUser() {
  return User.fromJson({
    'id': 'user-1',
    'aud': 'authenticated',
    'role': 'authenticated',
    'email': 'user@example.com',
    'created_at': DateTime.utc(2026, 1, 1).toIso8601String(),
    'app_metadata': <String, dynamic>{},
    'user_metadata': <String, dynamic>{},
  })!;
}

Month _fakeMonth() {
  return Month(
    id: 'month-1',
    userId: 'user-1',
    name: 'January 2026',
    startDate: DateTime.utc(2026, 1, 1),
    endDate: DateTime.utc(2026, 1, 31),
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
}

class _FakeMonthService extends MonthService {
  _FakeMonthService(this._month);

  final Month _month;
  int getOrCreateCalls = 0;

  @override
  Future<Month> getOrCreateCurrentMonth() async {
    getOrCreateCalls += 1;
    return _month;
  }
}

class _FakeCategoryService extends CategoryService {
  _FakeCategoryService({required this.existingCategories});

  final List<Category> existingCategories;
  final List<String> createdNames = <String>[];
  int _createdCount = 0;

  @override
  Future<List<Category>> getCategoriesForMonth(String monthId) async {
    return existingCategories;
  }

  @override
  Future<Category> createCategory({
    required String monthId,
    required String name,
    String icon = 'wallet',
    String color = '#6366f1',
    bool isBudgeted = true,
    double? budgetAmount,
    int? sortOrder,
    bool allowReservedName = false,
  }) async {
    createdNames.add(name);
    _createdCount += 1;
    return Category(
      id: 'cat-$_createdCount',
      userId: 'user-1',
      monthId: monthId,
      name: name,
      icon: icon,
      color: color,
      isBudgeted: isBudgeted,
      budgetAmount: budgetAmount,
      sortOrder: sortOrder ?? _createdCount,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      items: const [],
    );
  }
}

class _FakeItemService extends ItemService {
  final List<Item> createdItems = <Item>[];
  int _createdCount = 0;

  @override
  Future<Item> createItem({
    required String categoryId,
    required String name,
    String? subscriptionId,
    double projected = 0,
    bool isArchived = false,
    bool isBudgeted = true,
    bool isRecurring = false,
    int? sortOrder,
    String? notes,
  }) async {
    _createdCount += 1;
    final created = Item(
      id: 'item-$_createdCount',
      categoryId: categoryId,
      userId: 'user-1',
      name: name,
      projected: projected,
      isArchived: isArchived,
      isBudgeted: isBudgeted,
      isRecurring: isRecurring,
      sortOrder: sortOrder ?? _createdCount,
      notes: notes,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );
    createdItems.add(created);
    return created;
  }
}

class _FakeProfileService extends ProfileService {
  int completeCalls = 0;

  @override
  Future<UserProfile> completeOnboarding() async {
    completeCalls += 1;
    return UserProfile(
      id: 'profile-1',
      userId: 'user-1',
      displayName: 'User',
      currency: 'USD',
      locale: 'en_US',
      onboardingCompleted: true,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );
  }
}
