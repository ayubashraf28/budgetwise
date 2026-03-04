import 'package:budgetwise/config/supabase_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    SupabaseConfig.setRuntimeEnv(<String, String>{});
  });

  test(
      'uses runtime .env fallback for Supabase config when dart-defines are absent',
      () {
    SupabaseConfig.setRuntimeEnv(<String, String>{
      'SUPABASE_URL': 'https://example.supabase.co',
      'SUPABASE_ANON_KEY': 'test-anon-key',
    });

    expect(SupabaseConfig.supabaseUrl, 'https://example.supabase.co');
    expect(SupabaseConfig.supabaseAnonKey, 'test-anon-key');
  });

  test('throws a clear error when Supabase URL is missing', () {
    SupabaseConfig.setRuntimeEnv(<String, String>{
      'SUPABASE_ANON_KEY': 'test-anon-key',
    });

    expect(
      () => SupabaseConfig.supabaseUrl,
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('SUPABASE_URL'),
        ),
      ),
    );
  });

  test('throws a clear error when Supabase URL is invalid', () {
    SupabaseConfig.setRuntimeEnv(<String, String>{
      'SUPABASE_URL': 'not-a-url',
      'SUPABASE_ANON_KEY': 'test-anon-key',
    });

    expect(
      () => SupabaseConfig.supabaseUrl,
      throwsA(isA<StateError>()),
    );
  });
}
