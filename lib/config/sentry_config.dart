import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class SentryConfig {
  SentryConfig._();

  static bool _initialized = false;
  static bool _enabled = false;

  static Future<void> initialize(
    Future<void> Function() appRunner,
  ) async {
    if (_initialized) {
      await appRunner();
      return;
    }

    _initialized = true;
    final dsn = (dotenv.env['SENTRY_DSN'] ?? '').trim();
    final hasDsn = dsn.isNotEmpty;

    if (!hasDsn) {
      _enabled = false;
      debugPrint(
        '[SentryConfig] SENTRY_DSN is empty. Running without Sentry.',
      );
      await appRunner();
      return;
    }

    if (kDebugMode) {
      _enabled = false;
      debugPrint(
        '[SentryConfig] Debug build detected. Crash events are logged locally only.',
      );
      await appRunner();
      return;
    }

    _enabled = true;
    await SentryFlutter.init(
      (options) {
        options.dsn = dsn;
        options.environment = kReleaseMode ? 'release' : 'profile';
        options.debug = false;
      },
      appRunner: appRunner,
    );
  }

  static Future<void> captureException(
    Object error,
    StackTrace? stackTrace, {
    String? hint,
  }) async {
    if (!_enabled) {
      debugPrint('[SentryConfig] captureException: $error');
      if (stackTrace != null) {
        debugPrint('[SentryConfig] stackTrace: $stackTrace');
      }
      if (hint != null && hint.isNotEmpty) {
        debugPrint('[SentryConfig] hint: $hint');
      }
      return;
    }

    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
    );
  }

  static Future<void> setUser({
    required String id,
    String? email,
    String? username,
  }) async {
    if (!_enabled) {
      debugPrint('[SentryConfig] setUser: $id');
      return;
    }

    await Sentry.configureScope((scope) {
      scope.setUser(
        SentryUser(
          id: id,
          email: email,
          username: username,
        ),
      );
    });
  }

  static Future<void> clearUser() async {
    if (!_enabled) {
      debugPrint('[SentryConfig] clearUser');
      return;
    }

    await Sentry.configureScope((scope) {
      scope.setUser(null);
    });
  }
}
