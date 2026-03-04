import 'package:budgetwise/config/supabase_config.dart';
import 'package:budgetwise/services/auth_service.dart';
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

  test('resetPassword passes the app deep-link redirect URI', () async {
    final service = _FakeAuthService();

    await service.resetPassword('user@example.com');

    expect(service.capturedEmail, 'user@example.com');
    expect(
      service.capturedRedirectTo,
      '${SupabaseConfig.appRedirectScheme}://login-callback',
    );
  });
}

class _FakeAuthService extends AuthService {
  String? capturedEmail;
  String? capturedRedirectTo;

  @override
  Future<void> sendPasswordResetEmail(
    String email, {
    required String redirectTo,
  }) async {
    capturedEmail = email;
    capturedRedirectTo = redirectTo;
  }
}
