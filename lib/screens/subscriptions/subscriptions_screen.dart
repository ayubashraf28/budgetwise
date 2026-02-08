import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../models/subscription.dart';
import '../../providers/providers.dart';
import '../../utils/subscription_payment_feedback.dart';
import 'subscription_form_sheet.dart';

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(subscriptionsProvider);
    final totalCost = ref.watch(totalSubscriptionCostProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(subscriptionsProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Custom header
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Subscriptions', style: AppTypography.h2),
                          const SizedBox(height: 2),
                          Text(
                            'Manage recurring payments',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      // Add button
                      GestureDetector(
                        onTap: () => _showAddSheet(context, ref),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.savings.withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(AppSizing.radiusMd),
                            border: Border.all(
                              color: AppColors.savings.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            LucideIcons.plus,
                            size: 18,
                            color: AppColors.savings,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            ...subscriptionsAsync.when(
              data: (subscriptions) {
                final active = subscriptions.where((s) => s.isActive).toList();
                final paused = subscriptions.where((s) => !s.isActive).toList();

                return <Widget>[
                  // Summary Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: _buildSummaryCard(
                          totalCost, active.length, currencySymbol),
                    ),
                  ),

                  // Active Section
                  if (active.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          AppSpacing.sm,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Active', style: AppTypography.h3),
                            Text(
                              '${active.length} ${active.length == 1 ? 'subscription' : 'subscriptions'}',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final sub = active[index];
                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: _buildSubscriptionCard(
                                  context, ref, sub, currencySymbol),
                            );
                          },
                          childCount: active.length,
                        ),
                      ),
                    ),
                  ],

                  // Paused Section
                  if (paused.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.lg,
                          AppSpacing.md,
                          AppSpacing.sm,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Paused', style: AppTypography.h3),
                            Text(
                              '${paused.length} ${paused.length == 1 ? 'subscription' : 'subscriptions'}',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final sub = paused[index];
                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: _buildSubscriptionCard(
                                  context, ref, sub, currencySymbol),
                            );
                          },
                          childCount: paused.length,
                        ),
                      ),
                    ),
                  ],

                  // Empty State
                  if (subscriptions.isEmpty)
                    SliverToBoxAdapter(
                      child: _buildEmptyState(context, ref),
                    ),

                  // Bottom padding
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xl),
                  ),
                ];
              },
              loading: () => [
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 400,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              ],
              error: (error, stack) => [
                SliverToBoxAdapter(
                  child: _buildErrorState(error.toString()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      double totalCost, int activeCount, String currencySymbol) {
    const color = AppColors.savings;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + title row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                ),
                child: const Icon(LucideIcons.repeat, size: 18, color: color),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'Monthly Cost',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Amount
          Text(
            '$currencySymbol${totalCost.toStringAsFixed(0)}',
            style: AppTypography.amountMedium.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(
            '$activeCount ${activeCount == 1 ? 'active subscription' : 'active subscriptions'}',
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(
    BuildContext context,
    WidgetRef ref,
    Subscription sub,
    String currencySymbol,
  ) {
    final color = sub.colorValue;

    return Dismissible(
      key: Key(sub.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        ),
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      confirmDismiss: (direction) => _showDeleteConfirmation(context, sub),
      onDismissed: (_) {
        ref
            .read(subscriptionNotifierProvider.notifier)
            .deleteSubscription(sub.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${sub.name} deleted')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
              ),
              child: Icon(
                _getIcon(sub.icon),
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sub.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$currencySymbol${sub.amount.toStringAsFixed(0)} / ${sub.billingCycleLabel.toLowerCase()}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Due date chip
                  _buildDueDateChip(sub),
                ],
              ),
            ),
            // Menu
            PopupMenuButton<String>(
              icon: const Icon(
                LucideIcons.moreVertical,
                size: 18,
                color: AppColors.textSecondary,
              ),
              color: AppColors.surface,
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showEditSheet(context, ref, sub);
                    break;
                  case 'mark_paid':
                    _markAsPaid(context, ref, sub);
                    break;
                  case 'toggle':
                    _toggleActive(context, ref, sub);
                    break;
                  case 'delete':
                    _showDeleteConfirmation(context, sub).then((confirmed) {
                      if (confirmed == true && context.mounted) {
                        ref
                            .read(subscriptionNotifierProvider.notifier)
                            .deleteSubscription(sub.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${sub.name} deleted')),
                        );
                      }
                    });
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(LucideIcons.pencil, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                if (sub.isActive)
                  const PopupMenuItem(
                    value: 'mark_paid',
                    child: Row(
                      children: [
                        Icon(LucideIcons.check, size: 18),
                        SizedBox(width: 8),
                        Text('Mark as Paid'),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(
                        sub.isActive ? LucideIcons.pause : LucideIcons.play,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(sub.isActive ? 'Pause' : 'Resume'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(LucideIcons.trash2,
                          size: 18, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDueDateChip(Subscription sub) {
    final Color chipColor;
    if (sub.isOverdue) {
      chipColor = AppColors.error;
    } else if (sub.isDueToday) {
      chipColor = AppColors.warning;
    } else {
      chipColor = AppColors.textMuted;
    }

    final String text;
    if (sub.isDueToday) {
      text = 'Due today';
    } else if (sub.isOverdue) {
      text = 'Overdue ${sub.daysUntilDue.abs()} days';
    } else {
      text = 'Due ${DateFormat('d MMM').format(sub.nextDueDate)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.calendar, size: 10, color: chipColor),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: chipColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    const color = AppColors.savings;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSizing.radiusMd),
            ),
            child: const Icon(LucideIcons.repeat, size: 24, color: color),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'No subscriptions yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Add your first subscription to track recurring payments',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => _showAddSheet(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                foregroundColor: color,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                  side: BorderSide(color: color.withValues(alpha: 0.3)),
                ),
              ),
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text(
                'Add Subscription',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSizing.radiusMd),
            ),
            child: const Icon(
              LucideIcons.alertCircle,
              size: 24,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            error,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.error.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String iconName) {
    final icons = {
      'home': LucideIcons.home,
      'utensils': LucideIcons.utensils,
      'car': LucideIcons.car,
      'tv': LucideIcons.tv,
      'shopping-bag': LucideIcons.shoppingBag,
      'gamepad-2': LucideIcons.gamepad2,
      'piggy-bank': LucideIcons.piggyBank,
      'graduation-cap': LucideIcons.graduationCap,
      'heart': LucideIcons.heart,
      'wallet': LucideIcons.wallet,
      'briefcase': LucideIcons.briefcase,
      'plane': LucideIcons.plane,
      'gift': LucideIcons.gift,
      'credit-card': LucideIcons.creditCard,
      'landmark': LucideIcons.landmark,
      'baby': LucideIcons.baby,
      'dumbbell': LucideIcons.dumbbell,
      'music': LucideIcons.music,
      'book': LucideIcons.book,
    };
    return icons[iconName] ?? LucideIcons.creditCard;
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SubscriptionFormSheet(),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, Subscription sub) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SubscriptionFormSheet(subscription: sub),
    );
  }

  Future<void> _markAsPaid(
      BuildContext context, WidgetRef ref, Subscription sub) async {
    try {
      final result = await ref
          .read(subscriptionNotifierProvider.notifier)
          .markAsPaid(sub.id);
      if (context.mounted) {
        final activeMonthId = ref.read(activeMonthProvider).valueOrNull?.id;
        final paidMonthText = result.monthName;
        final isDifferentMonth =
            activeMonthId != null && activeMonthId != result.monthId;
        final feedback = buildSubscriptionPaymentFeedback(
          subscriptionName: sub.name,
          paidMonthName: paidMonthText,
          isDifferentMonth: isDifferentMonth,
          duplicatePrevented: result.duplicatePrevented,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(feedback.message),
            action: feedback.showViewMonthAction
                ? SnackBarAction(
                    label: 'View month',
                    onPressed: () {
                      ref
                          .read(monthNotifierProvider.notifier)
                          .setActiveMonth(result.monthId);
                      context.go('/transactions');
                    },
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final message = e.toString();
        final inFlightDuplicate =
            message.toLowerCase().contains('already being processed');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              inFlightDuplicate
                  ? 'Payment already in progress'
                  : 'Error: ${e.toString()}',
            ),
            backgroundColor: inFlightDuplicate ? null : AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _toggleActive(
      BuildContext context, WidgetRef ref, Subscription sub) async {
    try {
      await ref.read(subscriptionNotifierProvider.notifier).updateSubscription(
            subscriptionId: sub.id,
            isActive: !sub.isActive,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${sub.name} ${sub.isActive ? 'paused' : 'resumed'}'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<bool> _showDeleteConfirmation(
      BuildContext context, Subscription sub) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Delete Subscription?'),
            content: Text(
                'This will permanently delete "${sub.name}". This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
