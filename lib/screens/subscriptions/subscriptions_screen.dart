import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../models/subscription.dart';
import '../../providers/providers.dart';
import 'subscription_form_sheet.dart';

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(subscriptionsProvider);
    final totalCost = ref.watch(totalSubscriptionCostProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () => _showAddSheet(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(subscriptionsProvider);
        },
        child: subscriptionsAsync.when(
          data: (subscriptions) {
            final active = subscriptions.where((s) => s.isActive).toList();
            final paused = subscriptions.where((s) => !s.isActive).toList();

            return CustomScrollView(
              slivers: [
                // Summary Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: _buildSummaryCard(totalCost, active.length, currencySymbol),
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
                      child: const Text('Active', style: AppTypography.h3),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final sub = active[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: _buildSubscriptionCard(context, ref, sub, currencySymbol),
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
                      child: const Text('Paused', style: AppTypography.h3),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final sub = paused[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: _buildSubscriptionCard(context, ref, sub, currencySymbol),
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
              ],
            );
          },
          loading: () => const SliverToBoxAdapter(
            child: SizedBox(
              height: 400,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, stack) => SliverToBoxAdapter(
            child: _buildErrorState(error.toString()),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double totalCost, int activeCount, String currencySymbol) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Monthly Cost', style: AppTypography.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$currencySymbol${totalCost.toStringAsFixed(0)}',
            style: AppTypography.amountLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$activeCount ${activeCount == 1 ? 'active subscription' : 'active subscriptions'}',
            style: AppTypography.bodyMedium,
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
        ref.read(subscriptionNotifierProvider.notifier).deleteSubscription(sub.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${sub.name} deleted')),
        );
      },
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: sub.colorValue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
              ),
              child: Icon(
                _getIcon(sub.icon),
                color: sub.colorValue,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sub.name, style: AppTypography.labelLarge),
                  const SizedBox(height: 2),
                  Text(
                    '$currencySymbol${sub.amount.toStringAsFixed(0)} / ${sub.billingCycleLabel.toLowerCase()}',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        size: 12,
                        color: sub.isOverdue
                            ? AppColors.error
                            : sub.isDueToday
                                ? AppColors.warning
                                : AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        sub.isDueToday
                            ? 'Due today'
                            : sub.isOverdue
                                ? 'Overdue ${sub.daysUntilDue.abs()} days'
                                : 'Due ${DateFormat('d MMM').format(sub.nextDueDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: sub.isOverdue
                              ? AppColors.error
                              : sub.isDueToday
                                  ? AppColors.warning
                                  : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Menu
            PopupMenuButton<String>(
              icon: const Icon(LucideIcons.moreVertical, size: 20),
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
                        ref.read(subscriptionNotifierProvider.notifier).deleteSubscription(sub.id);
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
                      Icon(LucideIcons.trash2, size: 18, color: AppColors.error),
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

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.repeat,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text('No subscriptions yet', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Add your first subscription to track recurring payments',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: () => _showAddSheet(context, ref),
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('Add Subscription'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            const Text('Something went wrong', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.sm),
            Text(error, style: AppTypography.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
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

  Future<void> _markAsPaid(BuildContext context, WidgetRef ref, Subscription sub) async {
    try {
      await ref.read(subscriptionNotifierProvider.notifier).markAsPaid(sub.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${sub.name} marked as paid')),
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

  Future<void> _toggleActive(BuildContext context, WidgetRef ref, Subscription sub) async {
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

  Future<bool> _showDeleteConfirmation(BuildContext context, Subscription sub) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Delete Subscription?'),
            content: Text('This will permanently delete "${sub.name}". This action cannot be undone.'),
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

