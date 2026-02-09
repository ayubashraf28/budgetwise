import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../providers/providers.dart';

class ManageScreen extends ConsumerWidget {
  const ManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider).valueOrNull ?? const [];
    final dueSoonCount = ref.watch(dueSoonCountProvider);
    final budgetHealth = ref.watch(budgetHealthProvider);

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
              const Text('Manage', style: AppTypography.h2),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Budgets, subscriptions, and accounts',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _ManageCard(
                title: 'Budgets',
                subtitle: budgetHealth,
                icon: LucideIcons.pieChart,
                iconColor: AppColors.primaryLight,
                onTap: () => context.push('/budget'),
              ),
              const SizedBox(height: AppSpacing.sm),
              _ManageCard(
                title: 'Subscriptions',
                subtitle: dueSoonCount > 0
                    ? '$dueSoonCount due soon'
                    : 'No upcoming dues',
                icon: LucideIcons.repeat,
                iconColor: AppColors.warning,
                onTap: () => context.push('/subscriptions'),
              ),
              const SizedBox(height: AppSpacing.sm),
              _ManageCard(
                title: 'Accounts',
                subtitle: '${accounts.length} accounts',
                icon: LucideIcons.wallet,
                iconColor: AppColors.savings,
                onTap: () => context.push('/settings/accounts'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManageCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _ManageCard({
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
