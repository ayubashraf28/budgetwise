import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../models/account.dart';
import '../../models/subscription.dart';
import '../../providers/providers.dart';
import '../../utils/app_icon_registry.dart';
import '../../utils/subscription_payment_feedback.dart';
import '../../widgets/common/neo_page_components.dart';
import 'subscription_form_sheet.dart';

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = NeoTheme.of(context);
    final subscriptionsAsync = ref.watch(subscriptionsProvider);
    final accounts = ref.watch(accountsProvider).value ?? <Account>[];
    final totalCost = ref.watch(totalSubscriptionCostProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      backgroundColor: palette.appBg,
      body: NeoPageBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(subscriptionsProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    NeoLayout.screenPadding,
                    0,
                    NeoLayout.screenPadding,
                    AppSpacing.sm,
                  ),
                  child: _buildHeader(context, ref),
                ),
              ),
              ...subscriptionsAsync.when(
                data: (subscriptions) {
                  final active =
                      subscriptions.where((s) => s.isActive).toList();
                  final paused =
                      subscriptions.where((s) => !s.isActive).toList();

                  return <Widget>[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: NeoLayout.screenPadding,
                        ),
                        child: _buildSummaryCard(
                          context,
                          totalCost,
                          active.length,
                          currencySymbol,
                        ),
                      ),
                    ),
                    if (active.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            NeoLayout.screenPadding,
                            NeoLayout.sectionGap,
                            NeoLayout.screenPadding,
                            AppSpacing.sm,
                          ),
                          child: _buildSectionHeading(
                            context,
                            title: 'Active',
                            count: active.length,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: NeoLayout.screenPadding,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final sub = active[index];
                              return Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm),
                                child: _buildSubscriptionCard(
                                  context,
                                  ref,
                                  sub,
                                  currencySymbol,
                                  accounts,
                                ),
                              );
                            },
                            childCount: active.length,
                          ),
                        ),
                      ),
                    ],
                    if (paused.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            NeoLayout.screenPadding,
                            NeoLayout.sectionGap,
                            NeoLayout.screenPadding,
                            AppSpacing.sm,
                          ),
                          child: _buildSectionHeading(
                            context,
                            title: 'Paused',
                            count: paused.length,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: NeoLayout.screenPadding,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final sub = paused[index];
                              return Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm),
                                child: _buildSubscriptionCard(
                                  context,
                                  ref,
                                  sub,
                                  currencySymbol,
                                  accounts,
                                ),
                              );
                            },
                            childCount: paused.length,
                          ),
                        ),
                      ),
                    ],
                    if (subscriptions.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            NeoLayout.screenPadding,
                            NeoLayout.sectionGap,
                            NeoLayout.screenPadding,
                            0,
                          ),
                          child: _buildEmptyState(context, ref),
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
                loading: () => [
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 360,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                ],
                error: (error, stack) => [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(NeoLayout.screenPadding),
                      child: _buildErrorState(context, error.toString()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return SafeArea(
      bottom: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subscriptions',
                  style: NeoTypography.pageTitle(context),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Recurring payments and due-date tracking',
                  style: NeoTypography.pageContext(context),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: NeoCircleIconButton(
              icon: LucideIcons.plus,
              onPressed: () => _showAddSheet(context, ref),
              semanticLabel: 'Add subscription',
              size: 36,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    double totalCost,
    int activeCount,
    String currencySymbol,
  ) {
    final palette = NeoTheme.of(context);
    final accent = palette.accent;

    return NeoGlassCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: palette.surface2,
              borderRadius: BorderRadius.circular(AppSizing.radiusMd),
              border: Border.all(color: palette.stroke),
            ),
            child: Icon(
              LucideIcons.repeat,
              size: NeoIconSizes.lg,
              color: accent,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monthly cost',
                    style: NeoTypography.rowSecondary(context)),
                const SizedBox(height: 2),
                Text(
                  '$currencySymbol${_formatAmount(totalCost)}',
                  style: NeoTypography.rowAmount(context, accent),
                ),
                const SizedBox(height: 2),
                Text(
                  '$activeCount ${activeCount == 1 ? 'active subscription' : 'active subscriptions'}',
                  style: NeoTypography.rowSecondary(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading(
    BuildContext context, {
    required String title,
    required int count,
  }) {
    return Row(
      children: [
        Expanded(
          child: AdaptiveHeadingText(
            text: title,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            '$count ${count == 1 ? 'subscription' : 'subscriptions'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: NeoTypography.rowSecondary(context),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionCard(
    BuildContext context,
    WidgetRef ref,
    Subscription sub,
    String currencySymbol,
    List<Account> accounts,
  ) {
    final palette = NeoTheme.of(context);
    final color = sub.colorValue;
    final defaultAccount =
        accounts.where((a) => a.id == sub.defaultAccountId).firstOrNull;

    return Dismissible(
      key: Key(sub.id),
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
      confirmDismiss: (direction) => _showDeleteConfirmation(context, sub),
      onDismissed: (_) {
        ref
            .read(subscriptionNotifierProvider.notifier)
            .deleteSubscription(sub.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${sub.name} deleted')),
        );
      },
      child: NeoGlassCard(
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: palette.surface2,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: palette.stroke),
              ),
              child: Icon(
                _getIcon(sub.icon),
                color: color,
                size: NeoIconSizes.lg,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sub.name,
                    style: NeoTypography.rowTitle(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$currencySymbol${_formatAmount(sub.amount)} / ${sub.billingCycleLabel.toLowerCase()}',
                    style: NeoTypography.rowSecondary(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  _buildDueDateChip(context, sub),
                  if (defaultAccount != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Pays from ${defaultAccount.name}',
                      style: NeoTypography.rowSecondary(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Theme(
              data: Theme.of(context).copyWith(
                popupMenuTheme: PopupMenuThemeData(
                  color: palette.surface2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                    side: BorderSide(color: palette.stroke),
                  ),
                  textStyle: AppTypography.bodyMedium.copyWith(
                    color: palette.textPrimary,
                  ),
                ),
              ),
              child: PopupMenuButton<String>(
                icon: Icon(
                  LucideIcons.moreVertical,
                  size: NeoIconSizes.lg,
                  color: palette.textSecondary,
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditSheet(context, ref, sub);
                      break;
                    case 'mark_paid':
                      _markAsPaid(context, ref, sub, accounts);
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
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  if (sub.isActive)
                    const PopupMenuItem(
                      value: 'mark_paid',
                      child: Text('Mark as paid'),
                    ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(sub.isActive ? 'Pause' : 'Resume'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: TextStyle(color: NeoTheme.negativeValue(context)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDueDateChip(BuildContext context, Subscription sub) {
    final Color chipColor;
    if (sub.isOverdue) {
      chipColor = NeoTheme.negativeValue(context);
    } else if (sub.isDueToday || sub.isDueSoon) {
      chipColor = NeoTheme.warningValue(context);
    } else {
      chipColor = NeoTheme.of(context).textSecondary;
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSizing.radiusFull),
        border: Border.all(color: chipColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.calendar, size: NeoIconSizes.xs, color: chipColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 11,
              color: chipColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final palette = NeoTheme.of(context);

    return NeoGlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: palette.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.stroke),
              ),
              child: Icon(
                LucideIcons.repeat,
                color: palette.textSecondary,
                size: NeoIconSizes.xl,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('No subscriptions yet',
                style: NeoTypography.rowTitle(context)),
            const SizedBox(height: 2),
            Text(
              'Add recurring services to track upcoming payments.',
              style: NeoTypography.rowSecondary(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: () => _showAddSheet(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: NeoTheme.isLight(context)
                    ? palette.textPrimary
                    : palette.surface1,
              ),
              icon: const Icon(LucideIcons.plus, size: NeoIconSizes.md),
              label: const Text('Add subscription'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final danger = NeoTheme.negativeValue(context);
    return NeoGlassCard(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: danger.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: danger.withValues(alpha: 0.35)),
        ),
        child: Text(
          'Failed to load subscriptions: $error',
          style: AppTypography.bodySmall.copyWith(color: danger),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return NumberFormat('#,##0').format(amount);
    }
    return NumberFormat('#,##0.##').format(amount);
  }

  IconData _getIcon(String iconName) {
    return resolveAppIcon(iconName, fallback: LucideIcons.creditCard);
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
    BuildContext context,
    WidgetRef ref,
    Subscription sub,
    List<Account> accounts,
  ) async {
    try {
      final accountId = await _resolveAccountForPayment(context, sub, accounts);
      if (accountId == null) return;

      final result = await ref
          .read(subscriptionNotifierProvider.notifier)
          .markAsPaid(sub.id, accountId: accountId);
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
            backgroundColor:
                inFlightDuplicate ? null : NeoTheme.negativeValue(context),
          ),
        );
      }
    }
  }

  Future<String?> _resolveAccountForPayment(
    BuildContext context,
    Subscription sub,
    List<Account> activeAccounts,
  ) async {
    if (activeAccounts.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Create an account before marking a subscription paid',
            ),
            backgroundColor: NeoTheme.negativeValue(context),
          ),
        );
      }
      return null;
    }

    if (sub.defaultAccountId != null) {
      final matched =
          activeAccounts.where((a) => a.id == sub.defaultAccountId).firstOrNull;
      if (matched != null) return matched.id;
    }

    return _showAccountPickerSheet(context, activeAccounts);
  }

  Future<String?> _showAccountPickerSheet(
    BuildContext context,
    List<Account> accounts,
  ) async {
    String selectedId = accounts.first.id;

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final palette = NeoTheme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: NeoGlassCard(
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: palette.stroke,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const AdaptiveHeadingText(
                        text: 'Choose payment account',
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'This subscription has no default account.',
                        style: NeoTypography.rowSecondary(context),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...accounts.map(
                        (account) {
                          final isSelected = account.id == selectedId;
                          return InkWell(
                            onTap: () =>
                                setModalState(() => selectedId = account.id),
                            borderRadius:
                                BorderRadius.circular(AppSizing.radiusMd),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 2,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? LucideIcons.checkCircle2
                                        : LucideIcons.circle,
                                    size: NeoIconSizes.lg,
                                    color: isSelected
                                        ? palette.accent
                                        : palette.textMuted,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          account.name,
                                          style:
                                              AppTypography.bodyLarge.copyWith(
                                            color: palette.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _accountTypeLabel(account.type),
                                          style:
                                              AppTypography.bodySmall.copyWith(
                                            color: palette.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        height: AppSizing.buttonHeightCompact,
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.of(context).pop(selectedId),
                          child: const Text('Use account'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  String _accountTypeLabel(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return 'Cash';
      case AccountType.debit:
        return 'Debit';
      case AccountType.credit:
        return 'Credit';
      case AccountType.savings:
        return 'Savings';
      case AccountType.other:
        return 'Other';
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
            backgroundColor: NeoTheme.negativeValue(context),
          ),
        );
      }
    }
  }

  Future<bool> _showDeleteConfirmation(
      BuildContext context, Subscription sub) async {
    final palette = NeoTheme.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: palette.surface1,
            title: Text(
              'Delete Subscription?',
              style: AppTypography.h3.copyWith(color: palette.textPrimary),
            ),
            content: Text(
              'This will permanently delete "${sub.name}". This action cannot be undone.',
              style: AppTypography.bodyMedium.copyWith(
                color: palette.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: NeoTheme.negativeValue(context),
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
