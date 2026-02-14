part of 'analysis_screen.dart';

extension _AnalysisScreenControls on _AnalysisScreenState {
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
                _updateState(() {
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
        borderRadius: BorderRadius.circular(_AnalysisScreenState._pillRadius),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: NeoControlSizing.minHeight,
            minWidth: NeoControlSizing.minWidth,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : idleBg,
            borderRadius:
                BorderRadius.circular(_AnalysisScreenState._pillRadius),
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
}
