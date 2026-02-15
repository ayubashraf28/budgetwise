import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/sentry_config.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';
import '../utils/errors/error_mapper.dart';
import 'auth_provider.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});

final notificationBootstrapProvider = Provider<void>((ref) {
  final service = ref.watch(notificationServiceProvider);

  Future<void> syncAuthState(User? previousUser, User? nextUser) async {
    try {
      await service.handleAuthStateChanged(
        previousUserId: previousUser?.id,
        nextUserId: nextUser?.id,
      );
    } catch (error, stackTrace) {
      await SentryConfig.captureException(
        error,
        stackTrace,
        hint: 'Notification auth sync failed',
      );
    }

    try {
      if (nextUser == null) {
        await SentryConfig.clearUser();
      } else {
        await SentryConfig.setUser(
          id: nextUser.id,
          email: nextUser.email,
          username: (nextUser.userMetadata?['display_name'] as String?)?.trim(),
        );
      }
    } catch (error, stackTrace) {
      await SentryConfig.captureException(
        error,
        stackTrace,
        hint: 'Sentry user context sync failed',
      );
    }

    ref.invalidate(notificationNotifierProvider);
  }

  unawaited(service.initialize());
  unawaited(syncAuthState(null, ref.read(currentUserProvider)));

  ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
    unawaited(
      syncAuthState(
        previous?.valueOrNull,
        next.valueOrNull,
      ),
    );
  });
});

class NotificationNotifier extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return <AppNotification>[];

    final service = ref.watch(notificationServiceProvider);
    return service.getUserNotifications();
  }

  NotificationService get _service => ref.read(notificationServiceProvider);

  Future<void> refresh() async {
    await _reload();
  }

  Future<void> markRead(String id) async {
    try {
      await _service.markAsRead(id);
      await _reload();
    } catch (error, stackTrace) {
      final mapped = ErrorMapper.toAppError(error, stackTrace: stackTrace);
      state = AsyncValue.error(mapped, stackTrace);
      rethrow;
    }
  }

  Future<void> markAllRead() async {
    try {
      await _service.markAllAsRead();
      await _reload();
    } catch (error, stackTrace) {
      final mapped = ErrorMapper.toAppError(error, stackTrace: stackTrace);
      state = AsyncValue.error(mapped, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _service.deleteNotification(id);
      await _reload();
    } catch (error, stackTrace) {
      final mapped = ErrorMapper.toAppError(error, stackTrace: stackTrace);
      state = AsyncValue.error(mapped, stackTrace);
      rethrow;
    }
  }

  Future<void> _reload() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = const AsyncValue.data(<AppNotification>[]);
      return;
    }
    final latest = await _service.getUserNotifications();
    state = AsyncValue.data(latest);
  }
}

final notificationNotifierProvider =
    AsyncNotifierProvider<NotificationNotifier, List<AppNotification>>(
  NotificationNotifier.new,
);

final userNotificationsProvider = Provider<AsyncValue<List<AppNotification>>>(
  (ref) => ref.watch(notificationNotifierProvider),
);

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationNotifierProvider).valueOrNull;
  if (notifications == null) return 0;
  return notifications.where((item) => !item.isRead).length;
});
