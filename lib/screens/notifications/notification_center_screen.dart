import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../models/app_notification.dart';
import '../../providers/providers.dart';
import '../../utils/errors/error_mapper.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/neo_page_components.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = NeoTheme.of(context);
    final notificationsAsync = ref.watch(userNotificationsProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      backgroundColor: palette.appBg,
      body: NeoPageBackground(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  NeoLayout.screenPadding,
                  0,
                  NeoLayout.screenPadding,
                  AppSpacing.sm,
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notifications',
                              style: NeoTypography.pageTitle(context),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '$unreadCount unread',
                              style: NeoTypography.pageContext(context),
                            ),
                          ],
                        ),
                      ),
                      if (unreadCount > 0)
                        TextButton(
                          onPressed: () async {
                            try {
                              await ref
                                  .read(notificationNotifierProvider.notifier)
                                  .markAllRead();
                            } catch (_) {}
                          },
                          child: const Text('Mark all read'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            ...notificationsAsync.when(
              data: (notifications) {
                if (notifications.isEmpty) {
                  return <Widget>[
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(NeoLayout.screenPadding),
                        child: EmptyState(
                          title: 'No notifications yet',
                          message:
                              'Budget reminders and alerts will appear here.',
                          icon: LucideIcons.bellOff,
                        ),
                      ),
                    ),
                  ];
                }

                return <Widget>[
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: NeoLayout.screenPadding,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final notification = notifications[index];
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: _NotificationRow(
                              notification: notification,
                              onTap: () async {
                                if (!notification.isRead) {
                                  try {
                                    await ref
                                        .read(notificationNotifierProvider
                                            .notifier)
                                        .markRead(notification.id);
                                  } catch (_) {}
                                }
                              },
                              onDelete: () async {
                                try {
                                  await ref
                                      .read(
                                          notificationNotifierProvider.notifier)
                                      .deleteNotification(notification.id);
                                } catch (error, stackTrace) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        ErrorMapper.toUserMessage(
                                          error,
                                          stackTrace: stackTrace,
                                        ),
                                      ),
                                      backgroundColor:
                                          NeoTheme.negativeValue(context),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                        childCount: notifications.length,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: AppSpacing.xl +
                          MediaQuery.paddingOf(context).bottom +
                          NeoLayout.bottomNavSafeBuffer,
                    ),
                  ),
                ];
              },
              loading: () => <Widget>[
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 240,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ],
              error: (error, stackTrace) => <Widget>[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(NeoLayout.screenPadding),
                    child: ErrorState(
                      message: ErrorMapper.toUserMessage(
                        error,
                        stackTrace: stackTrace,
                      ),
                      onRetry: () {
                        ref
                            .read(notificationNotifierProvider.notifier)
                            .refresh();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationRow({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);
    final accent = _colorForType(context, notification.type);
    final createdLabel =
        DateFormat('d MMM, h:mm a').format(notification.createdAt);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        decoration: BoxDecoration(
          color: NeoTheme.negativeValue(context),
          borderRadius: BorderRadius.circular(NeoLayout.cardRadius),
        ),
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(NeoLayout.cardRadius),
          child: NeoGlassCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                  ),
                  child: Icon(
                    _iconForType(notification.type),
                    size: NeoIconSizes.lg,
                    color: accent,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: NeoTypography.rowTitle(context).copyWith(
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: NeoTypography.rowSecondary(context).copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        createdLabel,
                        style: AppTypography.bodySmall.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.subscriptionReminder:
        return LucideIcons.repeat;
      case NotificationType.budgetAlert:
        return LucideIcons.alertTriangle;
      case NotificationType.monthlyReminder:
        return LucideIcons.calendar;
    }
  }

  Color _colorForType(BuildContext context, NotificationType type) {
    switch (type) {
      case NotificationType.subscriptionReminder:
        return NeoTheme.of(context).accent;
      case NotificationType.budgetAlert:
        return NeoTheme.warningValue(context);
      case NotificationType.monthlyReminder:
        return NeoTheme.positiveValue(context);
    }
  }
}
