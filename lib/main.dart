import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'config/crash_reporter.dart';
import 'config/firebase_env.dart';
import 'config/supabase_config.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // In debug mode, load .env file for local development convenience.
  // In release mode, secrets are provided via --dart-define at compile time
  // and are NOT bundled as an extractable asset in the APK.
  if (kDebugMode) {
    try {
      await dotenv.load(fileName: '.env');
      SupabaseConfig.setRuntimeEnv(dotenv.env);
    } catch (_) {
      // .env file may not exist if using --dart-define; that's fine.
    }
  }

  // Initialize Supabase
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

  runZonedGuarded(
    () {
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
