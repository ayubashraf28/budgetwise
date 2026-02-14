import 'package:budgetwise/screens/auth/login_screen.dart';
import 'package:budgetwise/screens/auth/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpAuthScreen(WidgetTester tester, Widget child) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(1200, 2200),
          textScaler: TextScaler.linear(1.0),
        ),
        child: ProviderScope(
          child: MaterialApp(home: child),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('login screen opens forgot password dialog', (tester) async {
    await pumpAuthScreen(tester, const LoginScreen());

    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();

    expect(find.text('Reset Password'), findsOneWidget);
    expect(find.text('Send link'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('register screen renders core controls', (tester) async {
    await pumpAuthScreen(tester, const RegisterScreen());

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
