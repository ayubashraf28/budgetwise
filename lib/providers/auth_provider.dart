import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../utils/errors/error_mapper.dart';
import 'account_provider.dart';
import 'analysis_metrics_provider.dart';
import 'category_provider.dart';
import 'income_provider.dart';
import 'month_provider.dart';
import 'onboarding_provider.dart';
import 'profile_provider.dart';
import 'subscription_provider.dart';
import 'transaction_provider.dart';
import 'yearly_provider.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges.map((state) => state.session?.user);
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

final linkedProvidersProvider = FutureProvider<Set<String>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return <String>{};

  final authService = ref.watch(authServiceProvider);
  return authService.getLinkedProviders();
});

/// Invalidates all user-scoped providers to prevent data leaking
/// between user sessions on the same device.
void invalidateAllUserProviders(Ref ref) {
  // Auth
  ref.invalidate(linkedProvidersProvider);

  // Profile & onboarding
  ref.invalidate(userProfileProvider);
  ref.invalidate(onboardingCompletedProvider);

  // Months
  ref.invalidate(activeMonthProvider);
  ref.invalidate(userMonthsProvider);
  ref.invalidate(ensureMonthSetupProvider);

  // Budget data
  ref.invalidate(categoriesProvider);
  ref.invalidate(transactionsProvider);
  ref.invalidate(incomeSourcesProvider);

  // Accounts
  ref.invalidate(accountsProvider);
  ref.invalidate(allAccountsProvider);
  ref.invalidate(netWorthProvider);

  // Subscriptions
  ref.invalidate(subscriptionsProvider);

  // Yearly/analysis
  ref.invalidate(yearMonthsProvider);
  ref.invalidate(analysisTrendMonthsProvider);
}

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthService _authService;
  final Ref _ref;

  AuthNotifier(this._authService, this._ref)
      : super(AsyncValue.data(_authService.currentUser));

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _authService.signIn(
        email: email,
        password: password,
      );
      state = AsyncValue.data(response.user);
    } catch (e, st) {
      final mappedError = ErrorMapper.toAppError(e, stackTrace: st);
      state = AsyncValue.error(mappedError, st);
      throw mappedError;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      state = AsyncValue.data(response.user);
    } catch (e, st) {
      final mappedError = ErrorMapper.toAppError(e, stackTrace: st);
      state = AsyncValue.error(mappedError, st);
      throw mappedError;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authService.signOut();
      invalidateAllUserProviders(_ref);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      final mappedError = ErrorMapper.toAppError(e, stackTrace: st);
      state = AsyncValue.error(mappedError, st);
      throw mappedError;
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      await _authService.signInWithGoogle();
      state = AsyncValue.data(_authService.currentUser);
    } catch (e, st) {
      final mappedError = ErrorMapper.toAppError(e, stackTrace: st);
      state = AsyncValue.error(mappedError, st);
      throw mappedError;
    }
  }

  Future<void> linkGoogleAccount() async {
    state = const AsyncValue.loading();
    try {
      final response = await _authService.linkGoogleAccount();
      state = AsyncValue.data(response.user ?? _authService.currentUser);
    } catch (e, st) {
      final mappedError = ErrorMapper.toAppError(e, stackTrace: st);
      state = AsyncValue.error(mappedError, st);
      throw mappedError;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
    } catch (e) {
      rethrow;
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService, ref);
});
