import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../config/sentry_config.dart';
import '../config/supabase_config.dart';
import '../models/app_notification.dart';
import '../models/subscription.dart';
import '../utils/errors/app_error.dart';
import '../utils/errors/error_mapper.dart';
import 'month_service.dart';

class NotificationService {
  NotificationService({
    dynamic client,
    FlutterLocalNotificationsPlugin? localNotificationsPlugin,
  })  : _client = client ?? SupabaseConfig.client,
        _localNotificationsPlugin =
            localNotificationsPlugin ?? FlutterLocalNotificationsPlugin();

  static final NotificationService _instance = NotificationService();
  static NotificationService get instance => _instance;

  final dynamic _client;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin;

  static const _notificationsTable = 'notifications';
  static const _profilesTable = 'profiles';
  static const _subscriptionsTable = 'subscriptions';
  static const _transactionsTable = 'transactions';
  static const _categoriesTable = 'categories';

  bool _isInitialized = false;

  String get _userId {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppError.unauthenticated();
    }
    return userId;
  }

  bool get _supportsLocalNotifications {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
  }

  bool get _supportsNotificationPermission {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();
    await _configureLocalTimezone();

    if (_supportsLocalNotifications) {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const settings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _localNotificationsPlugin.initialize(settings);
      await _createNotificationChannelIfNeeded();
    }

    _isInitialized = true;
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (error, stackTrace) {
      tz.setLocalLocation(tz.UTC);
      await SentryConfig.captureException(
        error,
        stackTrace,
        hint: 'Falling back to UTC timezone for notifications',
      );
    }
  }

  Future<void> _createNotificationChannelIfNeeded() async {
    if (kIsWeb || !Platform.isAndroid) return;

    const channel = AndroidNotificationChannel(
      'budgetwise_general',
      'BudgetWise Notifications',
      description: 'Budget reminders and alerts',
      importance: Importance.high,
    );

    final androidImplementation =
        _localNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.createNotificationChannel(channel);
  }

  Future<bool> areNotificationsAllowed() async {
    if (!_supportsNotificationPermission) return true;
    final status = await Permission.notification.status;
    return status.isGranted || status.isLimited;
  }

  Future<bool> requestPermissionIfNeeded() async {
    await initialize();
    if (!_supportsNotificationPermission) return true;

    final currentStatus = await Permission.notification.status;
    if (currentStatus.isGranted || currentStatus.isLimited) {
      return true;
    }

    final requestedStatus = await Permission.notification.request();
    var granted = requestedStatus.isGranted || requestedStatus.isLimited;

    if (_supportsLocalNotifications &&
        (Platform.isIOS || Platform.isMacOS) &&
        !granted) {
      var nativeGranted = false;
      if (Platform.isIOS) {
        final iosImplementation =
            _localNotificationsPlugin.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        nativeGranted = await iosImplementation?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      } else if (Platform.isMacOS) {
        final macImplementation =
            _localNotificationsPlugin.resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin>();
        nativeGranted = await macImplementation?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
      granted = granted || nativeGranted;
    }

    return granted;
  }

  Future<void> handleAuthStateChanged({
    required String? previousUserId,
    required String? nextUserId,
  }) async {
    await initialize();

    if (previousUserId != null && previousUserId != nextUserId) {
      await cancelAllScheduledForCurrentUser();
    }

    if (nextUserId == null) {
      return;
    }

    await bootstrapCurrentUserNotifications();
  }

  Future<void> bootstrapCurrentUserNotifications() async {
    if (_client.auth.currentUser == null) return;

    await initialize();

    await rescheduleAllActiveSubscriptionReminders();
    await emitDueSubscriptionReminderNotifications();
    await maybeCreateMonthlyReminder();
  }

  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic> payload = const <String, dynamic>{},
  }) async {
    await initialize();
    if (!_supportsLocalNotifications) return;
    if (!await _canGenerateNotification(type)) return;
    if (!await areNotificationsAllowed()) return;

    await _localNotificationsPlugin.show(
      id,
      title,
      body,
      _notificationDetails(),
      payload: jsonEncode(payload),
    );
  }

  Future<void> scheduleSubscriptionReminder(Subscription subscription) async {
    await initialize();
    if (!_supportsLocalNotifications) return;

    final notificationId =
        _subscriptionReminderScheduleNotificationId(subscription.id);

    if (!subscription.isActive ||
        !await _canGenerateNotification(
            NotificationType.subscriptionReminder)) {
      await _localNotificationsPlugin.cancel(notificationId);
      return;
    }

    if (!await areNotificationsAllowed()) return;

    final dueDate = DateTime(
      subscription.nextDueDate.year,
      subscription.nextDueDate.month,
      subscription.nextDueDate.day,
    );
    final reminderDate =
        dueDate.subtract(Duration(days: subscription.reminderDaysBefore));
    final scheduledAtLocal = DateTime(
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      9,
    );
    final scheduledAt = tz.TZDateTime.from(scheduledAtLocal, tz.local);
    if (!scheduledAt.isAfter(tz.TZDateTime.now(tz.local))) {
      await _localNotificationsPlugin.cancel(notificationId);
      return;
    }

    final payload = <String, dynamic>{
      'type': notificationTypeToString(NotificationType.subscriptionReminder),
      'subscription_id': subscription.id,
      'due_date': _dateOnly(dueDate),
      'scheduled_for': _dateOnly(reminderDate),
    };

    await _localNotificationsPlugin.zonedSchedule(
      notificationId,
      'Upcoming subscription payment',
      '${subscription.name} is due on ${DateFormat('d MMM').format(dueDate)}.',
      scheduledAt,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: jsonEncode(payload),
    );
  }

  Future<void> cancelSubscriptionReminder(String subscriptionId) async {
    await initialize();
    if (!_supportsLocalNotifications) return;
    await _localNotificationsPlugin.cancel(
      _subscriptionReminderScheduleNotificationId(subscriptionId),
    );
  }

  Future<void> rescheduleAllActiveSubscriptionReminders() async {
    await initialize();
    if (_client.auth.currentUser == null) return;

    try {
      final rows = await _client
          .from(_subscriptionsTable)
          .select()
          .eq('user_id', _userId)
          .eq('is_active', true);

      final subscriptions = (rows as List)
          .map((json) => Subscription.fromJson(json as Map<String, dynamic>))
          .toList();

      for (final subscription in subscriptions) {
        await scheduleSubscriptionReminder(subscription);
      }
    } catch (error, stackTrace) {
      await SentryConfig.captureException(
        error,
        stackTrace,
        hint: 'Failed to reschedule subscription reminders',
      );
    }
  }

  Future<void> cancelAllScheduledForCurrentUser() async {
    await initialize();
    if (!_supportsLocalNotifications) return;
    await _localNotificationsPlugin.cancelAll();
  }

  Future<AppNotification?> createInAppNotification({
    required String title,
    required String body,
    required NotificationType type,
    String? subscriptionId,
    String? categoryId,
    String? monthId,
    Map<String, dynamic> payload = const <String, dynamic>{},
    bool respectPreferences = true,
  }) async {
    if (respectPreferences && !await _canGenerateNotification(type)) {
      return null;
    }

    try {
      final response = await _client
          .from(_notificationsTable)
          .insert(<String, dynamic>{
            'user_id': _userId,
            'title': title.trim(),
            'body': body.trim(),
            'type': notificationTypeToString(type),
            'subscription_id': subscriptionId,
            'category_id': categoryId,
            'month_id': monthId,
            'is_read': false,
            'payload': payload,
          })
          .select()
          .single();

      return AppNotification.fromJson(response);
    } catch (error, stackTrace) {
      final mapped = ErrorMapper.toAppError(error, stackTrace: stackTrace);
      if (mapped.code == AppErrorCode.conflict) {
        return null;
      }
      rethrow;
    }
  }

  Future<List<AppNotification>> getUserNotifications() async {
    if (_client.auth.currentUser == null) return <AppNotification>[];

    final response = await _client
        .from(_notificationsTable)
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => AppNotification.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAsRead(String id) async {
    await _client
        .from(_notificationsTable)
        .update(<String, dynamic>{
          'is_read': true,
          'read_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> markAllAsRead() async {
    await _client
        .from(_notificationsTable)
        .update(<String, dynamic>{
          'is_read': true,
          'read_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', _userId)
        .eq('is_read', false);
  }

  Future<void> deleteNotification(String id) async {
    await _client
        .from(_notificationsTable)
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> checkAndCreateBudgetAlert({
    required String categoryId,
    required String monthId,
  }) async {
    if (!await _canGenerateNotification(NotificationType.budgetAlert)) return;

    final categoryResponse = await _client
        .from(_categoriesTable)
        .select(
            'id, name, is_budgeted, budget_amount, items(projected, is_archived)')
        .eq('id', categoryId)
        .eq('user_id', _userId)
        .maybeSingle();
    if (categoryResponse == null) return;

    final category = categoryResponse;
    final isBudgeted = category['is_budgeted'] as bool? ?? true;
    if (!isBudgeted) return;

    final budgetAmount = (category['budget_amount'] as num?)?.toDouble();
    double projected = budgetAmount ?? 0.0;

    if (budgetAmount == null) {
      final items = category['items'] as List<dynamic>? ?? const <dynamic>[];
      projected = 0;
      for (final rawItem in items) {
        if (rawItem is! Map<String, dynamic>) continue;
        final isArchived = rawItem['is_archived'] as bool? ?? false;
        if (isArchived) continue;
        projected += (rawItem['projected'] as num?)?.toDouble() ?? 0.0;
      }
    }
    if (projected <= 0) return;

    final txResponse = await _client
        .from(_transactionsTable)
        .select('amount')
        .eq('user_id', _userId)
        .eq('month_id', monthId)
        .eq('category_id', categoryId)
        .eq('type', 'expense');

    final actual = (txResponse as List<dynamic>).fold<double>(
      0,
      (sum, row) =>
          sum +
          (((row as Map<String, dynamic>)['amount'] as num?)?.toDouble() ?? 0),
    );
    if (actual <= projected) return;

    if (await _notificationExists(
      type: NotificationType.budgetAlert,
      categoryId: categoryId,
      monthId: monthId,
    )) {
      return;
    }

    final categoryName = (category['name'] as String?)?.trim();
    const title = 'Budget exceeded';
    final body =
        '${categoryName == null || categoryName.isEmpty ? 'A category' : categoryName} is over budget by ${(actual - projected).toStringAsFixed(2)}.';
    final payload = <String, dynamic>{
      'category_id': categoryId,
      'month_id': monthId,
      'actual': actual,
      'projected': projected,
    };

    await createInAppNotification(
      title: title,
      body: body,
      type: NotificationType.budgetAlert,
      categoryId: categoryId,
      monthId: monthId,
      payload: payload,
    );
    await showImmediateNotification(
      id: _budgetAlertNotificationId(categoryId, monthId),
      title: title,
      body: body,
      type: NotificationType.budgetAlert,
      payload: payload,
    );
  }

  Future<void> maybeCreateMonthlyReminder() async {
    if (!await _canGenerateNotification(NotificationType.monthlyReminder)) {
      return;
    }

    final now = DateTime.now();
    if (now.day < 1 || now.day > 3) return;

    final month = await MonthService().getMonthForDate(now);
    if (await _notificationExists(
      type: NotificationType.monthlyReminder,
      monthId: month.id,
    )) {
      return;
    }

    const title = 'New month, new budget';
    final body = 'Review your plan for ${month.name} and stay on track.';
    final payload = <String, dynamic>{
      'month_id': month.id,
      'month_name': month.name,
    };

    await createInAppNotification(
      title: title,
      body: body,
      type: NotificationType.monthlyReminder,
      monthId: month.id,
      payload: payload,
    );
    await showImmediateNotification(
      id: _monthlyReminderNotificationId(month.id),
      title: title,
      body: body,
      type: NotificationType.monthlyReminder,
      payload: payload,
    );
  }

  Future<void> emitDueSubscriptionReminderNotifications() async {
    if (!await _canGenerateNotification(
        NotificationType.subscriptionReminder)) {
      return;
    }

    final rows = await _client
        .from(_subscriptionsTable)
        .select()
        .eq('user_id', _userId)
        .eq('is_active', true);

    final subscriptions = (rows as List)
        .map((json) => Subscription.fromJson(json as Map<String, dynamic>))
        .toList();

    final today = DateTime.now();
    final dateToday = DateTime(today.year, today.month, today.day);

    for (final subscription in subscriptions) {
      final dueDate = DateTime(
        subscription.nextDueDate.year,
        subscription.nextDueDate.month,
        subscription.nextDueDate.day,
      );
      final triggerDate =
          dueDate.subtract(Duration(days: subscription.reminderDaysBefore));
      if (triggerDate.isAfter(dateToday)) {
        continue;
      }

      final dueDateValue = _dateOnly(dueDate);
      final exists = await _client
          .from(_notificationsTable)
          .select('id')
          .eq('user_id', _userId)
          .eq(
            'type',
            notificationTypeToString(NotificationType.subscriptionReminder),
          )
          .eq('subscription_id', subscription.id)
          .contains(
              'payload', <String, dynamic>{'due_date': dueDateValue}).limit(1);
      if ((exists as List).isNotEmpty) {
        continue;
      }

      const title = 'Subscription reminder';
      final body =
          '${subscription.name} is due on ${DateFormat('d MMM').format(dueDate)}.';
      final payload = <String, dynamic>{
        'subscription_id': subscription.id,
        'due_date': dueDateValue,
      };

      await createInAppNotification(
        title: title,
        body: body,
        type: NotificationType.subscriptionReminder,
        subscriptionId: subscription.id,
        payload: payload,
      );
      await showImmediateNotification(
        id: _subscriptionReminderTriggerNotificationId(
          subscription.id,
          dueDateValue,
        ),
        title: title,
        body: body,
        type: NotificationType.subscriptionReminder,
        payload: payload,
      );
    }
  }

  Future<bool> _notificationExists({
    required NotificationType type,
    String? categoryId,
    String? monthId,
  }) async {
    dynamic query = _client
        .from(_notificationsTable)
        .select('id')
        .eq('user_id', _userId)
        .eq('type', notificationTypeToString(type));

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    if (monthId != null) {
      query = query.eq('month_id', monthId);
    }

    final response = await query.limit(1);
    return (response as List).isNotEmpty;
  }

  Future<bool> _canGenerateNotification(NotificationType type) async {
    final prefs = await _loadPreferences();
    if (!prefs.notificationsEnabled) return false;

    switch (type) {
      case NotificationType.subscriptionReminder:
        return prefs.subscriptionRemindersEnabled;
      case NotificationType.budgetAlert:
        return prefs.budgetAlertsEnabled;
      case NotificationType.monthlyReminder:
        return prefs.monthlyRemindersEnabled;
    }
  }

  Future<_NotificationPreferences> _loadPreferences() async {
    if (_client.auth.currentUser == null) {
      return const _NotificationPreferences.defaults();
    }

    final response = await _client
        .from(_profilesTable)
        .select(
          'notifications_enabled, subscription_reminders_enabled, budget_alerts_enabled, monthly_reminders_enabled',
        )
        .eq('user_id', _userId)
        .maybeSingle();
    if (response == null) {
      return const _NotificationPreferences.defaults();
    }
    return _NotificationPreferences(
      notificationsEnabled: response['notifications_enabled'] as bool? ?? true,
      subscriptionRemindersEnabled:
          response['subscription_reminders_enabled'] as bool? ?? true,
      budgetAlertsEnabled: response['budget_alerts_enabled'] as bool? ?? true,
      monthlyRemindersEnabled:
          response['monthly_reminders_enabled'] as bool? ?? true,
    );
  }

  NotificationDetails _notificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      'budgetwise_general',
      'BudgetWise Notifications',
      channelDescription: 'Budget reminders and alerts',
      importance: Importance.high,
      priority: Priority.high,
    );
    const darwinDetails = DarwinNotificationDetails();
    return const NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
  }

  int _subscriptionReminderScheduleNotificationId(String subscriptionId) {
    return _stableNotificationId(
        'subscription_schedule::$subscriptionId', 1000);
  }

  int _subscriptionReminderTriggerNotificationId(
    String subscriptionId,
    String dueDate,
  ) {
    return _stableNotificationId(
      'subscription_due::$subscriptionId::$dueDate',
      2000,
    );
  }

  int _budgetAlertNotificationId(String categoryId, String monthId) {
    return _stableNotificationId('budget::$categoryId::$monthId', 3000);
  }

  int _monthlyReminderNotificationId(String monthId) {
    return _stableNotificationId('monthly::$monthId', 4000);
  }

  int _stableNotificationId(String input, int namespace) {
    const fnvOffset = 0x811C9DC5;
    const fnvPrime = 0x01000193;
    var hash = fnvOffset;
    final codeUnits = input.codeUnits;
    for (final unit in codeUnits) {
      hash ^= unit;
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }
    final positiveHash = hash & 0x7FFFFFFF;
    return namespace + (positiveHash % 0x3FFFFF);
  }

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

@immutable
class _NotificationPreferences {
  final bool notificationsEnabled;
  final bool subscriptionRemindersEnabled;
  final bool budgetAlertsEnabled;
  final bool monthlyRemindersEnabled;

  const _NotificationPreferences({
    required this.notificationsEnabled,
    required this.subscriptionRemindersEnabled,
    required this.budgetAlertsEnabled,
    required this.monthlyRemindersEnabled,
  });

  const _NotificationPreferences.defaults()
      : notificationsEnabled = true,
        subscriptionRemindersEnabled = true,
        budgetAlertsEnabled = true,
        monthlyRemindersEnabled = true;
}
