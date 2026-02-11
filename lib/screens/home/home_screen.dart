import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../models/account.dart';
import '../../models/subscription.dart';
import '../../models/transaction.dart';
import '../../providers/providers.dart';
import '../../utils/app_icon_registry.dart';
import '../../widgets/charts/donut_chart.dart';
import '../../widgets/charts/stacked_bar_chart.dart';
import '../transactions/transaction_form_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int? _selectedYearlyBarIndex;

  NeoPalette get _palette => NeoTheme.of(context);

  bool _isLightMode(BuildContext context) => NeoTheme.isLight(context);

  Color _hsl(double h, double s, double l) =>
      HSLColor.fromAHSL(1, h, s, l).toColor();

  Color get _neoAppBg => _palette.appBg;
  Color get _neoSurface1 => _palette.surface1;
  Color get _neoSurface2 => _palette.surface2;
  Color get _neoStroke => _palette.stroke;
  Color get _neoTextPrimary => _palette.textPrimary;
  Color get _neoTextSecondary => _palette.textSecondary;
  Color get _neoLime => _palette.accent;
  Color get _neoBlueCardStart => _palette.balanceCardStart;
  Color get _neoBlueCardEnd => _palette.balanceCardEnd;
  Color get _neoExpenseCardStart => _palette.expenseCardStart;
  Color get _neoExpenseCardEnd => _palette.expenseCardEnd;
  Color get _neoIncomeCardStart => _palette.incomeCardStart;
  Color get _neoIncomeCardEnd => _palette.incomeCardEnd;
  Color get _positiveColor => NeoTheme.positiveValue(context);
  Color get _negativeColor => NeoTheme.negativeValue(context);
  Color get _warningColor => NeoTheme.warningValue(context);
  static const double _homeCardRadius = 16;
  static const double _homeHorizontalPadding = AppSpacing.md;
  static const double _homeSectionSpacing = 14;
  static const double _homeRowVerticalPadding = 6;

  TextStyle get _sectionTitleStyle => NeoTypography.sectionTitle(context);

  TextStyle get _sectionActionStyle => NeoTypography.sectionAction(context);

  TextStyle get _rowTitleStyle => NeoTypography.rowTitle(context);

  TextStyle get _rowSecondaryStyle => NeoTypography.rowSecondary(context);

  TextStyle _rowAmountStyle(Color color) =>
      NeoTypography.rowAmount(context, color);

  @override
  void initState() {
    super.initState();
    // Ensure all 12 months exist and current calendar month is active.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ensureMonthSetupProvider.future).then((_) {
        ref.invalidate(activeMonthProvider);
        ref.invalidate(userMonthsProvider);
        ref.invalidate(categoriesProvider);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(monthlySummaryProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final activeMonth = ref.watch(activeMonthProvider).value;
    final profile = ref.watch(userProfileProvider);
    final upcoming = ref.watch(upcomingSubscriptionsProvider);
    final totalActualIncome = ref.watch(totalActualIncomeProvider);
    final totalActualExpenses = ref.watch(totalActualExpensesProvider);
    final netWorth = ref.watch(netWorthProvider).value ?? 0.0;
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final accountBalances =
        ref.watch(allAccountBalancesProvider).value ?? const <String, double>{};
    final transactions = ref.watch(transactionsProvider);
    final hideSensitiveAmounts = ref.watch(hideSensitiveAmountsProvider);
    final isAmountsVisible = !hideSensitiveAmounts;
    final isAccountsExpanded =
        ref.watch(uiSectionExpandedProvider(UiSectionKeys.homeAccounts));
    final isUpcomingExpanded =
        ref.watch(uiSectionExpandedProvider(UiSectionKeys.homeUpcoming));
    final isRecentTransactionsExpanded = ref.watch(
      uiSectionExpandedProvider(UiSectionKeys.homeRecentTransactions),
    );
    final monthScopeLabel = activeMonth != null
        ? DateFormat('MMM yyyy').format(activeMonth.startDate)
        : DateFormat('MMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: _neoAppBg,
      body: _buildHomeBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(activeMonthProvider);
            ref.invalidate(categoriesProvider);
            ref.invalidate(incomeSourcesProvider);
            ref.invalidate(subscriptionsProvider);
            ref.invalidate(yearlyMonthlyExpensesProvider);
            ref.invalidate(transactionsProvider);
            ref.invalidate(allAccountsProvider);
            ref.invalidate(accountsProvider);
            ref.invalidate(accountBalancesProvider);
            ref.invalidate(allAccountBalancesProvider);
            ref.invalidate(netWorthProvider);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildTopHeader(profile),
              ),
              SliverToBoxAdapter(
                child: _buildOverviewHero(
                  summary,
                  currencySymbol,
                  totalActualIncome,
                  totalActualExpenses,
                  netWorth,
                  monthScopeLabel,
                  isAmountsVisible,
                ),
              ),
              SliverToBoxAdapter(
                child: _buildAccountsPreview(
                  accounts,
                  accountBalances,
                  currencySymbol,
                  isAccountsExpanded,
                ),
              ),
              SliverToBoxAdapter(
                child: _buildUpcomingPayments(
                  currencySymbol,
                  upcoming,
                  isUpcomingExpanded,
                ),
              ),
              SliverToBoxAdapter(
                child: _buildRecentTransactions(
                  transactions,
                  currencySymbol,
                  isRecentTransactionsExpanded,
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.xl),
              ),
            ],
          ),
        ),
      ),
    );
  }

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

  Widget _buildTopHeader(AsyncValue<dynamic> profile) {
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
              onTap: () {
                // Future: notifications screen.
              },
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
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizing.radiusLg),
      child: Container(
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
    dynamic summary,
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
      padding: const EdgeInsets.symmetric(horizontal: _homeHorizontalPadding),
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
              const SizedBox(height: _homeSectionSpacing),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAccountsPreview(
    List<Account> accounts,
    Map<String, double> accountBalances,
    String currencySymbol,
    bool isExpanded,
  ) {
    if (accounts.isEmpty) return const SizedBox.shrink();

    final visible = accounts.take(3).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _homeHorizontalPadding,
        0,
        _homeHorizontalPadding,
        _homeSectionSpacing,
      ),
      child: _buildGlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        tintColor: _neoSurface1,
        borderColor: _neoStroke,
        borderRadius: BorderRadius.circular(_homeCardRadius),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AdaptiveHeadingText(
                    text: 'Accounts',
                    style: _sectionTitleStyle,
                  ),
                ),
                const SizedBox(width: 8),
                _buildSectionActionButton(
                  label: 'Manage',
                  icon: LucideIcons.settings2,
                  onPressed: () => context.push('/settings/accounts'),
                ),
                const SizedBox(width: 8),
                _buildSectionChevronButton(
                  expanded: isExpanded,
                  onPressed: () {
                    ref.read(uiPreferencesProvider.notifier).setSectionExpanded(
                          UiSectionKeys.homeAccounts,
                          !isExpanded,
                        );
                  },
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: AppSpacing.sm),
              for (var i = 0; i < visible.length; i++) ...[
                _buildAccountPreviewRow(
                  visible[i],
                  accountBalances[visible[i].id] ?? visible[i].openingBalance,
                  currencySymbol,
                  onTap: () => context.push(
                    '/settings/accounts?accountId=${Uri.encodeComponent(visible[i].id)}',
                  ),
                ),
                if (i < visible.length - 1)
                  Divider(
                    height: 16,
                    color: _neoStroke.withValues(alpha: 0.85),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccountPreviewRow(
      Account account, double balance, String currencySymbol,
      {VoidCallback? onTap}) {
    final isNegative = balance < 0;
    final amountColor = isNegative ? _negativeColor : _positiveColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: _homeRowVerticalPadding),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _neoSurface2,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: _neoStroke),
              ),
              child: Icon(
                _getAccountTypeIcon(account.type),
                size: NeoIconSizes.lg,
                color: _neoTextSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                account.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _rowTitleStyle,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '$currencySymbol${_formatAmount(balance)}',
              style: _rowAmountStyle(amountColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    String? cornerLabel,
    required double amount,
    required bool isAmountVisible,
    required String currencySymbol,
    required IconData icon,
    required Color lightAccent,
    required Color darkAccent,
    required List<Color> gradientColors,
    required IconData footerIcon,
    required String footerLabel,
    required double amountFontSize,
    required double cardHeight,
    required double headerHeight,
    required double footerHeight,
    VoidCallback? onTap,
  }) {
    final isLight = _isLightMode(context);
    final textColor = isLight ? lightAccent : darkAccent;
    final iconBgColor = isLight
        ? lightAccent.withValues(alpha: 0.22)
        : darkAccent.withValues(alpha: 0.18);
    final footerColor = isLight
        ? textColor.withValues(alpha: 0.95)
        : textColor.withValues(alpha: 0.88);
    final textScale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(0.85, 1.3).toDouble();
    final cornerText = cornerLabel?.trim() ?? '';
    final hasCornerLabel = cornerText.isNotEmpty;
    final showCornerLabel = hasCornerLabel && textScale < 1.1;
    final chipBorderColor = isLight
        ? textColor.withValues(alpha: 0.42)
        : textColor.withValues(alpha: 0.34);
    final chipBgColor = isLight
        ? Colors.white.withValues(alpha: 0.30)
        : Colors.black.withValues(alpha: 0.18);
    final amountStyle = AppTypography.amountMedium.copyWith(
      color: textColor,
      fontWeight: FontWeight.w700,
      fontSize: amountFontSize,
      height: 1.0,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_homeCardRadius),
        child: SizedBox(
          height: cardHeight,
          child: _buildGlassCard(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            tintColor: gradientColors.first,
            gradientColors: gradientColors,
            borderColor: isLight
                ? lightAccent.withValues(alpha: 0.46)
                : darkAccent.withValues(alpha: 0.40),
            borderRadius: BorderRadius.circular(_homeCardRadius),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: headerHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: iconBgColor,
                          borderRadius:
                              BorderRadius.circular(AppSizing.radiusSm),
                          border: Border.all(
                            color: isLight
                                ? lightAccent.withValues(alpha: 0.42)
                                : darkAccent.withValues(alpha: 0.34),
                          ),
                        ),
                        child: Icon(
                          icon,
                          size: NeoIconSizes.xs,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: AdaptiveHeadingText(
                          text: title,
                          maxLines: 2,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.02,
                          ),
                        ),
                      ),
                      if (showCornerLabel) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: chipBgColor,
                            borderRadius:
                                BorderRadius.circular(AppSizing.radiusFull),
                            border: Border.all(color: chipBorderColor),
                          ),
                          child: Text(
                            cornerText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _rowSecondaryStyle.copyWith(
                              color: footerColor.withValues(alpha: 0.9),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        isAmountVisible
                            ? '$currencySymbol${_formatAmount(amount)}'
                            : '\u2022\u2022\u2022\u2022',
                        style: amountStyle,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: footerHeight,
                  child: Row(
                    children: [
                      Icon(
                        footerIcon,
                        size: 10,
                        color: footerColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          footerLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: footerColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.05,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final isLight = _isLightMode(context);
    final textScale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(0.85, 1.3).toDouble();
    final horizontalPadding =
        (12.0 - (textScale - 1.0) * 4.0).clamp(8.0, 12.0).toDouble();
    final verticalPadding =
        (8.0 + (textScale - 1.0) * 3.0).clamp(8.0, 11.0).toDouble();
    final minHeight = (34.0 + (textScale - 1.0) * 8.0).clamp(34.0, 40.0);
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: NeoIconSizes.sm, color: _neoLime),
      label: Text(label, style: _sectionActionStyle),
      style: OutlinedButton.styleFrom(
        foregroundColor: _neoLime,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        minimumSize: Size(0, minHeight),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        backgroundColor:
            isLight ? _neoLime.withValues(alpha: 0.10) : Colors.transparent,
        side: BorderSide(
          color: _neoLime.withValues(alpha: isLight ? 0.55 : 0.4),
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildSectionChevronButton({
    required bool expanded,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppSizing.radiusFull),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: _neoSurface2,
          borderRadius: BorderRadius.circular(AppSizing.radiusFull),
          border: Border.all(color: _neoStroke),
        ),
        child: Icon(
          expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
          size: NeoIconSizes.md,
          color: _neoTextSecondary,
        ),
      ),
    );
  }

  Widget _buildUpcomingPayments(
    String currencySymbol,
    AsyncValue<List<Subscription>> upcoming,
    bool isExpanded,
  ) {
    return upcoming.when(
      data: (upcomingList) {
        final sorted = [...upcomingList]
          ..sort((a, b) => a.daysUntilDue.compareTo(b.daysUntilDue));
        final visible = sorted.take(3).toList();

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            _homeHorizontalPadding,
            0,
            _homeHorizontalPadding,
            _homeSectionSpacing,
          ),
          child: _buildGlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            tintColor: _neoSurface1,
            borderColor: _neoStroke,
            borderRadius: BorderRadius.circular(_homeCardRadius),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AdaptiveHeadingText(
                        text: 'Upcoming payments',
                        style: _sectionTitleStyle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildSectionActionButton(
                      label: 'View all',
                      icon: LucideIcons.calendarRange,
                      onPressed: () => context.push('/subscriptions'),
                    ),
                    const SizedBox(width: 8),
                    _buildSectionChevronButton(
                      expanded: isExpanded,
                      onPressed: () {
                        ref
                            .read(uiPreferencesProvider.notifier)
                            .setSectionExpanded(
                              UiSectionKeys.homeUpcoming,
                              !isExpanded,
                            );
                      },
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const SizedBox(height: AppSpacing.sm),
                  if (sorted.isEmpty)
                    _buildNoUpcomingPaymentsState()
                  else ...[
                    for (var index = 0; index < visible.length; index++) ...[
                      _buildUpcomingPaymentTile(visible[index], currencySymbol),
                      if (index < visible.length - 1)
                        Divider(
                          height: 16,
                          color: _neoStroke.withValues(alpha: 0.85),
                        ),
                    ],
                    if (sorted.length > visible.length)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '+${sorted.length - visible.length} more upcoming',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _rowSecondaryStyle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => context.push('/subscriptions'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 0,
                                  vertical: 0,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'See all',
                                style: _sectionActionStyle,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildNoUpcomingPaymentsState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _neoSurface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _neoStroke),
            ),
            child: Icon(
              LucideIcons.calendarCheck2,
              color: _neoTextSecondary,
              size: NeoIconSizes.xl,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No upcoming payments',
            style: _rowTitleStyle,
          ),
          const SizedBox(height: 2),
          Text(
            'You are all caught up',
            style: _rowSecondaryStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingPaymentTile(Subscription sub, String currencySymbol) {
    final accentColor = sub.isOverdue ? _negativeColor : sub.colorValue;
    final statusColor = sub.isOverdue
        ? _negativeColor
        : sub.isDueToday
            ? _warningColor
            : _positiveColor;

    return InkWell(
      onTap: () => context.push('/subscriptions'),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: _homeRowVerticalPadding),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _neoSurface2,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: _neoStroke),
              ),
              child: Icon(
                _getIcon(sub.icon),
                size: NeoIconSizes.lg,
                color: accentColor,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sub.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _rowTitleStyle,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormat('MMM d').format(sub.nextDueDate)} - ${sub.billingCycleLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _rowSecondaryStyle,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$currencySymbol${_formatAmount(sub.amount)}',
                  style: _rowAmountStyle(_neoTextPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  sub.isOverdue
                      ? 'Overdue'
                      : sub.isDueToday
                          ? 'Due today'
                          : 'In ${sub.daysUntilDue}d',
                  style: _rowSecondaryStyle.copyWith(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildSpendingChart(
    AsyncValue<List<dynamic>> categories,
    String currencySymbol,
  ) {
    return categories.when(
      data: (categoryList) {
        final spendingCategories =
            categoryList.where((c) => c.totalActual > 0).toList();
        if (spendingCategories.isEmpty) {
          return const SizedBox.shrink();
        }

        final totalActual = spendingCategories.fold<double>(
          0.0,
          (sum, c) => sum + c.totalActual,
        );

        final segments = spendingCategories
            .map(
              (c) => DonutSegment(
                color: c.colorValue,
                value: c.totalActual,
                name: c.name,
                icon: c.icon,
              ),
            )
            .toList();

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Spending by category', style: AppTypography.h3),
              const SizedBox(height: AppSpacing.sm),
              _buildGlassCard(
                padding: const EdgeInsets.all(AppSpacing.sm),
                borderColor: _neoStroke.withValues(alpha: 0.85),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth;
                    final isWideLayout = availableWidth >= 460;
                    final chartSize = isWideLayout
                        ? 260.0
                        : availableWidth.clamp(240.0, 360.0).toDouble();
                    final strokeWidth =
                        isWideLayout ? 28.0 : (chartSize >= 320 ? 26.0 : 22.0);
                    final selectedStrokeWidth = strokeWidth + 6;
                    final gapDegrees = isWideLayout ? 15.0 : 13.0;
                    final centerAmountStyle =
                        AppTypography.amountLarge.copyWith(
                      fontSize: chartSize >= 320 ? 40 : 32,
                      height: 1.0,
                    );
                    final centerLabelStyle = TextStyle(
                      color: _neoTextSecondary,
                      fontSize: chartSize >= 320 ? 13 : 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                    );
                    final chartWidget = SizedBox(
                      width: chartSize,
                      child: DonutChart(
                        segments: segments,
                        total: totalActual,
                        height: chartSize,
                        strokeWidth: strokeWidth,
                        selectedStrokeWidth: selectedStrokeWidth,
                        gapDegrees: gapDegrees,
                        centerBuilder: (selectedIndex) {
                          if (selectedIndex == null ||
                              selectedIndex >= spendingCategories.length) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.trendingUp,
                                  color: NeoTheme.positiveValue(context),
                                  size: 28,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '$currencySymbol${_formatAmount(totalActual)}',
                                  style: centerAmountStyle,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'TOTAL',
                                  style: centerLabelStyle,
                                ),
                              ],
                            );
                          }

                          final category = spendingCategories[selectedIndex];
                          final percentage = totalActual > 0
                              ? (category.totalActual / totalActual * 100)
                              : 0.0;

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getIcon(category.icon),
                                color: category.colorValue,
                                size: 28,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '$currencySymbol${_formatAmount(category.totalActual)}',
                                style: centerAmountStyle,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                category.name.toUpperCase(),
                                style: centerLabelStyle,
                              ),
                              Text(
                                '${percentage.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: category.colorValue,
                                  fontSize: chartSize >= 320 ? 18 : 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    );

                    final legendWidget = _buildSpendingLegend(
                      spendingCategories,
                      totalActual,
                      currencySymbol,
                      maxItems: isWideLayout ? 5 : 4,
                    );

                    if (isWideLayout) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          chartWidget,
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: legendWidget),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        Center(child: chartWidget),
                        const SizedBox(height: AppSpacing.md),
                        legendWidget,
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSpendingLegend(
    List<dynamic> categories,
    double totalActual,
    String currencySymbol, {
    int maxItems = 4,
  }) {
    final sorted = [...categories]
      ..sort((a, b) => b.totalActual.compareTo(a.totalActual));
    final visible = sorted.take(maxItems).toList();

    return Column(
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          _buildSpendingLegendRow(
            visible[i],
            totalActual,
            currencySymbol,
          ),
          if (i < visible.length - 1) Divider(height: 1, color: _neoStroke),
        ],
      ],
    );
  }

  Widget _buildSpendingLegendRow(
    dynamic category,
    double totalActual,
    String currencySymbol,
  ) {
    final percentage =
        totalActual > 0 ? (category.totalActual / totalActual * 100) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: category.colorValue,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium.copyWith(
                color: _neoTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: TextStyle(
              color: category.colorValue,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$currencySymbol${_formatAmount(category.totalActual)}',
            style: AppTypography.bodyMedium.copyWith(
              color: _neoTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildYearlyBarChart(
    AsyncValue<List<MonthlyBarData>> yearlyMonthlyExpenses,
    String currencySymbol,
  ) {
    return yearlyMonthlyExpenses.when(
      data: (monthlyData) {
        if (monthlyData.isEmpty ||
            monthlyData.every((d) => d.totalExpenses == 0)) {
          return const SizedBox.shrink();
        }

        final year = DateTime.now().year;

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Yearly Overview', style: AppTypography.h3),
                  Text(
                    '$year',
                    style: TextStyle(
                      color: _neoTextSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildGlassCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                borderColor: _neoStroke.withValues(alpha: 0.85),
                child: StackedBarChart(
                  monthlyData: monthlyData,
                  currencySymbol: currencySymbol,
                  interactive: true,
                  selectedBarIndex: _selectedYearlyBarIndex,
                  onBarSelected: (index) {
                    setState(() => _selectedYearlyBarIndex = index);
                  },
                  height: 230,
                ),
              ),
              if (_selectedYearlyBarIndex != null &&
                  _selectedYearlyBarIndex! < monthlyData.length) ...[
                const SizedBox(height: AppSpacing.sm),
                _buildYearlySelectionSummary(
                  monthlyData[_selectedYearlyBarIndex!],
                  currencySymbol,
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildYearlySelectionSummary(
    MonthlyBarData selectedMonth,
    String currencySymbol,
  ) {
    return Row(
      children: [
        Text(
          '${selectedMonth.monthName}: $currencySymbol${_formatAmount(selectedMonth.totalExpenses)}',
          style: AppTypography.bodyMedium.copyWith(
            color: _neoTextSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => setState(() => _selectedYearlyBarIndex = null),
          child: Text(
            'Clear',
            style: TextStyle(color: NeoTheme.positiveValue(context)),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(
    AsyncValue<List<Transaction>> transactions,
    String currencySymbol,
    bool isExpanded,
  ) {
    return transactions.when(
      data: (list) {
        final recent = [...list]..sort((a, b) => b.date.compareTo(a.date));
        final visible = recent.take(5).toList();

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            _homeHorizontalPadding,
            0,
            _homeHorizontalPadding,
            _homeSectionSpacing,
          ),
          child: _buildGlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            tintColor: _neoSurface1,
            borderColor: _neoStroke,
            borderRadius: BorderRadius.circular(_homeCardRadius),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AdaptiveHeadingText(
                        text: 'Recent transactions',
                        style: _sectionTitleStyle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildSectionActionButton(
                      label: 'View all',
                      icon: LucideIcons.list,
                      onPressed: () => context.push('/transactions'),
                    ),
                    const SizedBox(width: 8),
                    _buildSectionChevronButton(
                      expanded: isExpanded,
                      onPressed: () {
                        ref
                            .read(uiPreferencesProvider.notifier)
                            .setSectionExpanded(
                              UiSectionKeys.homeRecentTransactions,
                              !isExpanded,
                            );
                      },
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const SizedBox(height: AppSpacing.sm),
                  if (visible.isEmpty)
                    _buildEmptyRecentTransactions()
                  else
                    Column(
                      children: [
                        for (var index = 0;
                            index < visible.length;
                            index++) ...[
                          _buildRecentTransactionRow(
                            visible[index],
                            currencySymbol,
                          ),
                          if (index < visible.length - 1)
                            Divider(
                              height: 16,
                              color: _neoStroke.withValues(alpha: 0.85),
                            ),
                        ],
                      ],
                    ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.fromLTRB(
          _homeHorizontalPadding,
          0,
          _homeHorizontalPadding,
          _homeSectionSpacing,
        ),
        child: _buildGlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          tintColor: _neoSurface1,
          borderColor: _neoStroke,
          borderRadius: BorderRadius.circular(_homeCardRadius),
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildGlassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(AppSpacing.md),
    BorderRadius? borderRadius,
    Color? borderColor,
    Color? tintColor,
    List<Color>? gradientColors,
  }) {
    final radius = borderRadius ?? BorderRadius.circular(_homeCardRadius);
    final resolvedBorderColor = borderColor ?? _neoStroke;
    final resolvedTintColor = tintColor ?? _neoSurface1;
    final shadowColor = _isLightMode(context)
        ? Colors.black.withValues(alpha: 0.16)
        : _neoAppBg.withValues(alpha: 0.9);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: resolvedTintColor,
        gradient: gradientColors == null
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
        borderRadius: radius,
        border: Border.all(color: resolvedBorderColor),
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

  Widget _buildEmptyRecentTransactions() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _neoSurface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _neoStroke),
            ),
            child: Icon(
              LucideIcons.receipt,
              color: _neoTextSecondary,
              size: NeoIconSizes.xl,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No transactions yet',
            style: _rowTitleStyle,
          ),
          const SizedBox(height: 2),
          Text(
            'Start by adding your first transaction',
            style: _rowSecondaryStyle,
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: () => _showAddTransaction(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _neoLime,
              foregroundColor:
                  _isLightMode(context) ? _neoTextPrimary : _neoSurface1,
            ),
            icon: const Icon(LucideIcons.plus, size: NeoIconSizes.md),
            label: const Text('Add transaction'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionRow(
      Transaction transaction, String currencySymbol) {
    final amountColor = transaction.isIncome ? _positiveColor : _negativeColor;

    return InkWell(
      onTap: () => context.push('/transactions'),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: _homeRowVerticalPadding),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _neoSurface2,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: _neoStroke),
              ),
              child: Icon(
                _getTransactionIcon(transaction),
                size: NeoIconSizes.lg,
                color: amountColor,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.displayName,
                    style: _rowTitleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${transaction.isIncome ? 'Income' : (transaction.categoryName ?? 'Expense')} • ${DateFormat('MMM d, yyyy').format(transaction.date)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _rowSecondaryStyle,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  transaction.formattedAmount(currencySymbol),
                  style: _rowAmountStyle(amountColor),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.isIncome ? 'Received' : 'Paid',
                  style: _rowSecondaryStyle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount.abs() >= 100000) {
      return NumberFormat('#,##0').format(amount.round());
    }
    if (amount == amount.roundToDouble()) {
      return NumberFormat('#,##0').format(amount.round());
    }
    return NumberFormat('#,##0.##').format(amount);
  }

  IconData _getTransactionIcon(Transaction transaction) {
    if (transaction.isIncome) {
      return LucideIcons.arrowDownLeft;
    }

    final name =
        (transaction.categoryName ?? transaction.displayName).toLowerCase();

    if (name.contains('food') || name.contains('restaurant')) {
      return LucideIcons.utensils;
    }
    if (name.contains('transport') || name.contains('car')) {
      return LucideIcons.car;
    }
    if (name.contains('home') || name.contains('housing')) {
      return LucideIcons.home;
    }
    if (name.contains('entertainment') || name.contains('game')) {
      return LucideIcons.gamepad2;
    }
    if (name.contains('shopping')) {
      return LucideIcons.shoppingBag;
    }
    if (name.contains('health')) {
      return LucideIcons.heart;
    }
    if (name.contains('gift')) {
      return LucideIcons.gift;
    }

    return LucideIcons.receipt;
  }

  IconData _getAccountTypeIcon(AccountType type) {
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

  IconData _getIcon(String iconName) {
    return resolveAppIcon(iconName, fallback: LucideIcons.creditCard);
  }

  void _showAddTransaction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TransactionFormSheet(),
    );
  }
}
