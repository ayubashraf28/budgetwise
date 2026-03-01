import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options_dev.dart';
import 'firebase_options_prod.dart';
import 'firebase_options_stg.dart';

enum AppEnvironment {
  dev,
  stg,
  prod,
}

class FirebaseEnv {
  FirebaseEnv._();

  static const String _rawAppEnv =
      String.fromEnvironment('APP_ENV', defaultValue: 'prod');
  static const String _rawCrashReportingEnabled =
      String.fromEnvironment('CRASH_REPORTING_ENABLED', defaultValue: 'true');

  static AppEnvironment get current {
    switch (_rawAppEnv.trim().toLowerCase()) {
      case 'dev':
      case 'development':
        return AppEnvironment.dev;
      case 'stg':
      case 'stage':
      case 'staging':
        return AppEnvironment.stg;
      case 'prod':
      case 'production':
      default:
        return AppEnvironment.prod;
    }
  }

  static String get environmentName => current.name;

  static bool get crashReportingEnabled {
    final value = _rawCrashReportingEnabled.trim().toLowerCase();
    return value != '0' &&
        value != 'false' &&
        value != 'off' &&
        value != 'no';
  }

  static bool get isCrashlyticsSupportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static Future<void> initializeFirebase() async {
    if (!isCrashlyticsSupportedPlatform) {
      return;
    }
    if (Firebase.apps.isNotEmpty) {
      return;
    }

    try {
      await Firebase.initializeApp(
        options: _currentOptions,
      );
    } catch (error) {
      if (!kDebugMode) {
        rethrow;
      }
      debugPrint(
        '[FirebaseEnv] Falling back to default Firebase app initialization in debug mode: $error',
      );
      await Firebase.initializeApp();
    }
  }

  static FirebaseOptions get _currentOptions {
    switch (current) {
      case AppEnvironment.dev:
        return FirebaseOptionsDev.currentPlatform;
      case AppEnvironment.stg:
        return FirebaseOptionsStg.currentPlatform;
      case AppEnvironment.prod:
        return FirebaseOptionsProd.currentPlatform;
    }
  }
}
