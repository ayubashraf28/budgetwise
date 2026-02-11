import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../models/category.dart';
import '../../models/income_source.dart';
import '../../models/month.dart';
import '../../models/transaction.dart';
import '../../providers/providers.dart';
import '../../utils/app_icon_registry.dart';
import '../../widgets/charts/donut_chart.dart';
import '../../widgets/common/neo_dropdown_form_field.dart';
import '../../widgets/common/neo_page_components.dart';

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  int? _selectedSpendingIndex;
  int? _selectedIncomeIndex;

  static const double _cardRadius = 16;
  static const double _sectionGap = 12;
  static const double _screenPadding = 16;

  NeoPalette get _palette => NeoTheme.of(context);

  bool _isLight(BuildContext context) => NeoTheme.isLight(context);

  Color get _neoAppBg => _palette.appBg;
  Color get _neoSurface1 => _palette.surface1;
  Color get _neoStroke => _palette.stroke;
  Color get _neoTextSecondary => _palette.textSecondary;
  Color get _neoAccent => _palette.accent;

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
                    error: (e, _) => _ModeError(error: e.toString()),
                  ),
                AnalysisMode.income => incomes.when(
                    data: (list) => _incomeMode(list,
                        monthTransactions.valueOrNull ?? const [], currency),
                    loading: () => _ModeLoading(color: _neoAccent),
                    error: (e, _) => _ModeError(error: e.toString()),
                  ),
                AnalysisMode.accounts => accountRows.when(
                    data: (rows) => _accountsMode(rows, currency),
                    loading: () => _ModeLoading(color: _neoAccent),
                    error: (e, _) => _ModeError(error: e.toString()),
                  ),
                AnalysisMode.trends => trendSeries.when(
                    data: (points) => _trendsMode(
                      points: points,
                      metric: trendMetric,
                      insights: trendInsights,
                      currency: currency,
                    ),
                    loading: () => _ModeLoading(color: _neoAccent),
                    error: (e, _) => _ModeError(error: e.toString()),
                  ),
              },
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
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
                  'Analysis',
                  style: NeoTypography.pageTitle(context),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Spending, income, account movement, and trends in one place',
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

  Widget _buildAnalysisBackground({required Widget child}) {
    final textureColor = _isLight(context)
        ? Colors.black.withValues(alpha: 0.018)
        : Colors.white.withValues(alpha: 0.025);
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_neoAppBg, _neoAppBg],
            ),
          ),
        ),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.85, -0.95),
                radius: 1.25,
                colors: [textureColor, Colors.transparent],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _modeTabs(AnalysisMode selected) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: AnalysisMode.values.map((mode) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _pill(
              label: mode.label,
              isSelected: mode == selected,
              onTap: () async {
                await ref.read(analysisModeProvider.notifier).setMode(mode);
                if (!mounted) return;
                setState(() {
                  _selectedSpendingIndex = null;
                  _selectedIncomeIndex = null;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _trendDropdownFilters({
    required AnalysisTrendRange trendRange,
    required AnalysisTrendMetric trendMetric,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 390;
        final rangeDropdown = _trendDropdown<AnalysisTrendRange>(
          value: trendRange,
          items: AnalysisTrendRange.values,
          labelBuilder: (value) => value.label,
          onSelected: (value) async {
            await ref.read(analysisTrendRangeProvider.notifier).setRange(value);
          },
        );
        final metricDropdown = _trendDropdown<AnalysisTrendMetric>(
          value: trendMetric,
          items: AnalysisTrendMetric.values,
          labelBuilder: (value) => value.label,
          onSelected: (value) async {
            await ref
                .read(analysisTrendMetricProvider.notifier)
                .setMetric(value);
          },
        );

        if (isCompact) {
          return Column(
            children: [
              rangeDropdown,
              const SizedBox(height: AppSpacing.sm),
              metricDropdown,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: rangeDropdown),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: metricDropdown),
          ],
        );
      },
    );
  }

  Widget _trendDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T value) labelBuilder,
    required Future<void> Function(T value) onSelected,
  }) {
    return NeoDropdownFormField<T>(
      value: value,
      hintText: 'Select',
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(
                labelBuilder(item),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (next) async {
        if (next == null || next == value) return;
        await onSelected(next);
      },
    );
  }

  Widget _monthChips(
      AsyncValue<List<Month>> userMonths, String monthId, int? selectedYear) {
    return userMonths.when(
      data: (months) {
        final selected = months.where((m) => m.id == monthId).firstOrNull;
        final year = selectedYear ?? selected?.startDate.year;
        final visible = months.where((m) => m.startDate.year == year).toList()
          ..sort((a, b) => a.startDate.compareTo(b.startDate));
        if (visible.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: visible.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, i) {
              final m = visible[i];
              return _pill(
                label: m.name.substring(0, 3),
                isSelected: m.id == monthId,
                onTap: () => _selectMonth(m.id, m.startDate.year),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
          height: 44,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _yearChips(AsyncValue<List<Month>> userMonths, int? selectedYear) {
    return userMonths.when(
      data: (months) {
        final years = months.map((m) => m.startDate.year).toSet().toList()
          ..sort();
        if (years.isEmpty) return const SizedBox.shrink();
        final year = selectedYear ?? years.last;
        return SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: years.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, i) {
              final y = years[i];
              return _pill(
                label: '$y',
                isSelected: y == year,
                onTap: () async {
                  await ref
                      .read(analysisSelectedYearProvider.notifier)
                      .setYear(y);
                },
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
          height: 44,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _selectMonth(String monthId, int year) async {
    await ref
        .read(analysisSelectedMonthIdProvider.notifier)
        .setMonthId(monthId);
    await ref.read(analysisSelectedYearProvider.notifier).setYear(year);
  }

  Widget _pill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final selectedBg = NeoTheme.controlSelectedBackground(context);
    final selectedFg = NeoTheme.controlSelectedForeground(context);
    final idleBg = NeoTheme.controlIdleBackground(context);
    final idleFg = NeoTheme.controlIdleForeground(context);
    final idleBorder = NeoTheme.controlIdleBorder(context);
    final selectedBorder = NeoTheme.controlSelectedBorder(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(NeoControlSizing.radius),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: NeoControlSizing.minHeight,
            minWidth: NeoControlSizing.minWidth,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : idleBg,
            borderRadius: BorderRadius.circular(NeoControlSizing.radius),
            border: Border.all(
              color: isSelected ? selectedBorder : idleBorder,
            ),
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: NeoTypography.chipLabel(context, isSelected: isSelected)
                  .copyWith(color: isSelected ? selectedFg : idleFg),
            ),
          ),
        ),
      ),
    );
  }

  Widget _spendingMode(
      List<Category> categories, List<Transaction> txs, String currency) {
    final list = categories.where((c) => c.totalActual > 0).toList()
      ..sort((a, b) => b.totalActual.compareTo(a.totalActual));
    final total = list.fold<double>(0, (sum, c) => sum + c.totalActual);
    if (list.isEmpty || total <= 0) {
      return _emptyCard(
        title: 'No spending yet this month',
        subtitle:
            'Add your first expense transaction to unlock spending insights.',
      );
    }

    final counts = <String, int>{};
    for (final t in txs) {
      if (t.type == TransactionType.expense && t.categoryId != null) {
        counts[t.categoryId!] = (counts[t.categoryId!] ?? 0) + 1;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          title: 'Spending by category',
          child: DonutChart(
            segments: list
                .map((c) => DonutSegment(
                    color: c.colorValue,
                    value: c.totalActual,
                    name: c.name,
                    icon: c.icon))
                .toList(),
            total: total,
            height: 248,
            initialSelectedIndex: _selectedSpendingIndex,
            onSelectionChanged: (i) =>
                setState(() => _selectedSpendingIndex = i),
            centerBuilder: (i) {
              final selected = i != null && i < list.length ? list[i] : null;
              final amount = selected?.totalActual ?? total;
              final label = selected?.name ?? 'Total spending';
              return _ChartCenter(
                icon: selected != null
                    ? _categoryIcon(selected.icon)
                    : LucideIcons.pieChart,
                iconColor:
                    selected?.colorValue ?? NeoTheme.positiveValue(context),
                amount: '$currency${_money(amount)}',
                label: label,
                meta: selected == null
                    ? '${list.length} categories'
                    : '${(amount / total * 100).toStringAsFixed(0)}%',
              );
            },
          ),
        ),
        const SizedBox(height: _sectionGap),
        const AdaptiveHeadingText(text: 'Top categories'),
        const SizedBox(height: 8),
        ...list.map((c) {
          final amount = c.totalActual;
          final pct = amount / total * 100;
          return _RowCard(
            title: c.name,
            subtitle: '${counts[c.id] ?? 0} transactions',
            leadingColor: c.colorValue,
            leadingIcon: _categoryIcon(c.icon),
            amount: '$currency${_money(amount)}',
            meta: '${pct.toStringAsFixed(0)}%',
            onTap: () => context.push('/budget/category/${c.id}'),
          );
        }),
      ],
    );
  }

  Widget _incomeMode(
      List<IncomeSource> sources, List<Transaction> txs, String currency) {
    final categoryPalette = NeoTheme.categoryChartPalette(context);
    final paletteLength = categoryPalette.length;
    final list = sources.where((s) => s.actual > 0).toList()
      ..sort((a, b) => b.actual.compareTo(a.actual));
    final total = list.fold<double>(0, (sum, s) => sum + s.actual);
    if (list.isEmpty || total <= 0) {
      return _emptyCard(
        title: 'No income yet this month',
        subtitle: 'Add an income transaction to see source-level breakdowns.',
      );
    }

    final counts = <String, int>{};
    for (final t in txs) {
      if (t.type == TransactionType.income && t.incomeSourceId != null) {
        counts[t.incomeSourceId!] = (counts[t.incomeSourceId!] ?? 0) + 1;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          title: 'Income by source',
          child: DonutChart(
            segments: list
                .asMap()
                .entries
                .map((e) => DonutSegment(
                    color: categoryPalette[e.key % paletteLength],
                    value: e.value.actual,
                    name: e.value.name))
                .toList(),
            total: total,
            height: 248,
            initialSelectedIndex: _selectedIncomeIndex,
            onSelectionChanged: (i) => setState(() => _selectedIncomeIndex = i),
            centerBuilder: (i) {
              final selected = i != null && i < list.length ? list[i] : null;
              final amount = selected?.actual ?? total;
              return _ChartCenter(
                icon: LucideIcons.banknote,
                iconColor: selected == null
                    ? NeoTheme.positiveValue(context)
                    : categoryPalette[i! % paletteLength],
                amount: '$currency${_money(amount)}',
                label: selected?.name ?? 'Total income',
                meta: selected == null
                    ? '${list.length} sources'
                    : '${(amount / total * 100).toStringAsFixed(0)}%',
              );
            },
          ),
        ),
        const SizedBox(height: _sectionGap),
        const AdaptiveHeadingText(text: 'Top income sources'),
        const SizedBox(height: 8),
        ...list.asMap().entries.map((e) {
          final s = e.value;
          final pct = s.actual / total * 100;
          return _RowCard(
            title: s.name,
            subtitle: '${counts[s.id] ?? 0} transactions',
            leadingColor: categoryPalette[e.key % paletteLength],
            leadingIcon: LucideIcons.banknote,
            amount: '$currency${_money(s.actual)}',
            meta: '${pct.toStringAsFixed(0)}%',
            onTap: () => context.push('/transactions'),
          );
        }),
      ],
    );
  }

  Widget _accountsMode(List<AccountMovementSummary> rows, String currency) {
    if (rows.isEmpty) {
      return _emptyCard(
        title: 'No account movement this month',
        subtitle:
            'Add income or expense transactions with accounts to see movement by account.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          title: 'Account movement (income vs expense)',
          child: Column(
            children: [
              _AccountsChart(rows: rows, currency: currency),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LegendDot(
                    color: NeoTheme.positiveValue(context),
                    label: 'Income',
                  ),
                  SizedBox(width: 12),
                  _LegendDot(
                    color: NeoTheme.negativeValue(context),
                    label: 'Expense',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: _sectionGap),
        const AdaptiveHeadingText(text: 'Account breakdown'),
        const SizedBox(height: 8),
        ...rows.map((r) {
          final netPositive = r.net >= 0;
          return _RowCard(
            title: r.accountName,
            subtitle: '${r.transactionCount} transactions',
            leadingColor: netPositive
                ? NeoTheme.positiveValue(context)
                : NeoTheme.negativeValue(context),
            amount: '${r.net >= 0 ? '+' : '-'}$currency${_money(r.net.abs())}',
            meta:
                '+$currency${_money(r.income)}  /  -$currency${_money(r.expense)}',
            onTap: () {
              if (r.isUnassigned) {
                context.push('/transactions');
                return;
              }
              context.push(
                  '/settings/accounts?accountId=${Uri.encodeComponent(r.accountId)}');
            },
          );
        }),
      ],
    );
  }

  Widget _trendsMode({
    required List<TrendPoint> points,
    required AnalysisTrendMetric metric,
    required TrendInsights? insights,
    required String currency,
  }) {
    if (points.isEmpty) {
      return _emptyCard(
        title: 'No trend data yet',
        subtitle: 'Add transactions across months to unlock trend insights.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          title: 'Monthly ${metric.label.toLowerCase()} trend',
          child:
              _TrendChart(points: points, metric: metric, currency: currency),
        ),
        const SizedBox(height: AppSpacing.md),
        const AdaptiveHeadingText(text: 'Insights'),
        const SizedBox(height: 8),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _Insight(
                title: 'Highest spending month',
                value: insights?.highestSpendingMonthLabel ?? 'N/A'),
            _Insight(
                title: 'Average monthly expense',
                value:
                    '$currency${_money(insights?.averageMonthlyExpense ?? 0)}'),
            _Insight(
              title: 'Month-over-month',
              value: insights == null || !insights.hasMonthOverMonthDelta
                  ? 'Need 2+ months'
                  : '${insights.monthOverMonthDelta >= 0 ? '+' : '-'}$currency${_money(insights.monthOverMonthDelta.abs())}',
            ),
          ],
        ),
      ],
    );
  }

  Widget _card({required String title, required Widget child}) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: NeoTypography.cardTitle(context),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _emptyCard({required String title, required String subtitle}) {
    return _card(
      title: title,
      child: Text(
        subtitle,
        style: AppTypography.bodyMedium.copyWith(
          color: _neoTextSecondary,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    final shadowColor = _isLight(context)
        ? Colors.black.withValues(alpha: 0.08)
        : _neoAppBg.withValues(alpha: 0.86);
    final strokeColor =
        _isLight(context) ? _neoStroke.withValues(alpha: 0.75) : _neoStroke;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _neoSurface1,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: strokeColor),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  String _money(double amount) {
    if (amount == amount.roundToDouble()) {
      return NumberFormat('#,##0').format(amount);
    }
    return NumberFormat('#,##0.##').format(amount);
  }

  IconData _categoryIcon(String iconName) {
    return resolveAppIcon(iconName, fallback: LucideIcons.wallet);
  }
}

class _RowCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color leadingColor;
  final IconData? leadingIcon;
  final String amount;
  final String meta;
  final VoidCallback onTap;

  const _RowCard({
    required this.title,
    required this.subtitle,
    required this.leadingColor,
    this.leadingIcon,
    required this.amount,
    required this.meta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);
    final isLight = NeoTheme.isLight(context);
    final surface = isLight ? palette.surface1 : palette.surface2;
    final stroke = isLight
        ? palette.stroke.withValues(alpha: 0.75)
        : palette.stroke.withValues(alpha: 0.9);
    final cardShadow =
        isLight ? Colors.black.withValues(alpha: 0.06) : Colors.transparent;
    final textPrimary = palette.textPrimary;
    final textSecondary = palette.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: stroke),
              boxShadow: [
                BoxShadow(
                  color: cardShadow,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color:
                        leadingColor.withValues(alpha: isLight ? 0.14 : 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: leadingIcon != null
                        ? Icon(
                            leadingIcon,
                            size: 18,
                            color: leadingColor,
                          )
                        : Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: leadingColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelLarge.copyWith(
                            color: textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          )),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amount,
                      style: AppTypography.amountSmall.copyWith(
                        color: textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      style: AppTypography.bodySmall.copyWith(
                        color: textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartCenter extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String amount;
  final String label;
  final String meta;

  const _ChartCenter({
    this.icon,
    this.iconColor,
    required this.amount,
    required this.label,
    required this.meta,
  });

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);
    final textPrimary = palette.textPrimary;
    final textSecondary = palette.textSecondary;

    return SizedBox(
      width: 164,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: iconColor ?? textPrimary,
            ),
            const SizedBox(height: 6),
          ],
          Text(
            amount,
            style: AppTypography.amountSmall.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 17,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            meta,
            style: AppTypography.bodySmall.copyWith(
              color: textSecondary,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Insight extends StatelessWidget {
  final String title;
  final String value;

  const _Insight({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);
    final isLight = NeoTheme.isLight(context);
    final surface = isLight ? palette.surface1 : palette.surface2;
    final stroke =
        isLight ? palette.stroke.withValues(alpha: 0.75) : palette.stroke;
    final textPrimary = palette.textPrimary;
    final textSecondary = palette.textSecondary;

    return Container(
      constraints: const BoxConstraints(minWidth: 170),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.labelMedium.copyWith(
              color: textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountsChart extends StatelessWidget {
  final List<AccountMovementSummary> rows;
  final String currency;

  const _AccountsChart({
    required this.rows,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox(height: 220);
    final palette = NeoTheme.of(context);
    final positive = NeoTheme.positiveValue(context);
    final negative = NeoTheme.negativeValue(context);
    final muted = palette.textSecondary;
    final stroke = palette.stroke;
    final maxValue = rows.fold<double>(
        0, (m, r) => math.max(m, math.max(r.income, r.expense)));
    final maxY = maxValue <= 0 ? 100.0 : maxValue * 1.2;

    return SizedBox(
      height: 210,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: stroke.withValues(alpha: 0.7), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= rows.length) return const SizedBox.shrink();
                  final name = rows[i].accountName;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      name.length > 6 ? '${name.substring(0, 6)}..' : name,
                      style: TextStyle(fontSize: 10, color: muted),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => palette.surface2,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                if (rodIndex == 1) return null;
                final row = rows[group.x.toInt()];
                return BarTooltipItem(
                  '${row.accountName}\n+$currency${_fmt(row.income)}  /  -$currency${_fmt(row.expense)}',
                  TextStyle(color: palette.textPrimary, fontSize: 11),
                );
              },
            ),
          ),
          barGroups: rows.asMap().entries.map((e) {
            final row = e.value;
            return BarChartGroupData(
              x: e.key,
              barsSpace: 4,
              barRods: [
                BarChartRodData(toY: row.income, width: 10, color: positive),
                BarChartRodData(toY: row.expense, width: 10, color: negative),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v == v.roundToDouble()) {
      return NumberFormat('#,##0').format(v);
    }
    return NumberFormat('#,##0.##').format(v);
  }
}

class _TrendChart extends StatelessWidget {
  final List<TrendPoint> points;
  final AnalysisTrendMetric metric;
  final String currency;

  const _TrendChart({
    required this.points,
    required this.metric,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox(height: 240);
    final palette = NeoTheme.of(context);
    final muted = palette.textSecondary;
    final stroke = palette.stroke;
    final values = points.map(_value).toList();
    var minY =
        metric == AnalysisTrendMetric.net ? values.reduce(math.min) : 0.0;
    var maxY = values.reduce(math.max);
    if (metric == AnalysisTrendMetric.net) {
      minY = math.min(minY, 0);
      maxY = math.max(maxY, 0);
    }
    if (maxY == minY) {
      maxY += 50;
      if (metric == AnalysisTrendMetric.net) minY -= 50;
    }
    final color = metric == AnalysisTrendMetric.expense
        ? NeoTheme.negativeValue(context)
        : metric == AnalysisTrendMetric.income
            ? NeoTheme.positiveValue(context)
            : NeoTheme.infoValue(context);

    final includeZeroLine = metric == AnalysisTrendMetric.net;
    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY * 1.2,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: ((maxY - minY) / 4).clamp(1, double.infinity),
            getDrawingHorizontalLine: (_) =>
                FlLine(color: stroke.withValues(alpha: 0.7), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(points[i].monthLabel,
                        style: TextStyle(fontSize: 11, color: muted)),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => palette.surface2,
              getTooltipItems: (spots) => spots.map((s) {
                final p = points[s.x.toInt()];
                final sign =
                    metric == AnalysisTrendMetric.net && s.y < 0 ? '-' : '';
                return LineTooltipItem(
                  '${p.monthLabel} ${p.year}\n$sign$currency${_fmt(s.y.abs())}',
                  TextStyle(color: palette.textPrimary, fontSize: 11),
                );
              }).toList(),
            ),
          ),
          extraLinesData: includeZeroLine
              ? ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: 0,
                      color: stroke.withValues(alpha: 0.9),
                      strokeWidth: 1,
                    ),
                  ],
                )
              : const ExtraLinesData(),
          lineBarsData: [
            LineChartBarData(
              spots: points
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), _value(e.value)))
                  .toList(),
              isCurved: true,
              color: color,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(colors: [
                  color.withValues(alpha: 0.25),
                  color.withValues(alpha: 0.03)
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _value(TrendPoint p) => metric == AnalysisTrendMetric.expense
      ? p.expense
      : metric == AnalysisTrendMetric.income
          ? p.income
          : p.net;

  String _fmt(double v) {
    if (v == v.roundToDouble()) {
      return NumberFormat('#,##0').format(v);
    }
    return NumberFormat('#,##0.##').format(v);
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary = NeoTheme.of(context).textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ModeLoading extends StatelessWidget {
  final Color color;

  const _ModeLoading({required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: CircularProgressIndicator(color: color),
      ),
    );
  }
}

class _ModeError extends StatelessWidget {
  final String error;

  const _ModeError({required this.error});

  @override
  Widget build(BuildContext context) {
    final danger = NeoTheme.negativeValue(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final errorBg = isLight
        ? const HSLColor.fromAHSL(1, 355.7, 0.700, 0.961).toColor()
        : danger.withValues(alpha: 0.12);
    final errorStroke = isLight
        ? const HSLColor.fromAHSL(1, 352.0, 0.634, 0.861).toColor()
        : danger.withValues(alpha: 0.35);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: errorBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: errorStroke),
      ),
      child: Text(
        'Failed to load analysis data: $error',
        style: AppTypography.bodyMedium.copyWith(color: danger),
      ),
    );
  }
}
