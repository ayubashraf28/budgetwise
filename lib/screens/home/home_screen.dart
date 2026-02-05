import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/budget/budget_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeMonth = ref.watch(activeMonthProvider);
    final summary = ref.watch(monthlySummaryProvider);
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeMonthProvider);
          ref.invalidate(categoriesProvider);
          ref.invalidate(incomeSourcesProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Gradient Header
            SliverToBoxAdapter(
              child: _buildHeader(context, ref, activeMonth, summary),
            ),

            // Quick Stats Row
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -AppSpacing.md),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: _buildQuickStats(context, ref, summary),
                ),
              ),
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
                            onTap: () {
                              // Navigate to category detail
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

            // Bottom padding for FAB
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<dynamic> activeMonth,
    dynamic summary,
  ) {
    final monthName = activeMonth.value?.name ?? 'Loading...';

    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppSizing.radiusXl),
          bottomRight: Radius.circular(AppSizing.radiusXl),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month selector row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.calendar,
                        color: Colors.white,
                        size: AppSizing.iconMd,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        monthName,
                        style: AppTypography.h3.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      LucideIcons.settings,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      context.push('/settings');
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Balance Card
              BalanceCard(
                projectedBalance: summary?.projectedBalance ?? 0,
                actualBalance: summary?.actualBalance ?? 0,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(
    BuildContext context,
    WidgetRef ref,
    dynamic summary,
  ) {
    final projectedIncome = summary?.projectedIncome ?? 0.0;
    final actualIncome = summary?.actualIncome ?? 0.0;
    final projectedExpenses = summary?.projectedExpenses ?? 0.0;
    final actualExpenses = summary?.actualExpenses ?? 0.0;

    return Row(
      children: [
        QuickStatCard(
          title: 'Income',
          icon: LucideIcons.trendingUp,
          actual: actualIncome,
          projected: projectedIncome,
          color: AppColors.success,
          onTap: () {
            context.push('/income');
          },
        ),
        const SizedBox(width: AppSpacing.sm),
        QuickStatCard(
          title: 'Expenses',
          icon: LucideIcons.trendingDown,
          actual: actualExpenses,
          projected: projectedExpenses,
          color: AppColors.error,
          onTap: () {
            context.push('/expenses');
          },
        ),
      ],
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
}
