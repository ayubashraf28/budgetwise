import 'package:budgetwise/screens/settings/settings_about_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('about page shows retention summary', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SettingsAboutPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Data Retention'), findsOneWidget);
    expect(
      find.textContaining('Guest sessions may be deleted after 90 days'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Registered accounts may be deleted after 180 days'),
      findsOneWidget,
    );
  });
}
