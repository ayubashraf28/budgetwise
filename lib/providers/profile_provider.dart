import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import '../services/profile_service.dart';

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
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> completeOnboarding() async {
    final profileService = ref.read(profileServiceProvider);
    state = const AsyncValue.loading();
    try {
      final profile = await profileService.completeOnboarding();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    final profileService = ref.read(profileServiceProvider);
    state = const AsyncValue.loading();
    try {
      final profile = await profileService.getCurrentProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final profileNotifierProvider = AsyncNotifierProvider<ProfileNotifier, UserProfile?>(() {
  return ProfileNotifier();
});
