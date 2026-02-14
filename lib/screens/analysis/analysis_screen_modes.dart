part of 'analysis_screen.dart';

extension _AnalysisScreenModes on _AnalysisScreenState {
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
                _updateState(() => _selectedSpendingIndex = i),
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
        const SizedBox(height: _AnalysisScreenState._sectionGap),
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
            onSelectionChanged: (i) =>
                _updateState(() => _selectedIncomeIndex = i),
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
        const SizedBox(height: _AnalysisScreenState._sectionGap),
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
                  const SizedBox(width: 12),
                  _LegendDot(
                    color: NeoTheme.negativeValue(context),
                    label: 'Expense',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: _AnalysisScreenState._sectionGap),
        const AdaptiveHeadingText(text: 'Account breakdown'),
        const SizedBox(height: 8),
        ...rows.map((r) {
          final netPositive = r.net >= 0;
          return _RowCard(
            title: r.accountName,
            subtitle: '${r.transactionCount} transactions',
            leadingIcon: _accountTypeIcon(r.accountType, r.isUnassigned),
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
        borderRadius: BorderRadius.circular(_AnalysisScreenState._cardRadius),
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

  IconData _accountTypeIcon(AccountType type, bool isUnassigned) {
    if (isUnassigned) return LucideIcons.wallet;
    switch (type) {
      case AccountType.cash:
        return LucideIcons.wallet;
      case AccountType.debit:
        return LucideIcons.creditCard;
      case AccountType.credit:
        return LucideIcons.landmark;
      case AccountType.savings:
        return LucideIcons.piggyBank;
      case AccountType.other:
        return LucideIcons.circleDollarSign;
    }
  }
}
