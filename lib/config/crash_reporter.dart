import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'firebase_env.dart';

class CrashReporter {
  CrashReporter._();

  static bool _initialized = false;
  static bool _enabled = false;
  static FirebaseAnalytics? _analytics;

  static bool get enabled => _enabled;

  static Future<void> initialize({
    required bool enabledByDefault,
  }) async {
    if (_initialized) return;
    _initialized = true;

    if (!FirebaseEnv.isCrashlyticsSupportedPlatform) {
      _enabled = false;
      return;
    }

    _enabled = enabledByDefault;
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(enabledByDefault);

    if (!_enabled) {
      return;
    }

    _analytics = FirebaseAnalytics.instance;

    await setKey('app_env', FirebaseEnv.environmentName);
    await setKey('platform', defaultTargetPlatform.name);

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      await setKey('app_version', packageInfo.version);
      await setKey('build_number', packageInfo.buildNumber);
    } catch (_) {
      // Package metadata is best effort.
    }
  }

  static Future<void> recordFlutterFatalError(FlutterErrorDetails details) async {
    FlutterError.presentError(details);
    if (!_enabled) return;
    await FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  }

  static Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
    Map<String, Object?> context = const <String, Object?>{},
  }) async {
    if (!_enabled) {
      debugPrint('[CrashReporter] $error');
      if (stack != null) {
        debugPrint('[CrashReporter] $stack');
      }
      return;
    }

    final scrubbed = _scrubContext(context);
    var contextEntries = 0;
    for (final entry in scrubbed.entries) {
      if (contextEntries >= 12) break;
      await FirebaseCrashlytics.instance.setCustomKey(
        entry.key,
        _asCrashlyticsValue(entry.value),
      );
      contextEntries++;
    }

    await FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      fatal: fatal,
      reason: _sanitize(reason),
    );
  }

  static Future<void> log(String message) async {
    if (!_enabled) return;
    await FirebaseCrashlytics.instance.log(_sanitize(message));
  }

  static Future<void> setUser({
    required String id,
  }) async {
    if (!_enabled) return;
    await FirebaseCrashlytics.instance.setUserIdentifier(id.trim());
    await _analytics?.setUserId(id: id.trim());
  }

  static Future<void> clearUser() async {
    if (!_enabled) return;
    await FirebaseCrashlytics.instance.setUserIdentifier('');
    await _analytics?.setUserId();
  }

  static Future<void> setKey(String key, Object value) async {
    if (!_enabled) return;
    await FirebaseCrashlytics.instance.setCustomKey(
      key.trim(),
      _asCrashlyticsValue(value),
    );
  }

  static Future<void> recordBreadcrumb(
    String eventName, {
    Map<String, Object?> parameters = const <String, Object?>{},
  }) async {
    if (!_enabled) return;
    final safeName = _sanitizeEventName(eventName);
    final safeParams = _sanitizeAnalyticsParams(parameters);
    await _analytics?.logEvent(name: safeName, parameters: safeParams);
    await FirebaseCrashlytics.instance.log(
      'event=$safeName params=$safeParams',
    );
  }

  static Map<String, Object> _sanitizeAnalyticsParams(
    Map<String, Object?> params,
  ) {
    final out = <String, Object>{};
    var count = 0;
    for (final entry in _scrubContext(params).entries) {
      if (count >= 20) break;
      final value = entry.value;
      if (value is num || value is String || value is bool) {
        out[entry.key] = value as Object;
        count++;
      } else if (value != null) {
        out[entry.key] = value.toString();
        count++;
      }
    }
    return out;
  }

  static String _sanitizeEventName(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    final prefixed = normalized.startsWith('bw_') ? normalized : 'bw_$normalized';
    if (prefixed.length <= 40) return prefixed;
    return prefixed.substring(0, 40);
  }

  static Map<String, Object?> _scrubContext(Map<String, Object?> context) {
    final out = <String, Object?>{};
    for (final entry in context.entries) {
      final key = entry.key.trim().toLowerCase();
      final value = entry.value;
      if (_isSensitiveKey(key)) {
        out[key] = '[REDACTED]';
        continue;
      }
      if (value is String) {
        out[key] = _sanitize(value);
      } else {
        out[key] = value;
      }
    }
    return out;
  }

  static bool _isSensitiveKey(String key) {
    return key.contains('password') ||
        key.contains('token') ||
        key.contains('secret') ||
        key.contains('authorization') ||
        key.contains('cookie') ||
        key.contains('apikey') ||
        key.contains('api_key') ||
        key.contains('email');
  }

  static String _sanitize(String? value) {
    if (value == null) return '';
    final trimmed = value.trim();
    if (trimmed.length <= 300) return trimmed;
    return '${trimmed.substring(0, 300)}...';
  }

  static Object _asCrashlyticsValue(Object? value) {
    if (value == null) return 'null';
    if (value is num || value is bool || value is String) return value;
    return value.toString();
  }
}
