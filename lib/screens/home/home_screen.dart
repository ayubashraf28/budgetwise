import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../models/subscription.dart';
import '../../providers/providers.dart';
import '../../widgets/budget/budget_widgets.dart';
import '../transactions/transaction_form_sheet.dart';
import '../subscriptions/subscription_form_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isBalanceVisible = true;

  @override
  Widget build(BuildContext context) {
    final activeMonth = ref.watch(activeMonthProvider);
    final summary = ref.watch(monthlySummaryProvider);
    final categories = ref.watch(categoriesProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final profile = ref.watch(userProfileProvider);
    final upcoming = ref.watch(upcomingSubscriptionsProvider);
    final activeSubs = ref.watch(activeSubscriptionsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeMonthProvider);
          ref.invalidate(categoriesProvider);
          ref.invalidate(incomeSourcesProvider);
          ref.invalidate(subscriptionsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Greeting Header
            SliverToBoxAdapter(
              child: _buildGreetingHeader(ref, profile),
            ),

            // Balance Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _buildBalanceCard(ref, summary, currencySymbol),
              ),
            ),

            // Upcoming Payments
            SliverToBoxAdapter(
              child: _buildUpcomingPayments(ref, currencySymbol, upcoming),
            ),

            // Subscriptions Preview
            SliverToBoxAdapter(
              child: _buildSubscriptionsPreview(ref, currencySymbol, activeSubs),
            ),

            // Categories Section Title
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Text(
                  'Categories',
                  style: AppTypography.h3,
                ),
              ),
            ),

            // Categories List
            categories.when(
              data: (categoryList) {
                if (categoryList.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _buildEmptyState(context),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final category = categoryList[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: CategoryListItem(
                            category: category,
                            currencySymbol: currencySymbol,
                            onTap: () {
                              context.push('/budget/category/${category.id}');
                            },
                          ),
                        );
                      },
                      childCount: categoryList.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (error, stack) => SliverToBoxAdapter(
                child: _buildErrorState(context, error.toString()),
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xl),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingHeader(WidgetRef ref, AsyncValue<dynamic> profile) {
    final displayName = profile.value?.displayName ?? 'User';

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
        child: Row(
          children: [
            // Profile avatar circle
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.savings,
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Greeting text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back',
                    style: AppTypography.bodySmall,
                  ),
                  Text(displayName, style: AppTypography.h2),
                ],
              ),
            ),
            // Notification bell icon
            IconButton(
              icon: const Icon(LucideIcons.bell, color: AppColors.textSecondary),
              onPressed: () {
                // Future: notifications screen
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(WidgetRef ref, dynamic summary, String currencySymbol) {
    final actualBalance = summary?.actualBalance ?? 0.0;
    final previousBalance = 0.0; // TODO: Calculate from previous month
    final balanceChange = actualBalance - previousBalance;
    final balanceChangePercent = previousBalance != 0
        ? (balanceChange / previousBalance.abs()) * 100
        : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.tealGradient,
        borderRadius: BorderRadius.circular(AppSizing.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Total Balance" + info icon
          Row(
            children: [
              Text(
                'Total Balance',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                LucideIcons.info,
                size: 14,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Amount + eye toggle
          Row(
            children: [
              Text(
                _isBalanceVisible
                    ? '$currencySymbol${actualBalance.toStringAsFixed(0)}'
                    : '••••••',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Eye toggle icon
              GestureDetector(
                onTap: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
                child: Icon(
                  _isBalanceVisible ? LucideIcons.eye : LucideIcons.eyeOff,
                  size: 20,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Percentage change badge
          if (balanceChangePercent != 0)
            _buildPercentageBadge(balanceChangePercent),
          const SizedBox(height: AppSpacing.lg),
          // "Add New Transaction" button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddTransaction(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.tealDark,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                ),
              ),
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text(
                'Add New Transaction',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageBadge(double percent) {
    final isPositive = percent >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppSizing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? LucideIcons.trendingUp : LucideIcons.trendingDown,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            '${isPositive ? '+' : ''}${percent.toStringAsFixed(1)}% this month',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingPayments(
    WidgetRef ref,
    String currencySymbol,
    AsyncValue<List<Subscription>> upcoming,
  ) {
    return upcoming.when(
      data: (upcomingList) {
        if (upcomingList.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Upcoming Payments', style: AppTypography.h3),
                      Text('Bills due soon', style: AppTypography.bodySmall),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.push('/subscriptions'),
                    child: Text(
                      'View All →',
                      style: TextStyle(color: AppColors.savings),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Horizontal scroll of cards
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: upcomingList.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final sub = upcomingList[index];
                  return _buildUpcomingCard(sub, currencySymbol);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildUpcomingCard(Subscription sub, String currencySymbol) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(AppSpacing.sm + 4), // 12px padding
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon + name row
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: sub.colorValue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSizing.radiusSm),
                ),
                child: Icon(_getIcon(sub.icon), color: sub.colorValue, size: 16),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  sub.name,
                  style: AppTypography.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Amount + cycle
          Text(
            '$currencySymbol${sub.amount.toStringAsFixed(0)}/${sub.billingCycleLabel.toLowerCase()}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          // Due date chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: sub.isOverdue
                  ? AppColors.error.withValues(alpha: 0.15)
                  : AppColors.savings.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSizing.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.calendar,
                  size: 11,
                  color: sub.isOverdue ? AppColors.error : AppColors.savings,
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    sub.isDueToday
                        ? 'Due today'
                        : 'Due in ${sub.daysUntilDue} days',
                    style: TextStyle(
                      fontSize: 10,
                      color: sub.isOverdue ? AppColors.error : AppColors.savings,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionsPreview(
    WidgetRef ref,
    String currencySymbol,
    AsyncValue<List<Subscription>> activeSubs,
  ) {
    final activeCount = activeSubs.value?.length ?? 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your Subscriptions', style: AppTypography.h3),
                  Text(
                    '$activeCount ${activeCount == 1 ? 'active subscription' : 'active subscriptions'}',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => _showAddSubscription(context),
                style: TextButton.styleFrom(foregroundColor: AppColors.savings),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Add New'),
              ),
            ],
          ),
        ),
        // Show top 3 subscriptions
        activeSubs.when(
          data: (subs) {
            final display = subs.take(3).toList();
            if (display.isEmpty) return const SizedBox.shrink();
            return Column(
              children: display
                  .map<Widget>((sub) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: _buildSubscriptionRow(sub, currencySymbol),
                      ))
                  .toList(),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _buildSubscriptionRow(Subscription sub, String currencySymbol) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: sub.colorValue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSizing.radiusMd),
            ),
            child: Icon(_getIcon(sub.icon), color: sub.colorValue, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sub.name, style: AppTypography.labelLarge),
                Text(
                  '$currencySymbol${sub.amount.toStringAsFixed(0)} / ${sub.billingCycleLabel.toLowerCase()}',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            DateFormat('d MMM').format(sub.nextDueDate),
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.folderOpen,
            size: 48,
            color: AppColors.textMuted,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'No categories yet',
            style: AppTypography.h3,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Add your first budget category to get started',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.alertCircle,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Something went wrong',
            style: AppTypography.h3,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            error,
            style: AppTypography.bodyMedium,
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

  void _showAddTransaction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TransactionFormSheet(),
    );
  }

  void _showAddSubscription(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SubscriptionFormSheet(),
    );
  }
}
