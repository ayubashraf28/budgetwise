import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/theme.dart';
import 'config/routes.dart';
import 'config/constants.dart';
import 'providers/providers.dart';

class BudgetWiseApp extends ConsumerWidget {
  const BudgetWiseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final appFontSize = ref.watch(appFontSizeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        if (child == null) {
          return const SizedBox.shrink();
        }
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(appFontSize.scaleFactor),
          ),
          child: child,
        );
      },
    );
  }
}
