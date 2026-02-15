part of 'home_screen.dart';

extension _HomeScreenHeaderOverview on _HomeScreenState {
  Widget _buildHomeBackground({required Widget child}) {
    final textureColor = _isLightMode(context)
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
              colors: [
                _neoAppBg,
                _neoAppBg,
              ],
            ),
          ),
        ),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.85, -0.95),
                radius: 1.25,
                colors: [
                  textureColor,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _buildTopHeader(AsyncValue<UserProfile?> profile) {
    final now = DateTime.now();
    final weekday = DateFormat('EEEE').format(now);
    final dateText = DateFormat('d MMMM').format(now);
    final rawName = profile.maybeWhen(
      data: (p) => p?.displayName,
      orElse: () => null,
    );
    final displayName =
        (rawName is String && rawName.trim().isNotEmpty) ? rawName.trim() : 'U';
    final profileInitial = displayName[0].toUpperCase();
    final unreadNotifications = ref.watch(unreadNotificationCountProvider);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildProfileHeaderButton(
              initial: profileInitial,
              onTap: () => context.push('/settings/profile'),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    weekday,
                    style: AppTypography.bodyLarge.copyWith(
                      color: _neoTextPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      height: 1.15,
                    ),
                  ),
                  Text(
                    dateText,
                    style: AppTypography.bodySmall.copyWith(
                      color: _neoTextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _buildHeaderIconButton(
              icon: _quickThemeToggleIcon(),
              onTap: _toggleThemeQuick,
            ),
            const SizedBox(width: AppSpacing.sm),
            _buildHeaderIconButton(
              icon: LucideIcons.bell,
              badgeCount: unreadNotifications,
              onTap: () => context.push('/notifications'),
            ),
            const SizedBox(width: AppSpacing.sm),
            _buildHeaderIconButton(
              icon: LucideIcons.settings,
              onTap: () => context.push('/settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeaderButton({
    required String initial,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizing.radiusFull),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _neoSurface2,
          shape: BoxShape.circle,
          border: Border.all(color: _neoStroke),
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: AppTypography.bodyMedium.copyWith(
            color: _neoTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizing.radiusLg),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _neoSurface2,
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                border: Border.all(color: _neoStroke),
              ),
              child: Icon(
                icon,
                size: NeoIconSizes.lg,
                color: _neoTextSecondary,
              ),
            ),
            if (badgeCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: _warningColor,
                    borderRadius: BorderRadius.circular(AppSizing.radiusFull),
                    border: Border.all(color: _neoAppBg, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _quickThemeToggleIcon() {
    return _isLightMode(context) ? LucideIcons.moon : LucideIcons.sun;
  }

  Future<void> _toggleThemeQuick() async {
    HapticFeedback.selectionClick();
    final isLight = _isLightMode(context);
    final nextMode = isLight ? ThemeMode.dark : ThemeMode.light;
    await setThemeModePreference(ref, nextMode);
  }

  Widget _buildOverviewHero(
    MonthlySummary? summary,
    String currencySymbol,
    double actualIncome,
    double actualExpenses,
    double netWorth,
    String monthScopeLabel,
    bool isAmountsVisible,
  ) {
    final textScale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(0.85, 1.3).toDouble();
    final monthlyCashflow = summary?.actualBalance ?? 0.0;
    final monthScopeText = monthScopeLabel;
    final cashflowIsPositive = monthlyCashflow >= 0;
    final netWorthIsPositive = netWorth >= 0;
    final cashflowLightAccent = cashflowIsPositive
        ? _hsl(185.0, 0.70, 0.27)
        : _hsl(350.5, 0.504, 0.443);
    final cashflowDarkAccent = cashflowIsPositive
        ? _hsl(173.8, 0.743, 0.403)
        : _hsl(354.5, 1.0, 0.678);
    final netWorthLightAccent = netWorthIsPositive
        ? _hsl(207.0, 0.52, 0.31)
        : _hsl(350.5, 0.504, 0.443);
    final netWorthDarkAccent =
        netWorthIsPositive ? _hsl(196.0, 0.58, 0.73) : _hsl(354.5, 1.0, 0.678);
    final netWorthGradient = netWorthIsPositive
        ? <Color>[
            _neoBlueCardStart.withValues(alpha: 0.88),
            _neoBlueCardEnd.withValues(alpha: 0.86),
          ]
        : <Color>[_neoExpenseCardStart, _neoExpenseCardEnd];

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: _HomeScreenState._homeHorizontalPadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
          final cardHeight = (cardWidth * (0.80 + (textScale - 1.0) * 0.20))
              .clamp(118.0, 158.0);
          final amountFontSize = (cardWidth * 0.26).clamp(32.0, 42.0);
          final headerHeight = (cardHeight * 0.36).clamp(38.0, 56.0);
          final footerHeight = (cardHeight * 0.22).clamp(20.0, 32.0);

          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: AdaptiveHeadingText(
                      text: 'Overview',
                      style: _sectionTitleStyle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      ref
                          .read(uiPreferencesProvider.notifier)
                          .setHideSensitiveAmounts(isAmountsVisible);
                    },
                    borderRadius: BorderRadius.circular(AppSizing.radiusFull),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _neoSurface2,
                        shape: BoxShape.circle,
                        border: Border.all(color: _neoStroke),
                      ),
                      child: Icon(
                        isAmountsVisible ? LucideIcons.eye : LucideIcons.eyeOff,
                        size: NeoIconSizes.md,
                        color: _neoTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      title: 'Monthly Net',
                      cornerLabel: monthScopeText,
                      amount: monthlyCashflow,
                      isAmountVisible: isAmountsVisible,
                      currencySymbol: currencySymbol,
                      icon: LucideIcons.arrowLeftRight,
                      lightAccent: cashflowLightAccent,
                      darkAccent: cashflowDarkAccent,
                      gradientColors: cashflowIsPositive
                          ? <Color>[_neoBlueCardStart, _neoBlueCardEnd]
                          : <Color>[_neoExpenseCardStart, _neoExpenseCardEnd],
                      footerIcon: cashflowIsPositive
                          ? LucideIcons.trendingUp
                          : LucideIcons.trendingDown,
                      footerLabel: cashflowIsPositive
                          ? 'Positive this month'
                          : 'Negative this month',
                      amountFontSize: amountFontSize,
                      cardHeight: cardHeight,
                      headerHeight: headerHeight,
                      footerHeight: footerHeight,
                      onTap: () => context.push('/transactions'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildKpiCard(
                      title: 'Net worth',
                      amount: netWorth,
                      isAmountVisible: isAmountsVisible,
                      currencySymbol: currencySymbol,
                      icon: LucideIcons.pieChart,
                      lightAccent: netWorthLightAccent,
                      darkAccent: netWorthDarkAccent,
                      gradientColors: netWorthGradient,
                      footerIcon: netWorthIsPositive
                          ? LucideIcons.shieldCheck
                          : LucideIcons.alertTriangle,
                      footerLabel: 'Across included accounts',
                      amountFontSize: amountFontSize,
                      cardHeight: cardHeight,
                      headerHeight: headerHeight,
                      footerHeight: footerHeight,
                      onTap: () => context.push('/settings/accounts'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      title: 'Income',
                      cornerLabel: monthScopeText,
                      amount: actualIncome,
                      isAmountVisible: isAmountsVisible,
                      currencySymbol: currencySymbol,
                      icon: LucideIcons.trendingUp,
                      lightAccent: _hsl(154.4, 0.794, 0.267),
                      darkAccent: _hsl(151.9, 0.726, 0.527),
                      gradientColors: <Color>[
                        _neoIncomeCardStart,
                        _neoIncomeCardEnd,
                      ],
                      footerIcon: LucideIcons.badgeCheck,
                      footerLabel: 'Received this month',
                      amountFontSize: amountFontSize,
                      cardHeight: cardHeight,
                      headerHeight: headerHeight,
                      footerHeight: footerHeight,
                      onTap: () => context.push('/income'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildKpiCard(
                      title: 'Expenses',
                      cornerLabel: monthScopeText,
                      amount: actualExpenses,
                      isAmountVisible: isAmountsVisible,
                      currencySymbol: currencySymbol,
                      icon: LucideIcons.trendingDown,
                      lightAccent: _hsl(350.5, 0.504, 0.443),
                      darkAccent: _hsl(354.5, 1.0, 0.678),
                      gradientColors: <Color>[
                        _neoExpenseCardStart,
                        _neoExpenseCardEnd,
                      ],
                      footerIcon: LucideIcons.receipt,
                      footerLabel: 'Spent this month',
                      amountFontSize: amountFontSize,
                      cardHeight: cardHeight,
                      headerHeight: headerHeight,
                      footerHeight: footerHeight,
                      onTap: () => context.push('/expenses'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: _HomeScreenState._homeSectionSpacing),
            ],
          );
        },
      ),
    );
  }
}
