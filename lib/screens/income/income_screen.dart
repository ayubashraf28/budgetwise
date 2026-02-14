import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../models/income_source.dart';
import '../../providers/providers.dart';
import '../../utils/errors/error_mapper.dart';
import '../../widgets/budget/budget_widgets.dart';
import '../../widgets/common/neo_page_components.dart';
import 'income_form_sheet.dart';

class IncomeScreen extends ConsumerWidget {
  const IncomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = NeoTheme.of(context);
    final incomeSources = ref.watch(incomeSourcesProvider);
    final totalProjected = ref.watch(totalProjectedIncomeProvider);
    final totalActual = ref.watch(totalActualIncomeProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      backgroundColor: palette.appBg,
      body: NeoPageBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(incomeSourcesProvider);
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
                  child: _buildHeader(context),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: NeoLayout.screenPadding,
                  ),
                  child: _buildSummaryCard(
                      context, totalProjected, totalActual, currencySymbol),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    NeoLayout.screenPadding,
                    NeoLayout.sectionGap,
                    NeoLayout.screenPadding,
                    AppSpacing.sm,
                  ),
                  child: AdaptiveHeadingText(
                    text: 'Income Sources',
                  ),
                ),
              ),
              ...incomeSources.when(
                data: (sources) {
                  if (sources.isEmpty) {
                    return <Widget>[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: NeoLayout.screenPadding,
                          ),
                          child: _buildEmptyState(context, ref),
                        ),
                      ),
                    ];
                  }

                  return <Widget>[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          NeoLayout.screenPadding,
                          0,
                          NeoLayout.screenPadding,
                          AppSpacing.sm,
                        ),
                        child: _buildAddIncomeSourceRow(
                          context: context,
                          onTap: () => _showAddSheet(context, ref),
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
                            final source = sources[index];
                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: _buildIncomeSourceItem(
                                context,
                                ref,
                                source,
                                currencySymbol,
                              ),
                            );
                          },
                          childCount: sources.length,
                        ),
                      ),
                    ),
                  ];
                },
                loading: () => <Widget>[
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 280,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                ],
                error: (error, stack) => <Widget>[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: NeoLayout.screenPadding,
                      ),
                      child: _buildErrorState(
                        context,
                        ErrorMapper.toUserMessage(error, stackTrace: stack),
                      ),
                    ),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: AppSpacing.xl +
                      MediaQuery.paddingOf(context).bottom +
                      NeoLayout.bottomNavSafeBuffer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Income', style: NeoTypography.pageTitle(context)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Track projected and actual income sources',
                  style: NeoTypography.pageContext(context),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: NeoSettingsHeaderButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddIncomeSourceRow({
    required BuildContext context,
    required VoidCallback onTap,
  }) {
    final addColor = NeoTheme.positiveValue(context);
    final borderColor = NeoTheme.of(context).stroke;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        child: Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizing.radiusLg),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.plus, color: addColor, size: NeoIconSizes.lg),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Add Income Source',
                style: AppTypography.bodyLarge.copyWith(
                  color: addColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    double totalProjected,
    double totalActual,
    String currencySymbol,
  ) {
    final difference = totalActual - totalProjected;
    final isAhead = difference >= 0;
    final deltaColor = isAhead
        ? NeoTheme.positiveValue(context)
        : NeoTheme.negativeValue(context);

    Widget summaryRow(String label, double amount) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: NeoTypography.rowSecondary(context)),
          Text(
            '$currencySymbol${_formatAmount(amount)}',
            style: NeoTypography.rowAmount(
                context, NeoTheme.of(context).textPrimary),
          ),
        ],
      );
    }

    return NeoGlassCard(
      child: Column(
        children: [
          summaryRow('Total projected', totalProjected),
          const SizedBox(height: AppSpacing.sm),
          summaryRow('Total actual', totalActual),
          Divider(
            height: AppSpacing.lg,
            color: NeoTheme.of(context).stroke.withValues(alpha: 0.85),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Difference', style: NeoTypography.cardTitle(context)),
              Row(
                children: [
                  Icon(
                    isAhead ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                    size: NeoIconSizes.md,
                    color: deltaColor,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${isAhead ? '+' : '-'}$currencySymbol${_formatAmount(difference.abs())}',
                    style: NeoTypography.rowAmount(context, deltaColor),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeSourceItem(
    BuildContext context,
    WidgetRef ref,
    IncomeSource source,
    String currencySymbol,
  ) {
    final palette = NeoTheme.of(context);

    return Dismissible(
      key: Key(source.id),
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
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmation(context);
      },
      onDismissed: (direction) {
        ref.read(incomeNotifierProvider.notifier).deleteIncomeSource(source.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${source.name} deleted')),
        );
      },
      child: InkWell(
        onTap: () => _showEditSheet(context, ref, source),
        borderRadius: BorderRadius.circular(NeoLayout.cardRadius),
        child: NeoGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                      LucideIcons.trendingUp,
                      size: NeoIconSizes.lg,
                      color: NeoTheme.positiveValue(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      source.name,
                      style: NeoTypography.rowTitle(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusBadge(context, source),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                source.isRecurring
                    ? '$currencySymbol${_formatAmount(source.actual)} / $currencySymbol${_formatAmount(source.projected)}'
                    : '$currencySymbol${_formatAmount(source.actual)}',
                style: NeoTypography.rowSecondary(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (source.isRecurring) ...[
                const SizedBox(height: AppSpacing.sm),
                BudgetProgressBar(
                  projected: source.projected,
                  actual: source.actual,
                  color: NeoTheme.positiveValue(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, IncomeSource source) {
    String label;
    Color color;

    if (!source.isRecurring) {
      if (source.actual > 0) {
        label = 'Received';
        color = NeoTheme.positiveValue(context);
      } else {
        label = 'Pending';
        color = NeoTheme.of(context).textMuted;
      }
    } else if (source.actual >= source.projected && source.projected > 0) {
      label = 'Received';
      color = NeoTheme.positiveValue(context);
    } else if (source.actual > 0) {
      label = 'Partial';
      color = NeoTheme.warningValue(context);
    } else {
      label = 'Pending';
      color = NeoTheme.of(context).textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSizing.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
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
                LucideIcons.wallet,
                size: NeoIconSizes.xl,
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('No income sources yet',
                style: NeoTypography.rowTitle(context)),
            const SizedBox(height: 2),
            Text(
              'Add your first income source to start tracking.',
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
              label: const Text('Add income source'),
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
          'Failed to load income sources: $error',
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

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const IncomeFormSheet(),
    );
  }

  void _showEditSheet(
      BuildContext context, WidgetRef ref, IncomeSource source) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IncomeFormSheet(incomeSource: source),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    final palette = NeoTheme.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: palette.surface1,
            title: Text(
              'Delete Income Source?',
              style: AppTypography.h3.copyWith(color: palette.textPrimary),
            ),
            content: Text(
              'This action cannot be undone. Any transactions linked to this income source will be unlinked.',
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
