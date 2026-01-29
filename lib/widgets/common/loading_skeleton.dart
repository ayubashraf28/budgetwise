import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../config/theme.dart';

/// Shimmer loading skeleton widget
class LoadingSkeleton extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const LoadingSkeleton({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceLight,
      highlightColor: AppColors.surface,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Loading skeleton for a card-like element
class CardSkeleton extends StatelessWidget {
  final double height;

  const CardSkeleton({
    super.key,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceLight,
      highlightColor: AppColors.surface,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        ),
      ),
    );
  }
}

/// Loading skeleton for list items
class ListItemSkeleton extends StatelessWidget {
  const ListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceLight,
      highlightColor: AppColors.surface,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        ),
        child: Row(
          children: [
            // Icon placeholder
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Text placeholders
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: 80,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            // Amount placeholder
            Container(
              width: 60,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading skeleton for the home dashboard
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          // Balance card skeleton
          const CardSkeleton(height: 180),
          const SizedBox(height: AppSpacing.lg),

          // Quick stats row
          const Row(
            children: [
              Expanded(child: CardSkeleton(height: 80)),
              SizedBox(width: AppSpacing.md),
              Expanded(child: CardSkeleton(height: 80)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Categories section
          const LoadingSkeleton(width: 120, height: 24),
          const SizedBox(height: AppSpacing.md),
          const ListItemSkeleton(),
          const SizedBox(height: AppSpacing.sm),
          const ListItemSkeleton(),
          const SizedBox(height: AppSpacing.sm),
          const ListItemSkeleton(),
        ],
      ),
    );
  }
}

/// Loading skeleton for transaction list
class TransactionListSkeleton extends StatelessWidget {
  final int itemCount;

  const TransactionListSkeleton({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, __) => const ListItemSkeleton(),
    );
  }
}
