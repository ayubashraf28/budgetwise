import 'package:budgetwise/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('login screen renders critical controls', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(
          size: Size(1200, 2200),
          textScaler: TextScaler.linear(1.0),
        ),
        child: ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text('Log In'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
