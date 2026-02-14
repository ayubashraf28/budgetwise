import 'package:budgetwise/providers/auth_provider.dart';
import 'package:budgetwise/providers/profile_provider.dart';
import 'package:budgetwise/providers/profile_reset_provider.dart';
import 'package:budgetwise/services/auth_service.dart';
import 'package:budgetwise/services/profile_service.dart';
import 'package:budgetwise/utils/errors/app_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  test(
      'deleteAllDataAndSignOut deletes data, signs out, invalidates linked providers',
      () async {
    final profileService = _FakeProfileService();
    final authNotifier = _FakeAuthNotifier();
    var linkedProviderLoads = 0;

    final container = ProviderContainer(
      overrides: [
        profileServiceProvider.overrideWithValue(profileService),
        authNotifierProvider.overrideWith((ref) => authNotifier),
        linkedProvidersProvider.overrideWith((ref) async {
          linkedProviderLoads += 1;
          return <String>{'email'};
        }),
      ],
    );
    addTearDown(container.dispose);

    await container.read(linkedProvidersProvider.future);
    expect(linkedProviderLoads, 1);

    await container
        .read(profileResetNotifierProvider.notifier)
        .deleteAllDataAndSignOut();

    final state = container.read(profileResetNotifierProvider);
    expect(state.hasValue, isTrue);
    expect(profileService.deleteCalls, 1);
    expect(authNotifier.signOutCalls, 1);

    await container.read(linkedProvidersProvider.future);
    expect(linkedProviderLoads, 2);
  });

  test('deleteAllDataAndSignOut maps and rethrows failures', () async {
    final profileService = _FakeProfileService(
      deleteError: const AppError.database(
        technicalMessage: 'delete_all_user_data failed',
      ),
    );
    final authNotifier = _FakeAuthNotifier();
    final container = ProviderContainer(
      overrides: [
        profileServiceProvider.overrideWithValue(profileService),
        authNotifierProvider.overrideWith((ref) => authNotifier),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      () => container
          .read(profileResetNotifierProvider.notifier)
          .deleteAllDataAndSignOut(),
      throwsA(
        isA<AppError>().having(
          (error) => error.code,
          'code',
          AppErrorCode.database,
        ),
      ),
    );

    final state = container.read(profileResetNotifierProvider);
    expect(state.hasError, isTrue);
    expect(state.error, isA<AppError>());
    expect(profileService.deleteCalls, 1);
    expect(authNotifier.signOutCalls, 0);
  });
}

class _FakeProfileService extends ProfileService {
  _FakeProfileService({this.deleteError});

  final Object? deleteError;
  int deleteCalls = 0;

  @override
  Future<void> deleteAllUserData() async {
    deleteCalls += 1;
    if (deleteError != null) {
      throw deleteError!;
    }
  }
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier() : super(_FakeAuthService());

  int signOutCalls = 0;

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
    state = const AsyncValue.data(null);
  }
}

class _FakeAuthService extends AuthService {}
