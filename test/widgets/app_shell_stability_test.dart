import 'package:budgetwise/widgets/navigation/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('app shell navigation switches sections without key exceptions',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('Home Screen')),
              ),
            ),
            GoRoute(
              path: '/analysis',
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('Analysis Screen')),
              ),
            ),
            GoRoute(
              path: '/categories',
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('Categories Screen')),
              ),
            ),
            GoRoute(
              path: '/manage',
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('Manage Screen')),
              ),
            ),
            GoRoute(
              path: '/transactions/new',
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('Add Transaction')),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home Screen'), findsOneWidget);

    await tester.tap(find.text('Analysis'));
    await tester.pumpAndSettle();
    expect(find.text('Analysis Screen'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();
    expect(find.text('Categories Screen'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Manage'));
    await tester.pumpAndSettle();
    expect(find.text('Manage Screen'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Home Screen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
