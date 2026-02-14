import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static SupabaseClient get client => Supabase.instance.client;

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get googleWebClientId =>
      _requiredGoogleClientId('GOOGLE_WEB_CLIENT_ID');
  static String get googleAndroidClientId => _resolvedAndroidGoogleClientId();
  static String? get googleIosClientId =>
      _optionalGoogleClientId('GOOGLE_IOS_CLIENT_ID');

  static Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  static User? get currentUser => client.auth.currentUser;

  static bool get isAuthenticated => currentUser != null;

  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;

  static String _requiredEnv(String key) {
    final value = (dotenv.env[key] ?? '').trim();
    if (value.isEmpty) {
      throw StateError('Missing required environment variable: $key');
    }
    return value;
  }

  static String _requiredGoogleClientId(String key) {
    final value = _requiredEnv(key);
    if (_isPlaceholderClientId(value) || !_isGoogleClientId(value)) {
      throw StateError(
        'Invalid environment variable $key. Expected a real Google OAuth client ID.',
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
    final value = (dotenv.env[key] ?? '').trim();
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
