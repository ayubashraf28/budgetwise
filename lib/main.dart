import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'config/crash_reporter.dart';
import 'config/firebase_env.dart';
import 'config/supabase_config.dart';
import 'services/notification_service.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      Object? bootstrapError;

      try {
        // Load repo-managed fallback config first. Compile-time dart-defines still
        // take precedence inside SupabaseConfig, so CI/release can override safely.
        try {
          await dotenv.load(fileName: '.env');
          SupabaseConfig.setRuntimeEnv(dotenv.env);
        } catch (_) {
          // Asset may be absent in some build contexts; validation below will
          // surface a clear startup error if config is still missing.
        }

        await SupabaseConfig.initialize();

        // Initialize Firebase and crash reporting (mobile only).
        await FirebaseEnv.initializeFirebase();
        await CrashReporter.initialize(
          enabledByDefault: FirebaseEnv.crashReportingEnabled,
        );

        FlutterError.onError = (details) {
          unawaited(CrashReporter.recordFlutterFatalError(details));
        };

        PlatformDispatcher.instance.onError = (error, stack) {
          unawaited(
            CrashReporter.recordError(
              error,
              stack,
              fatal: true,
              reason: 'Unhandled platform-dispatcher error',
              context: const <String, Object?>{
                'feature_area': 'app_bootstrap',
              },
            ),
          );
          return true;
        };

        // Initialize notifications/timezone before app startup.
        await NotificationService.instance.initialize();
      } catch (error) {
        bootstrapError = error;
      }

      if (bootstrapError != null) {
        runApp(_BootstrapErrorApp(error: bootstrapError));
        return;
      }

      runApp(
        const ProviderScope(
          child: BudgetWiseApp(),
        ),
      );
    },
    (error, stack) {
      unawaited(
        CrashReporter.recordError(
          error,
          stack,
          fatal: true,
          reason: 'Uncaught zoned error',
          context: const <String, Object?>{
            'feature_area': 'app_bootstrap',
          },
        ),
      );
    },
  );
}

class _BootstrapErrorApp extends StatelessWidget {
  const _BootstrapErrorApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF080B14),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF121826),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF2A3347)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFFF6B6B),
                        size: 36,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Startup Configuration Error',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'BudgetWise could not load its backend configuration. This build needs valid Supabase settings from .env or --dart-define values.',
                        style: TextStyle(
                          color: Color(0xFFB8C0D4),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SelectableText(
                        error.toString(),
                        style: const TextStyle(
                          color: Color(0xFFFFC9C9),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
