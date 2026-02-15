import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'config/sentry_config.dart';
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

  // Initialize notifications/timezone before app startup.
  await NotificationService.instance.initialize();

  await SentryConfig.initialize(() async {
    runApp(
      const ProviderScope(
        child: BudgetWiseApp(),
      ),
    );
  });
}
