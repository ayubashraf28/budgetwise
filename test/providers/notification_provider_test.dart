import 'package:budgetwise/models/app_notification.dart';
import 'package:budgetwise/providers/auth_provider.dart';
import 'package:budgetwise/providers/notification_provider.dart';
import 'package:budgetwise/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    try {
      await Supabase.initialize(
        url: 'https://example.supabase.co',
        anonKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIn0.c2lnbmF0dXJl',
      );
    } catch (_) {
      // Already initialized in this test process.
    }
  });

  test('unreadNotificationCountProvider reflects unread rows', () async {
    final fakeService = _FakeNotificationService(
      notifications: [
        _notification(id: 'n1', isRead: false),
        _notification(id: 'n2', isRead: true),
        _notification(id: 'n3', isRead: false),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith((ref) => _fakeUser()),
        notificationServiceProvider.overrideWithValue(fakeService),
      ],
    );
    addTearDown(container.dispose);

    await container.read(notificationNotifierProvider.future);
    final unread = container.read(unreadNotificationCountProvider);
    expect(unread, 2);
  });

  test('markRead and deleteNotification mutate state via notifier', () async {
    final fakeService = _FakeNotificationService(
      notifications: [
        _notification(id: 'n1', isRead: false),
        _notification(id: 'n2', isRead: false),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith((ref) => _fakeUser()),
        notificationServiceProvider.overrideWithValue(fakeService),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(notificationNotifierProvider.notifier);
    await container.read(notificationNotifierProvider.future);

    await notifier.markRead('n1');
    expect(container.read(unreadNotificationCountProvider), 1);

    await notifier.deleteNotification('n2');
    expect(container.read(unreadNotificationCountProvider), 0);
  });

  test('markAllRead clears unread count', () async {
    final fakeService = _FakeNotificationService(
      notifications: [
        _notification(id: 'n1', isRead: false),
        _notification(id: 'n2', isRead: false),
        _notification(id: 'n3', isRead: true),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith((ref) => _fakeUser()),
        notificationServiceProvider.overrideWithValue(fakeService),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(notificationNotifierProvider.notifier);
    await container.read(notificationNotifierProvider.future);
    expect(container.read(unreadNotificationCountProvider), 2);

    await notifier.markAllRead();
    expect(container.read(unreadNotificationCountProvider), 0);
  });
}

User _fakeUser() {
  return User.fromJson({
    'id': 'user-1',
    'aud': 'authenticated',
    'role': 'authenticated',
    'email': 'user@example.com',
    'created_at': DateTime.utc(2026, 1, 1).toIso8601String(),
    'app_metadata': <String, dynamic>{},
    'user_metadata': <String, dynamic>{},
  })!;
}

AppNotification _notification({
  required String id,
  required bool isRead,
}) {
  return AppNotification(
    id: id,
    userId: 'user-1',
    title: 'Title',
    body: 'Body',
    type: NotificationType.subscriptionReminder,
    isRead: isRead,
    readAt: isRead ? DateTime.utc(2026, 1, 1) : null,
    createdAt: DateTime.utc(2026, 1, 1),
    payload: const <String, dynamic>{},
  );
}

class _FakeNotificationService extends NotificationService {
  _FakeNotificationService({
    required List<AppNotification> notifications,
  })  : _notifications = List<AppNotification>.from(notifications),
        super();

  final List<AppNotification> _notifications;

  @override
  Future<List<AppNotification>> getUserNotifications() async {
    return List<AppNotification>.from(_notifications);
  }

  @override
  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index < 0) return;
    final current = _notifications[index];
    _notifications[index] = AppNotification(
      id: current.id,
      userId: current.userId,
      title: current.title,
      body: current.body,
      type: current.type,
      subscriptionId: current.subscriptionId,
      categoryId: current.categoryId,
      monthId: current.monthId,
      isRead: true,
      readAt: DateTime.utc(2026, 1, 1),
      createdAt: current.createdAt,
      updatedAt: current.updatedAt,
      payload: current.payload,
    );
  }

  @override
  Future<void> markAllAsRead() async {
    for (var i = 0; i < _notifications.length; i++) {
      final current = _notifications[i];
      _notifications[i] = AppNotification(
        id: current.id,
        userId: current.userId,
        title: current.title,
        body: current.body,
        type: current.type,
        subscriptionId: current.subscriptionId,
        categoryId: current.categoryId,
        monthId: current.monthId,
        isRead: true,
        readAt: DateTime.utc(2026, 1, 1),
        createdAt: current.createdAt,
        updatedAt: current.updatedAt,
        payload: current.payload,
      );
    }
  }

  @override
  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((item) => item.id == id);
  }
}
