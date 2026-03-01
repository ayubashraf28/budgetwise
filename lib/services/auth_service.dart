import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/crash_reporter.dart';
import '../config/supabase_config.dart';
import 'password_breach_checker.dart';

class AuthServiceException implements Exception {
  final String message;
  const AuthServiceException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  final SupabaseClient _client = SupabaseConfig.client;
  String get _googleRedirectUri =>
      '${SupabaseConfig.appRedirectScheme}://login-callback';

  User? get currentUser => _client.auth.currentUser;

  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      await _rejectBreachedPassword(password);

      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'display_name': displayName} : null,
      );
      await CrashReporter.recordBreadcrumb(
        'bw_auth_signup_success',
        parameters: const <String, Object?>{
          'provider': 'password',
        },
      );
      return response;
    } catch (error, stackTrace) {
      await CrashReporter.recordError(
        error,
        stackTrace,
        reason: 'Email sign-up failed',
        context: const <String, Object?>{
          'feature_area': 'auth',
          'operation': 'sign_up',
        },
      );
      rethrow;
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user != null) {
        await CrashReporter.setUser(id: user.id);
      }
      await CrashReporter.recordBreadcrumb(
        'bw_auth_signin_success',
        parameters: const <String, Object?>{
          'provider': 'password',
        },
      );
      return response;
    } catch (error, stackTrace) {
      await CrashReporter.recordError(
        error,
        stackTrace,
        reason: 'Email sign-in failed',
        context: const <String, Object?>{
          'feature_area': 'auth',
          'operation': 'sign_in',
        },
      );
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    _assertGoogleSignInSupportedPlatform();

    try {
      final launched = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _googleRedirectUri,
      );
      if (!launched) {
        throw const AuthServiceException(
          'Unable to open Google sign-in. Please try again.',
        );
      }
      await CrashReporter.recordBreadcrumb(
        'bw_auth_google_oauth_started',
        parameters: const <String, Object?>{
          'provider': 'google',
        },
      );
    } on AuthException catch (e) {
      await CrashReporter.recordError(
        e,
        StackTrace.current,
        reason: 'Google sign-in auth exception',
        context: const <String, Object?>{
          'feature_area': 'auth',
          'operation': 'google_sign_in',
        },
      );
      throw AuthServiceException(_mapGoogleAuthError(e));
    } on AuthServiceException {
      rethrow;
    } catch (e, st) {
      await CrashReporter.recordError(
        e,
        st,
        reason: 'Google sign-in failed',
        context: const <String, Object?>{
          'feature_area': 'auth',
          'operation': 'google_sign_in',
        },
      );
      throw AuthServiceException(_mapGoogleAuthError(e));
    }
  }

  Future<AuthResponse> linkGoogleAccount() async {
    _assertGoogleSignInSupportedPlatform();

    if (_client.auth.currentUser == null) {
      throw const AuthServiceException('You must be signed in to link Google.');
    }

    final linkedProviders = await getLinkedProviders();
    if (linkedProviders.contains('google')) {
      throw const AuthServiceException(
        'Google is already linked to this account.',
      );
    }

    final googleSignIn = _buildGoogleSignIn();

    try {
      await googleSignIn.signOut();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthServiceException('Google linking was cancelled.');
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null || idToken.isEmpty) {
        throw const AuthServiceException(
          'Google linking failed: missing ID token.',
        );
      }
      if (accessToken == null || accessToken.isEmpty) {
        throw const AuthServiceException(
          'Google linking failed: missing access token.',
        );
      }

      return await _client.auth.linkIdentityWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } on AuthServiceException catch (e, st) {
      await CrashReporter.recordError(
        e,
        st,
        reason: 'Google link account failed',
        context: const <String, Object?>{
          'feature_area': 'auth',
          'operation': 'link_google_account',
        },
      );
      rethrow;
    } catch (e, st) {
      await CrashReporter.recordError(
        e,
        st,
        reason: 'Google link account failed',
        context: const <String, Object?>{
          'feature_area': 'auth',
          'operation': 'link_google_account',
        },
      );
      throw AuthServiceException(_mapGoogleAuthError(e));
    }
  }

  Future<Set<String>> getLinkedProviders() async {
    final identities = await _client.auth.getUserIdentities();
    final providers = identities
        .map((identity) => identity.provider.trim().toLowerCase())
        .where((provider) => provider.isNotEmpty)
        .toSet();

    if (_client.auth.currentUser?.email != null) {
      providers.add('email');
    }

    return providers;
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } finally {
      await CrashReporter.clearUser();
      await CrashReporter.recordBreadcrumb(
        'bw_auth_signout',
        parameters: const <String, Object?>{
          'provider': 'all',
        },
      );
    }
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<UserResponse> updatePassword(String newPassword) async {
    await _rejectBreachedPassword(newPassword);

    return await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> _rejectBreachedPassword(String password) async {
    final isBreached = await PasswordBreachChecker.isBreached(password);
    if (isBreached) {
      throw const AuthServiceException(
        'This password has appeared in a data breach. Please choose a different one.',
      );
    }
  }

  Future<UserResponse> updateProfile({
    String? displayName,
    String? email,
  }) async {
    final Map<String, dynamic> data = {};
    if (displayName != null) data['display_name'] = displayName;

    return await _client.auth.updateUser(
      UserAttributes(email: email, data: data.isNotEmpty ? data : null),
    );
  }

  void _assertGoogleSignInSupportedPlatform() {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      throw const AuthServiceException(
        'Google sign-in is only available on Android and iOS in this release.',
      );
    }
  }

  GoogleSignIn _buildGoogleSignIn() {
    final iosClientId = defaultTargetPlatform == TargetPlatform.iOS
        ? SupabaseConfig.googleIosClientId
        : null;

    return GoogleSignIn(
      clientId: iosClientId,
      serverClientId: SupabaseConfig.googleWebClientId,
      scopes: const ['email', 'profile'],
    );
  }

  String _mapGoogleAuthError(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('network') ||
        message.contains('connection') ||
        message.contains('socket') ||
        message.contains('timeout')) {
      return 'No internet connection. Please try again.';
    }
    if (message.contains('provider_disabled') ||
        message.contains('provider is not enabled') ||
        message.contains('provider not enabled')) {
      return 'Google sign-in is not enabled in Supabase.';
    }
    if (message.contains('manual linking') && message.contains('disabled')) {
      return 'Manual identity linking is disabled in Supabase.';
    }
    if (message.contains('already linked') ||
        message.contains('identity already exists') ||
        message.contains('account exists')) {
      return 'This Google account is already linked to another user.';
    }
    if (message.contains('token') &&
        (message.contains('missing') || message.contains('invalid'))) {
      return 'Google authentication failed because tokens were invalid.';
    }
    if (message.contains('audience') || message.contains('wrong audience')) {
      return 'Google authentication failed. Please try again.';
    }
    if (message.contains('cancel')) {
      return 'Google authentication was cancelled.';
    }

    return 'Google authentication failed. Please try again.';
  }
}
