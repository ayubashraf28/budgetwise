import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'config/sentry_config.dart';
import 'config/supabase_config.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

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
