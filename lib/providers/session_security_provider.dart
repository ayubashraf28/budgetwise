import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/crash_reporter.dart';
import 'auth_provider.dart';
import 'profile_provider.dart';
import 'ui_preferences_provider.dart';

const Duration _sessionIdleTimeout = Duration(minutes: 15);
const Duration _sessionActivityHeartbeatInterval = Duration(hours: 12);

typedef SessionActivityToucher = Future<void> Function();

final sessionSecurityClockProvider = Provider<DateTime Function()>((ref) {
  return DateTime.now;
});

final sessionActivityHeartbeatIntervalProvider = Provider<Duration>((ref) {
  return _sessionActivityHeartbeatInterval;
});

final sessionActivityToucherProvider = Provider<SessionActivityToucher>((ref) {
  return () => ref.read(profileServiceProvider).touchLastActive();
});

final sessionSecurityControllerProvider = Provider<SessionSecurityController>(
  (ref) {
    final controller = SessionSecurityController(
      ref,
      nowProvider: ref.read(sessionSecurityClockProvider),
      activityHeartbeatInterval:
          ref.read(sessionActivityHeartbeatIntervalProvider),
      touchLastActive: ref.read(sessionActivityToucherProvider),
    );
    ref.onDispose(controller.dispose);

    controller.onAuthChanged(ref.read(isAuthenticatedProvider));
    controller.setStayLoggedIn(ref.read(stayLoggedInProvider));
    controller.setAnonymous(ref.read(isAnonymousProvider));

    ref.listen<bool>(isAuthenticatedProvider, (previous, next) {
      controller.onAuthChanged(next);
    });
    ref.listen<bool>(stayLoggedInProvider, (previous, next) {
      controller.setStayLoggedIn(next);
    });
    ref.listen<bool>(isAnonymousProvider, (previous, next) {
      controller.setAnonymous(next);
    });

    return controller;
  },
);

class SessionSecurityController with WidgetsBindingObserver {
  SessionSecurityController(
    Ref ref, {
    DateTime Function()? nowProvider,
    Duration activityHeartbeatInterval = _sessionActivityHeartbeatInterval,
    SessionActivityToucher? touchLastActive,
  })  : _ref = ref,
        _nowProvider = nowProvider ?? DateTime.now,
        _activityHeartbeatInterval = activityHeartbeatInterval,
        _touchLastActive = touchLastActive ??
            (() => ref.read(profileServiceProvider).touchLastActive()) {
    WidgetsBinding.instance.addObserver(this);
  }

  final Ref _ref;
  final DateTime Function() _nowProvider;
  final Duration _activityHeartbeatInterval;
  final SessionActivityToucher _touchLastActive;
  Timer? _idleTimer;
  DateTime _lastInteractionUtc = DateTime.now().toUtc();
  DateTime? _lastActivitySyncUtc;
  bool _isAuthenticated = false;
  bool _stayLoggedIn = false;
  bool _isAnonymous = false;
  bool _isSigningOut = false;
  bool _isActivitySyncInFlight = false;
  bool _pendingInteractionHeartbeat = false;

  bool get _shouldEnforceTimeout =>
      _isAuthenticated && !_stayLoggedIn && !_isAnonymous;

  DateTime _nowUtc() => _nowProvider().toUtc();

  void recordUserInteraction() {
    if (_shouldEnforceTimeout) {
      _lastInteractionUtc = _nowUtc();
      _scheduleIdleTimer();
    }

    if (!_isAuthenticated) return;

    unawaited(
      _syncLastActive(force: _pendingInteractionHeartbeat),
    );
  }

  void onAuthChanged(bool isAuthenticated) {
    final wasAuthenticated = _isAuthenticated;
    _isAuthenticated = isAuthenticated;
    if (!_isAuthenticated) {
      _cancelIdleTimer();
      _lastActivitySyncUtc = null;
      _pendingInteractionHeartbeat = false;
      return;
    }
    _lastInteractionUtc = _nowUtc();
    _pendingInteractionHeartbeat = true;
    _scheduleIdleTimer();

    if (!wasAuthenticated) {
      unawaited(_syncLastActive(force: true));
    }
  }

  void setStayLoggedIn(bool stayLoggedIn) {
    _stayLoggedIn = stayLoggedIn;
    if (_shouldEnforceTimeout) {
      _scheduleIdleTimer();
    } else {
      _cancelIdleTimer();
    }
  }

  void setAnonymous(bool isAnonymous) {
    _isAnonymous = isAnonymous;
    if (_shouldEnforceTimeout) {
      _scheduleIdleTimer();
    } else {
      _cancelIdleTimer();
    }
  }

  Future<void> _handleIdleTimeout() async {
    if (!_shouldEnforceTimeout || _isSigningOut) return;

    final idleDuration = _nowUtc().difference(_lastInteractionUtc);
    if (idleDuration < _sessionIdleTimeout) {
      _scheduleIdleTimer();
      return;
    }

    _isSigningOut = true;
    try {
      await _ref.read(authServiceProvider).signOut();
    } finally {
      _isSigningOut = false;
      _cancelIdleTimer();
    }
  }

  void _scheduleIdleTimer() {
    _cancelIdleTimer();
    if (!_shouldEnforceTimeout) return;

    final idleDuration = _nowUtc().difference(_lastInteractionUtc);
    final remaining = _sessionIdleTimeout - idleDuration;
    if (remaining <= Duration.zero) {
      unawaited(_handleIdleTimeout());
      return;
    }

    _idleTimer = Timer(remaining, () {
      unawaited(_handleIdleTimeout());
    });
  }

  void _cancelIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      if (_shouldEnforceTimeout) {
        _cancelIdleTimer();
      }
      return;
    }

    if (state == AppLifecycleState.resumed) {
      if (_isAuthenticated) {
        _pendingInteractionHeartbeat = true;
        unawaited(_syncLastActive(force: true));
      }
      if (_shouldEnforceTimeout) {
        unawaited(_handleIdleTimeout());
      }
    }
  }

  Future<void> _syncLastActive({bool force = false}) async {
    if (!_isAuthenticated || _isActivitySyncInFlight) return;

    final now = _nowUtc();
    final lastSync = _lastActivitySyncUtc;
    if (!force &&
        lastSync != null &&
        now.difference(lastSync) < _activityHeartbeatInterval) {
      return;
    }

    _isActivitySyncInFlight = true;
    try {
      await _touchLastActive();
      _lastActivitySyncUtc = now;
      _pendingInteractionHeartbeat = false;
    } catch (error, stackTrace) {
      await CrashReporter.recordError(
        error,
        stackTrace,
        reason: 'Profile last-active heartbeat failed',
        context: const <String, Object?>{
          'feature_area': 'session_security',
          'operation': 'touch_last_active',
        },
      );
    } finally {
      _isActivitySyncInFlight = false;
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelIdleTimer();
  }
}
