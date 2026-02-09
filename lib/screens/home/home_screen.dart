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
  bool _isAmountsVisible = true;
  bool _isAccountsExpanded = true;
  bool _isUpcomingExpanded = true;
  bool _isRecentTransactionsExpanded = true;

  static final _darkPalette = _HomePalette(
    appBg: const HSLColor.fromAHSL(1.0, 0.0, 0.0, 0.055).toColor(),
    surface1: const Color(0xFF171A20),
    surface2: const Color(0xFF1D2128),
    stroke: const Color(0xFF2B313B),
    textPrimary: const Color(0xFFF3F6FB),
    textSecondary: const Color(0xFFA8B0BF),
    accent: const Color(0xFFDDF36B),
    // Deep tinted KPI cards for dark mode (closer to provided reference)
    balanceCardStart: const HSLColor.fromAHSL(1, 198, 0.64, 0.18).toColor(),
    balanceCardEnd: const HSLColor.fromAHSL(1, 199, 0.56, 0.16).toColor(),
    expenseCardStart: const HSLColor.fromAHSL(1, 338, 0.43, 0.16).toColor(),
    expenseCardEnd: const HSLColor.fromAHSL(1, 338, 0.36, 0.14).toColor(),
    incomeCardStart: const HSLColor.fromAHSL(1, 165, 0.63, 0.17).toColor(),
    incomeCardEnd: const HSLColor.fromAHSL(1, 165, 0.56, 0.15).toColor(),
  );

  static final _lightPalette = _HomePalette(
    appBg: const HSLColor.fromAHSL(1, 220, 0.18, 0.96).toColor(),
    surface1: const HSLColor.fromAHSL(1, 220, 0.22, 0.99).toColor(),
    surface2: const HSLColor.fromAHSL(1, 220, 0.18, 0.95).toColor(),
    stroke: const HSLColor.fromAHSL(1, 220, 0.18, 0.86).toColor(),
    textPrimary: const HSLColor.fromAHSL(1, 220, 0.28, 0.14).toColor(),
    textSecondary: const HSLColor.fromAHSL(1, 220, 0.14, 0.40).toColor(),
    accent: const HSLColor.fromAHSL(1, 74, 0.52, 0.36).toColor(),
    // Light counterparts for dark KPI palette
    // Higher-contrast light KPI cards so they stand off the page background
    balanceCardStart: const HSLColor.fromAHSL(1, 196, 0.66, 0.84).toColor(),
    balanceCardEnd: const HSLColor.fromAHSL(1, 196, 0.58, 0.78).toColor(),
    expenseCardStart: const HSLColor.fromAHSL(1, 351, 0.65, 0.86).toColor(),
    expenseCardEnd: const HSLColor.fromAHSL(1, 351, 0.56, 0.79).toColor(),
    incomeCardStart: const HSLColor.fromAHSL(1, 152, 0.56, 0.84).toColor(),
    incomeCardEnd: const HSLColor.fromAHSL(1, 152, 0.48, 0.77).toColor(),
  );

  _HomePalette _palette(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? _lightPalette
          : _darkPalette;

  bool _isLightMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light;

  Color get _neoAppBg => _palette(context).appBg;
  Color get _neoSurface1 => _palette(context).surface1;
  Color get _neoSurface2 => _palette(context).surface2;
  Color get _neoStroke => _palette(context).stroke;
  Color get _neoTextPrimary => _palette(context).textPrimary;
  Color get _neoTextSecondary => _palette(context).textSecondary;
  Color get _neoLime => _palette(context).accent;
  Color get _neoBlueCardStart => _palette(context).balanceCardStart;
  Color get _neoBlueCardEnd => _palette(context).balanceCardEnd;
  Color get _neoExpenseCardStart => _palette(context).expenseCardStart;
  Color get _neoExpenseCardEnd => _palette(context).expenseCardEnd;
  Color get _neoIncomeCardStart => _palette(context).incomeCardStart;
  Color get _neoIncomeCardEnd => _palette(context).incomeCardEnd;
  Color get _positiveColor =>
      _isLightMode(context) ? const Color(0xFF4E7A2D) : const Color(0xFF9FE870);
  Color get _negativeColor =>
      _isLightMode(context) ? const Color(0xFFC14B60) : const Color(0xFFFF7A7A);
  Color get _warningColor =>
      _isLightMode(context) ? const Color(0xFFC58A30) : const Color(0xFFFFC568);
  static const double _homeCardRadius = 16;
  static const double _homeHorizontalPadding = AppSpacing.md;
  static const double _homeSectionSpacing = 14;
  static const double _homeHeaderActionHeight = 34;
  static const double _homeRowVerticalPadding = 6;

  TextStyle get _sectionTitleStyle => AppTypography.h3.copyWith(
        color: _neoTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.2,
      );

  TextStyle get _sectionActionStyle => AppTypography.labelMedium.copyWith(
        color: _neoLime,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.1,
      );

  TextStyle get _rowTitleStyle => AppTypography.bodyLarge.copyWith(
        color: _neoTextPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 16,
        height: 1.2,
      );

  TextStyle get _rowSecondaryStyle => AppTypography.bodySmall.copyWith(
        color: _neoTextSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.2,
      );

  TextStyle _rowAmountStyle(Color color) => AppTypography.amountSmall.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
        fontSize: 16,
        height: 1.1,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

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
    final profile = ref.watch(userProfileProvider);
    final upcoming = ref.watch(upcomingSubscriptionsProvider);
    final totalActualIncome = ref.watch(totalActualIncomeProvider);
    final totalActualExpenses = ref.watch(totalActualExpensesProvider);
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final accountBalances =
        ref.watch(allAccountBalancesProvider).value ?? const <String, double>{};
    final transactions = ref.watch(transactionsProvider);

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
                ),
              ),
              SliverToBoxAdapter(
                child: _buildAccountsPreview(
                  accounts,
                  accountBalances,
                  currencySymbol,
                ),
              ),
              SliverToBoxAdapter(
                child: _buildUpcomingPayments(currencySymbol, upcoming),
              ),
              SliverToBoxAdapter(
                child: _buildRecentTransactions(transactions, currencySymbol),
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
          size: 18,
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
    await ref.read(themeModeProvider.notifier).setThemeMode(nextMode);
  }

  Widget _buildOverviewHero(
    dynamic summary,
    String currencySymbol,
    double actualIncome,
    double actualExpenses,
  ) {
    final primaryBalance = summary?.actualBalance ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _homeHorizontalPadding),
      child: Column(
        children: [
          _buildBalanceHeroCard(currencySymbol, primaryBalance),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildCompactSummaryCard(
                  title: 'Expenses',
                  amount: actualExpenses,
                  isAmountVisible: _isAmountsVisible,
                  currencySymbol: currencySymbol,
                  icon: LucideIcons.trendingDown,
                  isIncome: false,
                  onTap: () => context.push('/expenses'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildCompactSummaryCard(
                  title: 'Income',
                  amount: actualIncome,
                  isAmountVisible: _isAmountsVisible,
                  currencySymbol: currencySymbol,
                  icon: LucideIcons.trendingUp,
                  isIncome: true,
                  onTap: () => context.push('/income'),
                ),
              ),
            ],
          ),
          const SizedBox(height: _homeSectionSpacing),
        ],
      ),
    );
  }

  Widget _buildBalanceHeroCard(
    String currencySymbol,
    double balanceAmount,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLight = _isLightMode(context);
        final isNarrow = constraints.maxWidth < 360;
        final inkColor =
            isLight ? const Color(0xFF085864) : const Color(0xFF1ED0C0);
        final iconInkColor =
            isLight ? const Color(0xFF0A6664) : const Color(0xFF1FC3B6);
        final trendColor =
            isLight ? const Color(0xFF0B7367) : const Color(0xFF1AB3A8);
        final eyeBgColor = isLight
            ? Color.alphaBlend(
                Colors.white.withValues(alpha: 0.42),
                _neoBlueCardStart,
              )
            : Color.alphaBlend(
                Colors.white.withValues(alpha: 0.10),
                _neoBlueCardStart,
              );
        final eyeBorderColor = isLight
            ? inkColor.withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.22);
        final eyeIconColor = isLight ? const Color(0xFF25374A) : iconInkColor;
        final cardHeight = isNarrow ? 98.0 : 104.0;
        final rightColumnWidth = isNarrow ? 116.0 : 126.0;
        final eyeSize = isNarrow ? 42.0 : 46.0;
        final trendLabel =
            isNarrow ? '+15% vs last month' : '+15% from last month';
        final amountStyle = TextStyle(
          color: inkColor,
          fontSize: isNarrow ? 44 : 50,
          fontWeight: FontWeight.w700,
          height: 0.98,
          fontFeatures: const [FontFeature.tabularFigures()],
        );
        final metaTextStyle = TextStyle(
          color: trendColor,
          fontSize: isNarrow ? 11 : 12,
          fontWeight: FontWeight.w500,
          height: 1.1,
        );

        return _buildGlassCard(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          borderColor: isLight
              ? inkColor.withValues(alpha: 0.38)
              : inkColor.withValues(alpha: 0.45),
          tintColor: _neoBlueCardStart,
          gradientColors: <Color>[
            _neoBlueCardStart,
            _neoBlueCardEnd,
          ],
          borderRadius: BorderRadius.circular(_homeCardRadius),
          child: SizedBox(
            height: cardHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: isNarrow ? 3 : 5),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: isNarrow ? 24 : 26,
                            height: isNarrow ? 24 : 26,
                            decoration: BoxDecoration(
                              color: isLight
                                  ? iconInkColor.withValues(alpha: 0.22)
                                  : iconInkColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isLight
                                    ? iconInkColor.withValues(alpha: 0.38)
                                    : iconInkColor.withValues(alpha: 0.34),
                              ),
                            ),
                            child: Icon(
                              LucideIcons.wallet,
                              size: isNarrow ? 13 : 14,
                              color: iconInkColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Balance',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: inkColor,
                                fontSize: isNarrow ? 15 : 16,
                                fontWeight: FontWeight.w500,
                                height: 1.05,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _isAmountsVisible
                                  ? '$currencySymbol${_formatAmount(balanceAmount)}'
                                  : '\u2022\u2022\u2022\u2022',
                              style: amountStyle,
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: rightColumnWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: () => setState(
                            () => _isAmountsVisible = !_isAmountsVisible),
                        borderRadius:
                            BorderRadius.circular(AppSizing.radiusFull),
                        child: Container(
                          width: eyeSize,
                          height: eyeSize,
                          decoration: BoxDecoration(
                            color: eyeBgColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: eyeBorderColor,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: isLight ? 0.10 : 0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isAmountsVisible
                                ? LucideIcons.eye
                                : LucideIcons.eyeOff,
                            size: isNarrow ? 22 : 24,
                            color: eyeIconColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: rightColumnWidth,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.trendingUp,
                                  size: 14,
                                  color: trendColor,
                                ),
                                const SizedBox(width: 4),
                                Text(trendLabel, style: metaTextStyle),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountsPreview(
    List<Account> accounts,
    Map<String, double> accountBalances,
    String currencySymbol,
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
                Text('Accounts', style: _sectionTitleStyle),
                const Spacer(),
                _buildSectionActionButton(
                  label: 'Manage',
                  icon: LucideIcons.settings2,
                  onPressed: () => context.push('/settings/accounts'),
                ),
                const SizedBox(width: 8),
                _buildSectionChevronButton(
                  expanded: _isAccountsExpanded,
                  onPressed: () {
                    setState(() => _isAccountsExpanded = !_isAccountsExpanded);
                  },
                ),
              ],
            ),
            if (_isAccountsExpanded) ...[
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
                size: 18,
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
              '$currencySymbol${_formatAmount(balance.abs())}',
              style: _rowAmountStyle(amountColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactSummaryCard({
    required String title,
    required double amount,
    required bool isAmountVisible,
    required String currencySymbol,
    required IconData icon,
    required bool isIncome,
    VoidCallback? onTap,
  }) {
    final isLight = _isLightMode(context);
    final darkAccent =
        isIncome ? const Color(0xFF2FDE8C) : const Color(0xFFFF5B6A);
    final lightAccent =
        isIncome ? const Color(0xFF0E7A4C) : const Color(0xFFAA384A);
    final textColor = isLight ? lightAccent : darkAccent;
    final iconBgColor = isLight
        ? lightAccent.withValues(alpha: 0.22)
        : darkAccent.withValues(alpha: 0.18);
    final gradientColors = isIncome
        ? <Color>[_neoIncomeCardStart, _neoIncomeCardEnd]
        : <Color>[_neoExpenseCardStart, _neoExpenseCardEnd];
    final changeColor = isIncome
        ? (isLight ? const Color(0xFF136C45) : const Color(0xFF546A37))
        : (isLight ? const Color(0xFF9A3343) : const Color(0xFFB2485A));
    final amountStyle = AppTypography.amountMedium.copyWith(
      color: textColor,
      fontWeight: FontWeight.w700,
      fontSize: 24,
      height: 1.0,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_homeCardRadius),
        child: SizedBox(
          height: 104,
          child: _buildGlassCard(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            tintColor: gradientColors.first,
            gradientColors: gradientColors,
            borderColor: isLight
                ? lightAccent.withValues(alpha: 0.46)
                : darkAccent.withValues(alpha: 0.40),
            borderRadius: BorderRadius.circular(_homeCardRadius),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(AppSizing.radiusSm),
                        border: Border.all(
                          color: isLight
                              ? lightAccent.withValues(alpha: 0.42)
                              : darkAccent.withValues(alpha: 0.34),
                        ),
                      ),
                      child: Icon(icon, size: 11, color: textColor),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    isAmountVisible
                        ? '$currencySymbol${_formatAmount(amount)}'
                        : '\u2022\u2022\u2022\u2022',
                    style: amountStyle,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      isIncome
                          ? LucideIcons.trendingUp
                          : LucideIcons.trendingDown,
                      size: 10,
                      color: isLight
                          ? changeColor
                          : darkAccent.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        isIncome ? '+15% Income' : '+53% Expenses',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isLight
                              ? changeColor
                              : darkAccent.withValues(alpha: 0.9),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
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

  Widget _buildSectionActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final isLight = _isLightMode(context);
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14, color: _neoLime),
      label: Text(label, style: _sectionActionStyle),
      style: OutlinedButton.styleFrom(
        foregroundColor: _neoLime,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, _homeHeaderActionHeight),
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
          size: 16,
          color: _neoTextSecondary,
        ),
      ),
    );
  }

  Widget _buildUpcomingPayments(
    String currencySymbol,
    AsyncValue<List<Subscription>> upcoming,
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
                    Text('Upcoming payments', style: _sectionTitleStyle),
                    const Spacer(),
                    _buildSectionActionButton(
                      label: 'View all',
                      icon: LucideIcons.calendarRange,
                      onPressed: () => context.push('/subscriptions'),
                    ),
                    const SizedBox(width: 8),
                    _buildSectionChevronButton(
                      expanded: _isUpcomingExpanded,
                      onPressed: () {
                        setState(
                            () => _isUpcomingExpanded = !_isUpcomingExpanded);
                      },
                    ),
                  ],
                ),
                if (_isUpcomingExpanded) ...[
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
                            Text(
                              '+${sorted.length - visible.length} more upcoming',
                              style: _rowSecondaryStyle,
                            ),
                            const Spacer(),
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
              size: 20,
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
              child: Icon(_getIcon(sub.icon), size: 18, color: accentColor),
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
                borderColor: AppColors.border.withValues(alpha: 0.85),
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
                      color: AppColors.textMuted,
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
                                const Icon(
                                  LucideIcons.trendingUp,
                                  color: AppColors.savings,
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
          if (i < visible.length - 1)
            const Divider(height: 1, color: AppColors.border),
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
                color: AppColors.textPrimary,
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
              color: AppColors.textPrimary,
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
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildGlassCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                borderColor: AppColors.border.withValues(alpha: 0.85),
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
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => setState(() => _selectedYearlyBarIndex = null),
          child: const Text(
            'Clear',
            style: TextStyle(color: AppColors.savings),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(
    AsyncValue<List<Transaction>> transactions,
    String currencySymbol,
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
                    Text('Recent transactions', style: _sectionTitleStyle),
                    const Spacer(),
                    _buildSectionActionButton(
                      label: 'View all',
                      icon: LucideIcons.list,
                      onPressed: () => context.push('/transactions'),
                    ),
                    const SizedBox(width: 8),
                    _buildSectionChevronButton(
                      expanded: _isRecentTransactionsExpanded,
                      onPressed: () {
                        setState(() => _isRecentTransactionsExpanded =
                            !_isRecentTransactionsExpanded);
                      },
                    ),
                  ],
                ),
                if (_isRecentTransactionsExpanded) ...[
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
    Color borderColor = AppColors.border,
    Color tintColor = AppColors.surface,
    List<Color>? gradientColors,
  }) {
    final radius = borderRadius ?? BorderRadius.circular(_homeCardRadius);
    final shadowColor = _isLightMode(context)
        ? Colors.black.withValues(alpha: 0.16)
        : _neoAppBg.withValues(alpha: 0.9);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: tintColor,
        gradient: gradientColors == null
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
        borderRadius: radius,
        border: Border.all(color: borderColor),
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
              size: 20,
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
            icon: const Icon(LucideIcons.plus, size: 16),
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
                size: 18,
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
    final icons = {
      'home': LucideIcons.home,
      'utensils': LucideIcons.utensils,
      'car': LucideIcons.car,
      'tv': LucideIcons.tv,
      'shopping-bag': LucideIcons.shoppingBag,
      'gamepad-2': LucideIcons.gamepad2,
      'piggy-bank': LucideIcons.piggyBank,
      'graduation-cap': LucideIcons.graduationCap,
      'heart': LucideIcons.heart,
      'wallet': LucideIcons.wallet,
      'briefcase': LucideIcons.briefcase,
      'plane': LucideIcons.plane,
      'gift': LucideIcons.gift,
      'credit-card': LucideIcons.creditCard,
      'landmark': LucideIcons.landmark,
      'baby': LucideIcons.baby,
      'dumbbell': LucideIcons.dumbbell,
      'music': LucideIcons.music,
      'book': LucideIcons.book,
      'repeat': LucideIcons.repeat,
    };

    return icons[iconName] ?? LucideIcons.creditCard;
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

class _HomePalette {
  final Color appBg;
  final Color surface1;
  final Color surface2;
  final Color stroke;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Color balanceCardStart;
  final Color balanceCardEnd;
  final Color expenseCardStart;
  final Color expenseCardEnd;
  final Color incomeCardStart;
  final Color incomeCardEnd;

  const _HomePalette({
    required this.appBg,
    required this.surface1,
    required this.surface2,
    required this.stroke,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.balanceCardStart,
    required this.balanceCardEnd,
    required this.expenseCardStart,
    required this.expenseCardEnd,
    required this.incomeCardStart,
    required this.incomeCardEnd,
  });
}
