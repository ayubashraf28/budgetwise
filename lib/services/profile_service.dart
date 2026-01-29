import '../config/supabase_config.dart';
import '../models/user_profile.dart';

class ProfileService {
  final _client = SupabaseConfig.client;
  static const _table = 'profiles';

  /// Ensure profile exists for the current user, create if not
  Future<UserProfile> ensureProfileExists() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Check if profile exists
    final existing = await getCurrentProfile();
    if (existing != null) return existing;

    // Create profile if it doesn't exist
    final now = DateTime.now();
    final response = await _client
        .from(_table)
        .insert({
          'user_id': userId,
          'display_name': _client.auth.currentUser?.email?.split('@').first ?? 'User',
          'currency': 'USD',
          'locale': 'en_US',
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

    final response = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return UserProfile.fromJson(response);
  }

  /// Get a profile by user ID
  Future<UserProfile?> getProfileByUserId(String userId) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .maybeSingle();

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
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

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
      if (current == null) throw Exception('Profile not found');
      return current;
    }

    final response = await _client
        .from(_table)
        .update(updates)
        .eq('user_id', userId)
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
}
