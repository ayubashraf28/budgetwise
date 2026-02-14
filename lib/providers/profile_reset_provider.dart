import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/errors/error_mapper.dart';
import 'auth_provider.dart';
import 'onboarding_provider.dart';
import 'profile_provider.dart';

class ProfileResetNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> deleteAllDataAndSignOut() async {
    state = const AsyncLoading();
    try {
      await ref.read(profileServiceProvider).deleteAllUserData();
      await ref.read(authNotifierProvider.notifier).signOut();
      ref.invalidate(linkedProvidersProvider);
      ref.invalidate(userProfileProvider);
      ref.invalidate(onboardingCompletedProvider);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      final mappedError = ErrorMapper.toAppError(error, stackTrace: stackTrace);
      state = AsyncError(mappedError, stackTrace);
      throw mappedError;
    }
  }
}

final profileResetNotifierProvider =
    AsyncNotifierProvider<ProfileResetNotifier, void>(
  ProfileResetNotifier.new,
);
