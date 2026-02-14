import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/constants.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../utils/errors/error_mapper.dart';

/// Provider for the profile service
final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

/// Provider for the current user's profile
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final profileService = ref.watch(profileServiceProvider);
  return profileService.getCurrentProfile();
});

/// Provider to check if onboarding is completed
final isOnboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  return profile?.onboardingCompleted ?? false;
});

/// Notifier for profile management
class ProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final profileService = ref.watch(profileServiceProvider);
    return profileService.getCurrentProfile();
  }

  Future<void> updateProfile({
    String? displayName,
    String? currency,
    String? locale,
  }) async {
    final profileService = ref.read(profileServiceProvider);
    state = const AsyncValue.loading();
    try {
      final profile = await profileService.updateProfile(
        displayName: displayName,
        currency: currency,
        locale: locale,
      );
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(ErrorMapper.toAppError(e, stackTrace: st), st);
    }
  }

  Future<void> completeOnboarding() async {
    final profileService = ref.read(profileServiceProvider);
    state = const AsyncValue.loading();
    try {
      final profile = await profileService.completeOnboarding();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(ErrorMapper.toAppError(e, stackTrace: st), st);
    }
  }

  Future<void> refresh() async {
    final profileService = ref.read(profileServiceProvider);
    state = const AsyncValue.loading();
    try {
      final profile = await profileService.getCurrentProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(ErrorMapper.toAppError(e, stackTrace: st), st);
    }
  }
}

final profileNotifierProvider =
    AsyncNotifierProvider<ProfileNotifier, UserProfile?>(() {
  return ProfileNotifier();
});

/// Provider for the current currency code (e.g., 'GBP', 'USD')
final currencyProvider = Provider<String>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  return profile?.currency ?? AppConstants.defaultCurrency;
});

/// Provider for the current currency symbol (e.g., '£', '$')
final currencySymbolProvider = Provider<String>((ref) {
  final currency = ref.watch(currencyProvider);
  return AppConstants.currencySymbols[currency] ?? '\u00A3';
});
