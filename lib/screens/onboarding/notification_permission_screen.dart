import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../utils/errors/error_mapper.dart';

class NotificationPermissionScreen extends ConsumerStatefulWidget {
  const NotificationPermissionScreen({super.key});

  @override
  ConsumerState<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends ConsumerState<NotificationPermissionScreen> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);
    return Scaffold(
      backgroundColor: palette.appBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: palette.accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(40),
                  border:
                      Border.all(color: palette.accent.withValues(alpha: 0.35)),
                ),
                child: Icon(
                  LucideIcons.bell,
                  size: 52,
                  color: palette.accent,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'Stay in the loop',
                style: AppTypography.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Get reminders for subscriptions and budget alerts at the right time.',
                style: AppTypography.bodyLarge.copyWith(
                  color: palette.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              _bullet(context, 'Subscription reminders before due dates'),
              const SizedBox(height: AppSpacing.sm),
              _bullet(context, 'Budget overspending alerts'),
              const SizedBox(height: AppSpacing.sm),
              _bullet(context, 'Monthly budget reset reminders'),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: AppSizing.buttonHeight,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _enableNotifications,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Enable Notifications'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: _isSubmitting ? null : _skipNotifications,
                child: const Text('Skip for now'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bullet(BuildContext context, String text) {
    final palette = NeoTheme.of(context);
    return Row(
      children: [
        Icon(
          LucideIcons.checkCircle2,
          size: 18,
          color: palette.accent,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style:
                AppTypography.bodyMedium.copyWith(color: palette.textPrimary),
          ),
        ),
      ],
    );
  }

  Future<void> _enableNotifications() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);
    try {
      final notificationService = ref.read(notificationServiceProvider);
      final granted = await notificationService.requestPermissionIfNeeded();

      if (!granted) {
        await _setNotificationPreferences(enabled: false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Notification permission was not granted. You can enable it later in Settings.',
            ),
            backgroundColor: NeoTheme.warningValue(context),
          ),
        );
        context.go('/home');
        return;
      }

      await _setNotificationPreferences(enabled: true);
      if (!mounted) return;
      context.go('/home');
    } catch (error, stackTrace) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ErrorMapper.toUserMessage(error, stackTrace: stackTrace),
          ),
          backgroundColor: NeoTheme.negativeValue(context),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _skipNotifications() async {
    HapticFeedback.selectionClick();
    setState(() => _isSubmitting = true);
    try {
      await _setNotificationPreferences(enabled: false);
      if (!mounted) return;
      context.go('/home');
    } catch (error, stackTrace) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ErrorMapper.toUserMessage(error, stackTrace: stackTrace),
          ),
          backgroundColor: NeoTheme.negativeValue(context),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _setNotificationPreferences({required bool enabled}) async {
    await ref.read(profileNotifierProvider.notifier).updateProfile(
          notificationsEnabled: enabled,
          subscriptionRemindersEnabled: enabled,
          budgetAlertsEnabled: enabled,
          monthlyRemindersEnabled: enabled,
        );
    ref.invalidate(userProfileProvider);
  }
}
