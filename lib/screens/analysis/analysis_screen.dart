import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../models/account.dart';
import '../../models/category.dart';
import '../../models/income_source.dart';
import '../../models/month.dart';
import '../../models/transaction.dart';
import '../../providers/providers.dart';
import '../../utils/app_icon_registry.dart';
import '../../utils/errors/error_mapper.dart';
import '../../widgets/charts/donut_chart.dart';
import '../../widgets/common/neo_dropdown_form_field.dart';
import '../../widgets/common/neo_page_components.dart';

part 'analysis_screen_controls.dart';
part 'analysis_screen_modes.dart';
part 'analysis_screen_components.dart';

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  int? _selectedSpendingIndex;
  int? _selectedIncomeIndex;

  static const double _cardRadius = 16;
  static const double _pillRadius = 16;
  static const double _sectionGap = 12;
  static const double _screenPadding = 16;

  NeoPalette get _palette => NeoTheme.of(context);

  bool _isLight(BuildContext context) => NeoTheme.isLight(context);

  Color get _neoAppBg => _palette.appBg;
  Color get _neoSurface1 => _palette.surface1;
  Color get _neoStroke => _palette.stroke;
  Color get _neoTextSecondary => _palette.textSecondary;
  Color get _neoAccent => _palette.accent;

  void _updateState(VoidCallback update) {
    if (!mounted) return;
    setState(update);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(ensureMonthSetupProvider.future);
      final activeMonth = await ref.read(activeMonthProvider.future);
      if (activeMonth == null) return;

      if (ref.read(analysisSelectedMonthIdProvider) == null) {
        await ref
            .read(analysisSelectedMonthIdProvider.notifier)
            .setMonthId(activeMonth.id);
      }
      if (ref.read(analysisSelectedYearProvider) == null) {
        await ref
            .read(analysisSelectedYearProvider.notifier)
            .setYear(activeMonth.startDate.year);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(analysisModeProvider);
    final monthId = ref.watch(analysisSelectedMonthIdProvider) ??
        ref.watch(activeMonthProvider).value?.id;
    final selectedYear = ref.watch(analysisSelectedYearProvider);
    final trendRange = ref.watch(analysisTrendRangeProvider);
    final trendMetric = ref.watch(analysisTrendMetricProvider);
    final userMonths = ref.watch(userMonthsProvider);
    final currency = ref.watch(currencySymbolProvider);

    if (monthId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final categories = ref.watch(categoriesForMonthProvider(monthId));
    final incomes = ref.watch(incomeSourcesForMonthProvider(monthId));
    final monthTransactions = ref.watch(transactionsForMonthProvider(monthId));
    final accountRows = ref.watch(analysisAccountMovementProvider(monthId));
    final trendSeries = ref.watch(analysisTrendSeriesProvider);
    final trendInsights = ref.watch(analysisTrendInsightsProvider);

    return Scaffold(
      backgroundColor: _neoAppBg,
      body: _buildAnalysisBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(categoriesForMonthProvider(monthId));
            ref.invalidate(incomeSourcesForMonthProvider(monthId));
            ref.invalidate(transactionsForMonthProvider(monthId));
            ref.invalidate(analysisAccountMovementProvider(monthId));
            ref.invalidate(analysisTrendMonthsProvider);
            ref.invalidate(analysisTrendSeriesProvider);
            ref.invalidate(analysisTrendInsightsProvider);
          },
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              _screenPadding,
              0,
              _screenPadding,
              AppSpacing.xl + MediaQuery.paddingOf(context).bottom + 92,
            ),
            children: [
              const SizedBox(height: AppSpacing.sm),
              _header(),
              const SizedBox(height: _sectionGap),
              _modeTabs(mode),
              const SizedBox(height: _sectionGap),
              if (mode == AnalysisMode.trends) ...[
                _trendDropdownFilters(
                  trendRange: trendRange,
                  trendMetric: trendMetric,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (trendRange == AnalysisTrendRange.year)
                  _yearChips(userMonths, selectedYear)
                else
                  _monthChips(userMonths, monthId, selectedYear),
              ] else
                _monthChips(userMonths, monthId, selectedYear),
              const SizedBox(height: _sectionGap),
              switch (mode) {
                AnalysisMode.spending => categories.when(
                    data: (list) => _spendingMode(list,
                        monthTransactions.valueOrNull ?? const [], currency),
                    loading: () => _ModeLoading(color: _neoAccent),
                    error: (e, stackTrace) => _ModeError(
                      error:
                          ErrorMapper.toUserMessage(e, stackTrace: stackTrace),
                    ),
                  ),
                AnalysisMode.income => incomes.when(
                    data: (list) => _incomeMode(list,
                        monthTransactions.valueOrNull ?? const [], currency),
                    loading: () => _ModeLoading(color: _neoAccent),
                    error: (e, stackTrace) => _ModeError(
                      error:
                          ErrorMapper.toUserMessage(e, stackTrace: stackTrace),
                    ),
                  ),
                AnalysisMode.accounts => accountRows.when(
                    data: (rows) => _accountsMode(rows, currency),
                    loading: () => _ModeLoading(color: _neoAccent),
                    error: (e, stackTrace) => _ModeError(
                      error:
                          ErrorMapper.toUserMessage(e, stackTrace: stackTrace),
                    ),
                  ),
                AnalysisMode.trends => trendSeries.when(
                    data: (points) => _trendsMode(
                      points: points,
                      metric: trendMetric,
                      insights: trendInsights,
                      currency: currency,
                    ),
                    loading: () => _ModeLoading(color: _neoAccent),
                    error: (e, stackTrace) => _ModeError(
                      error:
                          ErrorMapper.toUserMessage(e, stackTrace: stackTrace),
                    ),
                  ),
              },
            ],
          ),
        ),
      ),
    );
  }
}
