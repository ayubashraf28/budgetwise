import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';
import 'ui_preferences_provider.dart';

const Duration _sessionIdleTimeout = Duration(minutes: 15);

final sessionSecurityControllerProvider = Provider<SessionSecurityController>(
  (ref) {
    final controller = SessionSecurityController(ref);
    ref.onDispose(controller.dispose);

    controller.onAuthChanged(ref.read(isAuthenticatedProvider));
    controller.setStayLoggedIn(ref.read(stayLoggedInProvider));

    ref.listen<bool>(isAuthenticatedProvider, (previous, next) {
      controller.onAuthChanged(next);
    });
    ref.listen<bool>(stayLoggedInProvider, (previous, next) {
      controller.setStayLoggedIn(next);
    });

    return controller;
  },
);

class SessionSecurityController with WidgetsBindingObserver {
  SessionSecurityController(this._ref) {
    WidgetsBinding.instance.addObserver(this);
  }

  final Ref _ref;
  Timer? _idleTimer;
  DateTime _lastInteractionUtc = DateTime.now().toUtc();
  bool _isAuthenticated = false;
  bool _stayLoggedIn = false;
  bool _isSigningOut = false;

  bool get _shouldEnforceTimeout => _isAuthenticated && !_stayLoggedIn;

  void recordUserInteraction() {
    if (!_shouldEnforceTimeout) return;
    _lastInteractionUtc = DateTime.now().toUtc();
    _scheduleIdleTimer();
  }

  void onAuthChanged(bool isAuthenticated) {
    _isAuthenticated = isAuthenticated;
    if (!_isAuthenticated) {
      _cancelIdleTimer();
      return;
    }
    _lastInteractionUtc = DateTime.now().toUtc();
    _scheduleIdleTimer();
  }

  void setStayLoggedIn(bool stayLoggedIn) {
    _stayLoggedIn = stayLoggedIn;
    if (_shouldEnforceTimeout) {
      _scheduleIdleTimer();
    } else {
      _cancelIdleTimer();
    }
  }

  Future<void> _handleIdleTimeout() async {
    if (!_shouldEnforceTimeout || _isSigningOut) return;

    final idleDuration = DateTime.now().toUtc().difference(_lastInteractionUtc);
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

    final idleDuration = DateTime.now().toUtc().difference(_lastInteractionUtc);
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
    if (!_shouldEnforceTimeout) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _cancelIdleTimer();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      unawaited(_handleIdleTimeout());
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelIdleTimer();
  }
}
