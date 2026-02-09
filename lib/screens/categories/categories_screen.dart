import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../providers/providers.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseCategories =
        ref.watch(categoriesProvider).valueOrNull ?? const [];
    final incomeSources =
        ref.watch(incomeSourcesProvider).valueOrNull ?? const [];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Categories', style: AppTypography.h2),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Manage how transactions are organized',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _CategoryHubCard(
                title: 'Expense categories',
                subtitle: '${expenseCategories.length} categories',
                icon: LucideIcons.pieChart,
                iconColor: AppColors.expense,
                onTap: () => context.push('/budget'),
              ),
              const SizedBox(height: AppSpacing.sm),
              _CategoryHubCard(
                title: 'Income categories',
                subtitle: '${incomeSources.length} income sources',
                icon: LucideIcons.trendingUp,
                iconColor: AppColors.income,
                onTap: () => context.push('/income'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryHubCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _CategoryHubCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSizing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizing.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.labelLarge),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTypography.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                LucideIcons.chevronRight,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
