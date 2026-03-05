import 'package:budgetwise/models/user_profile.dart';
import 'package:budgetwise/providers/auth_provider.dart';
import 'package:budgetwise/providers/profile_provider.dart';
import 'package:budgetwise/providers/profile_reset_provider.dart';
import 'package:budgetwise/providers/theme_mode_provider.dart';
import 'package:budgetwise/providers/ui_preferences_provider.dart';
import 'package:budgetwise/screens/settings/settings_screen.dart';
import 'package:budgetwise/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  Future<void> pumpSettingsScreen(
    WidgetTester tester, {
    required List<Override> overrides,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('delete account flow completes without widget tree exception',
      (tester) async {
    await pumpSettingsScreen(
      tester,
      overrides: [
        authStateProvider.overrideWith(
          (ref) => Stream<User?>.value(_fakeUser()),
        ),
        userProfileProvider.overrideWith((ref) async => _fakeProfile()),
        themeModeProvider.overrideWith((ref) => ThemeMode.dark),
        budgetStructureProvider.overrideWith((ref) => BudgetStructure.detailed),
        isAnonymousProvider.overrideWith((ref) => false),
        authNotifierProvider
            .overrideWith((ref) => _FakeAuthNotifier(_FakeAuthService(), ref)),
        deleteUserAccountProvider.overrideWith((ref) {
          return () async {
            // No-op for widget-flow stability check.
          };
        }),
      ],
    );

    await tester.tap(find.text('Delete Account').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).last, 'DELETE');
    await tester.pump();

    final deleteAccountButton =
        find.widgetWithText(TextButton, 'Delete Account');
    expect(tester.widget<TextButton>(deleteAccountButton).onPressed, isNotNull);
    await tester.tap(deleteAccountButton);
    await tester.pumpAndSettle();

    expect(find.text('Type DELETE to confirm:'), findsNothing);
    expect(find.text('Settings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('delete all data flow completes without widget tree exception',
      (tester) async {
    late _FakeProfileResetNotifier profileResetNotifier;

    await pumpSettingsScreen(
      tester,
      overrides: [
        authStateProvider.overrideWith(
          (ref) => Stream<User?>.value(_fakeUser()),
        ),
        userProfileProvider.overrideWith((ref) async => _fakeProfile()),
        themeModeProvider.overrideWith((ref) => ThemeMode.dark),
        budgetStructureProvider.overrideWith((ref) => BudgetStructure.detailed),
        isAnonymousProvider.overrideWith((ref) => false),
        profileResetNotifierProvider.overrideWith(() {
          profileResetNotifier = _FakeProfileResetNotifier();
          return profileResetNotifier;
        }),
      ],
    );

    await tester.tap(find.text('Delete All Data').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).last, 'DELETE');
    await tester.pump();

    final deleteButton = find.widgetWithText(TextButton, 'Delete');
    expect(tester.widget<TextButton>(deleteButton).onPressed, isNotNull);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Delete Permanently'));
    await tester.pumpAndSettle();

    expect(profileResetNotifier.deleteCalls, 1);
    expect(find.text('Settings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeAuthService extends AuthService {}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(super.authService, super.ref);

  var signOutCalls = 0;

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
    state = const AsyncValue.data(null);
  }
}

class _FakeProfileResetNotifier extends ProfileResetNotifier {
  var deleteCalls = 0;

  @override
  Future<void> build() async {}

  @override
  Future<void> deleteAllDataAndSignOut() async {
    deleteCalls += 1;
    state = const AsyncData(null);
  }
}

User _fakeUser() {
  return User.fromJson({
    'id': 'user-1',
    'aud': 'authenticated',
    'role': 'authenticated',
    'email': 'user@example.com',
    'created_at': DateTime.utc(2026, 1, 1).toIso8601String(),
    'app_metadata': <String, dynamic>{},
    'user_metadata': <String, dynamic>{},
  })!;
}

UserProfile _fakeProfile() {
  final now = DateTime.utc(2026, 1, 1);
  return UserProfile(
    id: 'profile-1',
    userId: 'user-1',
    displayName: 'User',
    createdAt: now,
    updatedAt: now,
  );
}
