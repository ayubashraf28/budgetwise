import '../config/constants.dart';
import '../config/supabase_config.dart';
import '../models/user_profile.dart';
import '../utils/errors/app_error.dart';

class ProfileService {
  final _client = SupabaseConfig.client;
  static const _table = 'profiles';

  String get _userId {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppError.unauthenticated();
    }
    return userId;
  }

  /// Ensure profile exists for the current user, create if not
  Future<UserProfile> ensureProfileExists() async {
    // Check if profile exists
    final existing = await getCurrentProfile();
    if (existing != null) return existing;

    // Create profile if it doesn't exist
    final now = DateTime.now();
    final response = await _client
        .from(_table)
        .insert({
          'user_id': _userId,
          'display_name':
              _client.auth.currentUser?.email?.split('@').first ?? 'User',
          'currency': AppConstants.defaultCurrency,
          'locale': AppConstants.defaultLocale,
          'onboarding_completed': false,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        })
        .select()
        .single();

    return UserProfile.fromJson(response);
  }

  /// Get the current user's profile
  Future<UserProfile?> getCurrentProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response =
        await _client.from(_table).select().eq('user_id', userId).maybeSingle();

    if (response == null) return null;
    return UserProfile.fromJson(response);
  }

  /// Get a profile by user ID
  Future<UserProfile?> getProfileByUserId(String userId) async {
    final response =
        await _client.from(_table).select().eq('user_id', userId).maybeSingle();

    if (response == null) return null;
    return UserProfile.fromJson(response);
  }

  /// Update the current user's profile
  Future<UserProfile> updateProfile({
    String? displayName,
    String? currency,
    String? locale,
    bool? onboardingCompleted,
  }) async {
    // Ensure profile exists before updating
    await ensureProfileExists();

    final updates = <String, dynamic>{};
    if (displayName != null) updates['display_name'] = displayName;
    if (currency != null) updates['currency'] = currency;
    if (locale != null) updates['locale'] = locale;
    if (onboardingCompleted != null) {
      updates['onboarding_completed'] = onboardingCompleted;
    }

    if (updates.isEmpty) {
      final current = await getCurrentProfile();
      if (current == null) {
        throw const AppError.notFound(
          technicalMessage: 'Profile not found',
        );
      }
      return current;
    }

    final response = await _client
        .from(_table)
        .update(updates)
        .eq('user_id', _userId)
        .select()
        .single();

    return UserProfile.fromJson(response);
  }

  /// Mark onboarding as completed
  Future<UserProfile> completeOnboarding() async {
    return updateProfile(onboardingCompleted: true);
  }

  /// Check if onboarding is completed
  Future<bool> isOnboardingCompleted() async {
    final profile = await getCurrentProfile();
    return profile?.onboardingCompleted ?? false;
  }

  /// Delete all app data for the current user while preserving auth account
  Future<void> deleteAllUserData() async {
    await _client.rpc('delete_all_user_data');
  }
}
