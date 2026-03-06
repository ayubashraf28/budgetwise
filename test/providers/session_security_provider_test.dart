import 'package:budgetwise/providers/auth_provider.dart';
import 'package:budgetwise/providers/session_security_provider.dart';
import 'package:budgetwise/providers/ui_preferences_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('signed-in session records initial activity heartbeat',
      (tester) async {
    final clock = _FakeClock(DateTime.utc(2026, 3, 6, 9));
    var calls = 0;

    final container = ProviderContainer(
      overrides: [
        isAuthenticatedProvider.overrideWith((ref) => true),
        isAnonymousProvider.overrideWith((ref) => false),
        stayLoggedInProvider.overrideWith((ref) => true),
        sessionSecurityClockProvider.overrideWithValue(clock.call),
        sessionActivityToucherProvider.overrideWithValue(() async {
          calls += 1;
        }),
      ],
    );
    addTearDown(container.dispose);

    container.read(sessionSecurityControllerProvider);
    await tester.pump();

    expect(calls, 1);
  });

  testWidgets('anonymous sessions also record activity heartbeats',
      (tester) async {
    final clock = _FakeClock(DateTime.utc(2026, 3, 6, 9));
    var calls = 0;

    final container = ProviderContainer(
      overrides: [
        isAuthenticatedProvider.overrideWith((ref) => true),
        isAnonymousProvider.overrideWith((ref) => true),
        stayLoggedInProvider.overrideWith((ref) => true),
        sessionSecurityClockProvider.overrideWithValue(clock.call),
        sessionActivityToucherProvider.overrideWithValue(() async {
          calls += 1;
        }),
      ],
    );
    addTearDown(container.dispose);

    container.read(sessionSecurityControllerProvider);
    await tester.pump();

    expect(calls, 1);
  });

  testWidgets('activity heartbeats are throttled between interactions',
      (tester) async {
    final clock = _FakeClock(DateTime.utc(2026, 3, 6, 9));
    var calls = 0;

    final container = ProviderContainer(
      overrides: [
        isAuthenticatedProvider.overrideWith((ref) => true),
        isAnonymousProvider.overrideWith((ref) => false),
        stayLoggedInProvider.overrideWith((ref) => true),
        sessionSecurityClockProvider.overrideWithValue(clock.call),
        sessionActivityToucherProvider.overrideWithValue(() async {
          calls += 1;
        }),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(sessionSecurityControllerProvider);
    await tester.pump();
    expect(calls, 1);

    controller.recordUserInteraction();
    await tester.pump();
    expect(calls, 1);

    clock.advance(const Duration(hours: 13));
    controller.recordUserInteraction();
    await tester.pump();
    expect(calls, 2);
  });

  testWidgets('app resume forces a fresh activity heartbeat', (tester) async {
    final clock = _FakeClock(DateTime.utc(2026, 3, 6, 9));
    var calls = 0;

    final container = ProviderContainer(
      overrides: [
        isAuthenticatedProvider.overrideWith((ref) => true),
        isAnonymousProvider.overrideWith((ref) => false),
        stayLoggedInProvider.overrideWith((ref) => true),
        sessionSecurityClockProvider.overrideWithValue(clock.call),
        sessionActivityToucherProvider.overrideWithValue(() async {
          calls += 1;
        }),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(sessionSecurityControllerProvider);
    await tester.pump();
    expect(calls, 1);

    clock.advance(const Duration(minutes: 5));
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump();

    expect(calls, 2);
  });

  testWidgets('failed heartbeat is retried on next interaction',
      (tester) async {
    final clock = _FakeClock(DateTime.utc(2026, 3, 6, 9));
    var calls = 0;

    final container = ProviderContainer(
      overrides: [
        isAuthenticatedProvider.overrideWith((ref) => true),
        isAnonymousProvider.overrideWith((ref) => false),
        stayLoggedInProvider.overrideWith((ref) => true),
        sessionSecurityClockProvider.overrideWithValue(clock.call),
        sessionActivityToucherProvider.overrideWithValue(() async {
          calls += 1;
          if (calls == 1) {
            throw StateError('offline');
          }
        }),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(sessionSecurityControllerProvider);
    await tester.pump();
    expect(calls, 1);

    controller.recordUserInteraction();
    await tester.pump();

    expect(calls, 2);
  });
}

class _FakeClock {
  _FakeClock(this.current);

  DateTime current;

  DateTime call() => current;

  void advance(Duration duration) {
    current = current.add(duration);
  }
}
