import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../models/income_source.dart';
import '../../providers/providers.dart';
import '../../widgets/budget/budget_widgets.dart';
import 'income_form_sheet.dart';

class IncomeScreen extends ConsumerWidget {
  const IncomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomeSources = ref.watch(incomeSourcesProvider);
    final totalProjected = ref.watch(totalProjectedIncomeProvider);
    final totalActual = ref.watch(totalActualIncomeProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Income'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(incomeSourcesProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Summary Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: _buildSummaryCard(totalProjected, totalActual, currencySymbol),
              ),
            ),

            // Section Title
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Text(
                  'Income Sources',
                  style: AppTypography.h3,
                ),
              ),
            ),

            // Income Sources List
            incomeSources.when(
              data: (sources) {
                if (sources.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _buildEmptyState(context, ref),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final source = sources[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _buildIncomeSourceItem(context, ref, source, currencySymbol),
                        );
                      },
                      childCount: sources.length,
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
                child: _buildErrorState(error.toString()),
              ),
            ),

            // Add Button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: _buildAddButton(context, ref),
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

  Widget _buildSummaryCard(double totalProjected, double totalActual, String currencySymbol) {
    final difference = totalActual - totalProjected;
    final isAhead = difference >= 0;

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow('Total Projected', totalProjected, currencySymbol),
          const SizedBox(height: AppSpacing.sm),
          _buildSummaryRow('Total Actual', totalActual, currencySymbol),
          const Divider(height: AppSpacing.lg, color: AppColors.border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Difference',
                style: AppTypography.labelLarge,
              ),
              Row(
                children: [
                  Icon(
                    isAhead ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                    size: 16,
                    color: isAhead ? AppColors.success : AppColors.error,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${isAhead ? '+' : ''}$currencySymbol${difference.toStringAsFixed(0)}',
                    style: AppTypography.amountSmall.copyWith(
                      color: isAhead ? AppColors.success : AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, String currencySymbol) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyMedium),
        Text(
          '$currencySymbol${amount.toStringAsFixed(0)}',
          style: AppTypography.amountSmall,
        ),
      ],
    );
  }

  Widget _buildIncomeSourceItem(
    BuildContext context,
    WidgetRef ref,
    IncomeSource source,
    String currencySymbol,
  ) {
    return Dismissible(
      key: Key(source.id),
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
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmation(context);
      },
      onDismissed: (direction) {
        ref.read(incomeNotifierProvider.notifier).deleteIncomeSource(source.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${source.name} deleted')),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEditSheet(context, ref, source),
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
          child: Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizing.radiusLg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      source.name,
                      style: AppTypography.labelLarge,
                    ),
                    _buildStatusBadge(source),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  source.isRecurring
                      ? '$currencySymbol${source.actual.toStringAsFixed(0)} / $currencySymbol${source.projected.toStringAsFixed(0)}'
                      : '$currencySymbol${source.actual.toStringAsFixed(0)}',
                  style: AppTypography.bodyMedium,
                ),
                if (source.isRecurring) ...[
                  const SizedBox(height: AppSpacing.sm),
                  BudgetProgressBar(
                    projected: source.projected,
                    actual: source.actual,
                    color: AppColors.success,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(IncomeSource source) {
    String label;
    Color color;

    if (!source.isRecurring) {
      // Non-recurring: simple received/pending
      if (source.actual > 0) {
        label = 'Received';
        color = AppColors.success;
      } else {
        label = 'Pending';
        color = AppColors.textMuted;
      }
    } else if (source.actual >= source.projected && source.projected > 0) {
      label = 'Received';
      color = AppColors.success;
    } else if (source.actual > 0) {
      label = 'Partial';
      color = AppColors.warning;
    } else {
      label = 'Pending';
      color = AppColors.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizing.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showAddSheet(context, ref),
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        child: Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizing.radiusLg),
            border: Border.all(
              color: AppColors.border,
              style: BorderStyle.solid,
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.plus, color: AppColors.primary, size: 20),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Add Income Source',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.wallet,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'No income sources yet',
            style: AppTypography.h3,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Add your first income source to start tracking',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: () => _showAddSheet(context, ref),
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('Add Income Source'),
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
          Text(
            error,
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const IncomeFormSheet(),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, IncomeSource source) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IncomeFormSheet(incomeSource: source),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Delete Income Source?'),
            content: const Text(
              'This action cannot be undone. Any transactions linked to this income source will be unlinked.',
            ),
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
