import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuration loaded from compile-time --dart-define flags.
///
/// Build with:
///   flutter build apk --release \
///     --dart-define=SUPABASE_URL=https://your-project.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=your-anon-key \
///     --dart-define=GOOGLE_WEB_CLIENT_ID=... \
///     --dart-define=GOOGLE_ANDROID_CLIENT_ID_DEBUG=... \
///     --dart-define=GOOGLE_ANDROID_CLIENT_ID_RELEASE=... \
///     --dart-define=APP_REDIRECT_SCHEME=com.alivastudio.budgetwise \
///     --obfuscate --split-debug-info=build/symbols
///
/// Use the app redirect scheme that matches the active Android flavor:
///   dev -> com.alivastudio.budgetwise.dev
///   stg -> com.alivastudio.budgetwise.stg
///   prod -> com.alivastudio.budgetwise
///
/// Repo-managed .env values are used as a runtime fallback when dart-defines
/// are not supplied, which keeps manual dev/test builds functional on web and
/// mobile. Dart-defines still take precedence.
class SupabaseConfig {
  SupabaseConfig._();

  static SupabaseClient get client => Supabase.instance.client;

  // Compile-time constants from --dart-define (preferred, not extractable from APK)
  static const _dartDefineSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const _dartDefineSupabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');
  static const _dartDefineGoogleWebClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static const _dartDefineGoogleAndroidClientIdDebug =
      String.fromEnvironment('GOOGLE_ANDROID_CLIENT_ID_DEBUG');
  static const _dartDefineGoogleAndroidClientIdRelease =
      String.fromEnvironment('GOOGLE_ANDROID_CLIENT_ID_RELEASE');
  static const _dartDefineGoogleIosClientId =
      String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
  static const _dartDefineAppRedirectScheme =
      String.fromEnvironment('APP_REDIRECT_SCHEME');

  // Runtime fallbacks (set by main.dart from dotenv for local development)
  static Map<String, String> _runtimeEnv = {};

  /// Called from main.dart after loading .env (for local development only).
  static void setRuntimeEnv(Map<String, String> env) {
    _runtimeEnv = env;
  }

  static String _env(String key) {
    // Prefer compile-time --dart-define values
    switch (key) {
      case 'SUPABASE_URL':
        if (_dartDefineSupabaseUrl.isNotEmpty) {
          return _dartDefineSupabaseUrl;
        }
      case 'SUPABASE_ANON_KEY':
        if (_dartDefineSupabaseAnonKey.isNotEmpty) {
          return _dartDefineSupabaseAnonKey;
        }
      case 'GOOGLE_WEB_CLIENT_ID':
        if (_dartDefineGoogleWebClientId.isNotEmpty) {
          return _dartDefineGoogleWebClientId;
        }
      case 'GOOGLE_ANDROID_CLIENT_ID_DEBUG':
        if (_dartDefineGoogleAndroidClientIdDebug.isNotEmpty) {
          return _dartDefineGoogleAndroidClientIdDebug;
        }
      case 'GOOGLE_ANDROID_CLIENT_ID_RELEASE':
        if (_dartDefineGoogleAndroidClientIdRelease.isNotEmpty) {
          return _dartDefineGoogleAndroidClientIdRelease;
        }
      case 'GOOGLE_IOS_CLIENT_ID':
        if (_dartDefineGoogleIosClientId.isNotEmpty) {
          return _dartDefineGoogleIosClientId;
        }
      case 'APP_REDIRECT_SCHEME':
        if (_dartDefineAppRedirectScheme.isNotEmpty) {
          return _dartDefineAppRedirectScheme;
        }
    }
    // Fall back to runtime .env for local development
    return (_runtimeEnv[key] ?? '').trim();
  }

  static String get supabaseUrl => _requiredSupabaseUrl();
  static String get supabaseAnonKey => _requiredSupabaseAnonKey();
  static String get googleWebClientId =>
      _requiredGoogleClientId('GOOGLE_WEB_CLIENT_ID');
  static String get googleAndroidClientId => _resolvedAndroidGoogleClientId();
  static String? get googleIosClientId =>
      _optionalGoogleClientId('GOOGLE_IOS_CLIENT_ID');
  static String get appRedirectScheme {
    final value = _env('APP_REDIRECT_SCHEME');
    if (value.isEmpty) {
      return 'com.alivastudio.budgetwise';
    }
    return value;
  }

  static Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  static User? get currentUser => client.auth.currentUser;

  static bool get isAuthenticated => currentUser != null;

  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;

  static String _requiredSupabaseUrl() {
    final value = _env('SUPABASE_URL');
    final uri = Uri.tryParse(value);
    if (value.isEmpty || uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw StateError(
        'Invalid or missing SUPABASE_URL. Provide a valid https://<project>.supabase.co URL via --dart-define or .env.',
      );
    }
    return value;
  }

  static String _requiredSupabaseAnonKey() {
    final value = _env('SUPABASE_ANON_KEY');
    if (value.isEmpty || _isPlaceholderClientId(value)) {
      throw StateError(
        'Invalid or missing SUPABASE_ANON_KEY. Provide a real publishable/anon key via --dart-define or .env.',
      );
    }
    return value;
  }

  static String _requiredGoogleClientId(String key) {
    final value = _env(key);
    if (value.isEmpty ||
        _isPlaceholderClientId(value) ||
        !_isGoogleClientId(value)) {
      throw StateError(
        'Invalid or missing environment variable $key. Expected a real Google OAuth client ID.',
      );
    }
    return value;
  }

  static String _resolvedAndroidGoogleClientId() {
    // Backward-compatible fallback for legacy env key.
    final legacyClientId = _optionalGoogleClientId('GOOGLE_ANDROID_CLIENT_ID');
    if (legacyClientId != null) {
      return legacyClientId;
    }

    return _requiredGoogleClientId(
      kReleaseMode
          ? 'GOOGLE_ANDROID_CLIENT_ID_RELEASE'
          : 'GOOGLE_ANDROID_CLIENT_ID_DEBUG',
    );
  }

  static String? _optionalGoogleClientId(String key) {
    final value = _env(key);
    if (value.isEmpty || _isPlaceholderClientId(value)) {
      return null;
    }
    if (!_isGoogleClientId(value)) {
      throw StateError(
        'Invalid environment variable $key. Expected a Google OAuth client ID.',
      );
    }
    return value;
  }

  static bool _isGoogleClientId(String value) {
    return value.endsWith('.apps.googleusercontent.com');
  }

  static bool _isPlaceholderClientId(String value) {
    final normalized = value.toLowerCase();
    return normalized.startsWith('your-') ||
        normalized.startsWith('your_') ||
        normalized.contains('<') ||
        normalized.contains('replace-me') ||
        normalized.contains('example');
  }
}
