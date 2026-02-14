import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../models/account.dart';
import '../../models/monthly_summary.dart';
import '../../models/subscription.dart';
import '../../models/transaction.dart';
import '../../models/user_profile.dart';
import '../../providers/providers.dart';
import '../../utils/app_icon_registry.dart';
import '../../utils/transaction_display_utils.dart';
import '../transactions/transaction_form_sheet.dart';

part 'home_screen_header_overview.dart';
part 'home_screen_sections.dart';
part 'home_screen_recent.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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
}
