import 'dart:async';

import 'package:budgetwise/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('authRecoveryBootstrapProvider', () {
    test('sets recovery pending when password recovery event arrives',
        () async {
      final controller = StreamController<AuthState>.broadcast();
      final container = ProviderContainer(
        overrides: [
          authStateChangeProvider.overrideWith((ref) => controller.stream),
        ],
      );
      addTearDown(() async {
        await controller.close();
        container.dispose();
      });

      container.read(authRecoveryBootstrapProvider);
      expect(container.read(passwordRecoveryPendingProvider), isFalse);

      controller.add(const AuthState(AuthChangeEvent.passwordRecovery, null));
      await Future<void>.delayed(Duration.zero);

      expect(container.read(passwordRecoveryPendingProvider), isTrue);
    });

    test('clears recovery pending when signed out event arrives', () async {
      final controller = StreamController<AuthState>.broadcast();
      final container = ProviderContainer(
        overrides: [
          authStateChangeProvider.overrideWith((ref) => controller.stream),
          passwordRecoveryPendingProvider.overrideWith((ref) => true),
        ],
      );
      addTearDown(() async {
        await controller.close();
        container.dispose();
      });

      container.read(authRecoveryBootstrapProvider);

      controller.add(const AuthState(AuthChangeEvent.signedOut, null));
      await Future<void>.delayed(Duration.zero);

      expect(container.read(passwordRecoveryPendingProvider), isFalse);
    });

    test('ignores non-recovery auth events', () async {
      final controller = StreamController<AuthState>.broadcast();
      final container = ProviderContainer(
        overrides: [
          authStateChangeProvider.overrideWith((ref) => controller.stream),
        ],
      );
      addTearDown(() async {
        await controller.close();
        container.dispose();
      });

      container.read(authRecoveryBootstrapProvider);

      controller.add(const AuthState(AuthChangeEvent.signedIn, null));
      await Future<void>.delayed(Duration.zero);

      expect(container.read(passwordRecoveryPendingProvider), isFalse);
    });
  });
}
