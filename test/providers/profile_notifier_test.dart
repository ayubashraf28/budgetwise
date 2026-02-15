import 'package:budgetwise/models/user_profile.dart';
import 'package:budgetwise/providers/profile_provider.dart';
import 'package:budgetwise/services/profile_service.dart';
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
      // Already initialized in this test process.
    }
  });

  test('updateProfile sets updated AsyncData state', () async {
    final fake = _FakeProfileService(initial: _profile(displayName: 'Before'));
    final container = ProviderContainer(
      overrides: [
        profileServiceProvider.overrideWithValue(fake),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(profileNotifierProvider.notifier);
    await notifier.updateProfile(displayName: 'After');

    final state = container.read(profileNotifierProvider);
    expect(state.hasValue, isTrue);
    expect(state.value?.displayName, 'After');
  });

  test('updateProfile maps errors to AppError state', () async {
    final fake = _FakeProfileService(
      initial: _profile(displayName: 'Before'),
      updateError: const AppError.validation(
        technicalMessage: 'invalid profile update',
      ),
    );
    final container = ProviderContainer(
      overrides: [
        profileServiceProvider.overrideWithValue(fake),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(profileNotifierProvider.notifier);
    await expectLater(
      () => notifier.updateProfile(displayName: ''),
      throwsA(isA<AppError>()),
    );

    final state = container.read(profileNotifierProvider);
    expect(state.hasError, isTrue);
    expect(state.error, isA<AppError>());
  });

  test('completeOnboarding sets onboardingCompleted to true', () async {
    final fake =
        _FakeProfileService(initial: _profile(onboardingCompleted: false));
    final container = ProviderContainer(
      overrides: [
        profileServiceProvider.overrideWithValue(fake),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(profileNotifierProvider.notifier);
    await notifier.completeOnboarding();

    final state = container.read(profileNotifierProvider);
    expect(state.hasValue, isTrue);
    expect(state.value?.onboardingCompleted, isTrue);
  });

  test('refresh fetches latest profile from service', () async {
    final fake = _FakeProfileService(initial: _profile(displayName: 'First'));
    final container = ProviderContainer(
      overrides: [
        profileServiceProvider.overrideWithValue(fake),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(profileNotifierProvider.notifier);
    fake.current = _profile(displayName: 'Second');
    await notifier.refresh();

    final state = container.read(profileNotifierProvider);
    expect(state.hasValue, isTrue);
    expect(state.value?.displayName, 'Second');
  });
}

UserProfile _profile({
  String? displayName = 'User',
  String currency = 'USD',
  String locale = 'en_US',
  bool onboardingCompleted = false,
}) {
  return UserProfile(
    id: 'profile-1',
    userId: 'user-1',
    displayName: displayName,
    currency: currency,
    locale: locale,
    onboardingCompleted: onboardingCompleted,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
}

class _FakeProfileService extends ProfileService {
  _FakeProfileService({
    required this.initial,
    this.updateError,
  }) : current = initial;

  final UserProfile initial;
  UserProfile current;
  final Object? updateError;

  @override
  Future<UserProfile?> getCurrentProfile() async {
    return current;
  }

  @override
  Future<UserProfile> updateProfile({
    String? displayName,
    String? currency,
    String? locale,
    bool? onboardingCompleted,
    bool? notificationsEnabled,
    bool? subscriptionRemindersEnabled,
    bool? budgetAlertsEnabled,
    bool? monthlyRemindersEnabled,
  }) async {
    if (updateError != null) {
      throw updateError!;
    }
    current = current.copyWith(
      displayName: displayName,
      currency: currency,
      locale: locale,
      onboardingCompleted: onboardingCompleted,
      notificationsEnabled: notificationsEnabled,
      subscriptionRemindersEnabled: subscriptionRemindersEnabled,
      budgetAlertsEnabled: budgetAlertsEnabled,
      monthlyRemindersEnabled: monthlyRemindersEnabled,
    );
    return current;
  }

  @override
  Future<UserProfile> completeOnboarding() async {
    current = current.copyWith(onboardingCompleted: true);
    return current;
  }
}
