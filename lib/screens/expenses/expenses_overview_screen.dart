import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../config/theme.dart';
import '../../config/supabase_config.dart';
import '../../models/category.dart';
import '../../models/month.dart';
import '../../models/transaction.dart';
import '../../providers/providers.dart';
import '../../services/transaction_service.dart';
import '../../services/month_service.dart';
import 'category_form_sheet.dart';

class ExpensesOverviewScreen extends ConsumerStatefulWidget {
  const ExpensesOverviewScreen({super.key});

  @override
  ConsumerState<ExpensesOverviewScreen> createState() =>
      _ExpensesOverviewScreenState();
}

class _ExpensesOverviewScreenState
    extends ConsumerState<ExpensesOverviewScreen> {
  int? _selectedCategoryIndex;
  bool _hasCheckedMonths = false;
  bool _isYearView = false;

  @override
  void initState() {
    super.initState();
    // Ensure months exist for all transactions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureMonthsForTransactions();
    });
  }

  /// Ensure month records exist for all transaction dates
  Future<void> _ensureMonthsForTransactions() async {
    if (_hasCheckedMonths) return;
    _hasCheckedMonths = true;

    try {
      final transactionService = TransactionService();
      final monthService = MonthService();
      
      // Get all transactions (we'll query by user_id directly)
      final client = SupabaseConfig.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await client
          .from('transactions')
          .select('date, month_id')
          .eq('user_id', userId);

      if (response == null || (response as List).isEmpty) return;

      // Get existing months
      final existingMonths = await monthService.getAllMonths();
      final existingMonthIds = existingMonths.map((m) => m.id).toSet();

      // Extract unique month_ids from transactions
      final transactionMonthIds = (response as List)
          .map((e) => e['month_id'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toSet();

      // Find missing months
      final missingMonthIds = transactionMonthIds
          .where((id) => !existingMonthIds.contains(id))
          .toList();

      // For each missing month_id, try to get the month or create it from transaction dates
      for (final monthId in missingMonthIds) {
        // Try to get the month by ID first (in case it exists but wasn't in our query)
        var month = await monthService.getMonthById(monthId);
        
        if (month == null) {
          // Month doesn't exist - find a transaction with this month_id to get the date
          final txWithMonth = (response as List).firstWhere(
            (e) => e['month_id'] == monthId,
            orElse: () => null,
          );
          
          if (txWithMonth != null) {
            final txDate = DateTime.parse(txWithMonth['date'] as String);
            // Create month for this date
            final startDate = DateTime(txDate.year, txDate.month, 1);
            final endDate = DateTime(txDate.year, txDate.month + 1, 0);
            
            final monthNames = [
              'January', 'February', 'March', 'April', 'May', 'June',
              'July', 'August', 'September', 'October', 'November', 'December'
            ];
            
            month = await monthService.createMonth(
              name: '${monthNames[txDate.month - 1]} ${txDate.year}',
              startDate: startDate,
              endDate: endDate,
              isActive: false, // Don't make it active automatically
            );
          }
        }
      }

      // Also create months based on transaction dates (in case transactions have dates but wrong month_id)
      final transactionDates = (response as List)
          .map((e) => DateTime.parse(e['date'] as String))
          .toList();

      final uniqueMonths = <DateTime>{};
      for (final date in transactionDates) {
        final monthKey = DateTime(date.year, date.month, 1);
        uniqueMonths.add(monthKey);
      }

      for (final monthStart in uniqueMonths) {
        final existing = await monthService.getMonthByDate(monthStart);
        if (existing == null) {
          final endDate = DateTime(monthStart.year, monthStart.month + 1, 0);
          final monthNames = [
            'January', 'February', 'March', 'April', 'May', 'June',
            'July', 'August', 'September', 'October', 'November', 'December'
          ];
          
          await monthService.createMonth(
            name: '${monthNames[monthStart.month - 1]} ${monthStart.year}',
            startDate: monthStart,
            endDate: endDate,
            isActive: false,
          );
        }
      }

      // Refresh months list
      if (missingMonthIds.isNotEmpty || uniqueMonths.isNotEmpty) {
        ref.invalidate(userMonthsProvider);
      }
    } catch (e) {
      // Silently fail - don't disrupt the UI
      debugPrint('Error ensuring months: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final totalActual = ref.watch(totalActualExpensesProvider);
    final activeMonth = ref.watch(activeMonthProvider);
    final userMonths = ref.watch(userMonthsProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final expenseTransactions = ref.watch(expenseTransactionsProvider);

    // ── Year view providers ──
    final yearlyMonthlyExpenses = ref.watch(yearlyMonthlyExpensesProvider);
    final totalYearlyExpenses = ref.watch(totalYearlyExpensesProvider);
    final yearlyCategorySummaries = ref.watch(yearlyCategorySummariesProvider);

    // Build transaction count map: categoryId -> count
    final txCountByCategory = <String, int>{};
    for (final tx in expenseTransactions) {
      if (tx.categoryId != null) {
        txCountByCategory[tx.categoryId!] =
            (txCountByCategory[tx.categoryId!] ?? 0) + 1;
      }
    }

    final monthName = activeMonth.value?.name ?? '';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categoriesProvider);
          ref.invalidate(transactionsProvider);
          if (_isYearView) {
            ref.invalidate(yearlyMonthlyExpensesProvider);
            ref.invalidate(yearlyCategorySummariesProvider);
          }
        },
        child: categories.when(
          data: (categoryList) {
            // Filter to only categories with actual spending for the chart
            final spendingCategories =
                categoryList.where((c) => c.totalActual > 0).toList();

            return CustomScrollView(
              slivers: [
                // ── Page Header (unchanged) ──
                SliverToBoxAdapter(
                  child: _buildPageHeader(),
                ),

                // ── Month/Year Toggle (NEW) ──
                SliverToBoxAdapter(
                  child: _buildViewToggle(),
                ),

                // ── MONTH VIEW (unchanged, conditionally shown) ──
                if (!_isYearView) ...[
                  // Month Selector
                  SliverToBoxAdapter(
                    child: _buildMonthSelector(userMonths, activeMonth),
                  ),
                  // Spacing
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.lg),
                  ),
                  // Donut Chart
                  SliverToBoxAdapter(
                    child: _buildDonutChart(
                      spendingCategories,
                      totalActual,
                      currencySymbol,
                    ),
                  ),
                ],

                // ── YEAR VIEW (NEW, conditionally shown) ──
                if (_isYearView) ...[
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.sm),
                  ),
                  SliverToBoxAdapter(
                    child: yearlyMonthlyExpenses.when(
                      data: (monthlyData) =>
                          _buildBarChart(monthlyData, currencySymbol),
                      loading: () => const SizedBox(
                        height: 280,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                ],

                // ── Categories Header (unchanged) ──
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: Text(
                      'Categories',
                      style: AppTypography.h3,
                    ),
                  ),
                ),

                // ── MONTH VIEW: Category List (unchanged, conditionally shown) ──
                if (!_isYearView) ...[
                  if (categoryList.isEmpty)
                    SliverToBoxAdapter(child: _buildEmptyState())
                  else
                    SliverToBoxAdapter(
                      child: _buildCategoryList(
                        categoryList,
                        totalActual,
                        currencySymbol,
                        txCountByCategory,
                      ),
                    ),
                ],

                // ── YEAR VIEW: Yearly Category List (NEW, conditionally shown) ──
                if (_isYearView) ...[
                  SliverToBoxAdapter(
                    child: yearlyCategorySummaries.when(
                      data: (summaries) {
                        if (summaries.isEmpty) return _buildEmptyState();
                        return _buildYearlyCategoryList(
                          summaries,
                          totalYearlyExpenses,
                          currencySymbol,
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                ],

                // ── Add Category Button (unchanged) ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: _buildAddButton(),
                  ),
                ),

                // ── Bottom Padding (unchanged) ──
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxl),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(error.toString()),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // PAGE HEADER
  // ──────────────────────────────────────────────

  Widget _buildPageHeader() {
    return const SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Budget', style: AppTypography.h2),
            SizedBox(height: AppSpacing.xs),
            Text(
              'View your spending by category',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // MONTH SELECTOR
  // ──────────────────────────────────────────────

  Widget _buildMonthSelector(
    AsyncValue<List<Month>> userMonths,
    AsyncValue<Month?> activeMonth,
  ) {
    return userMonths.when(
      data: (months) {
        if (months.isEmpty) return const SizedBox.shrink();

        final activeMonthId = activeMonth.value?.id;

        return SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: months.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final month = months[index];
              final isActive = month.id == activeMonthId;

              return GestureDetector(
                onTap: () => _switchMonth(month.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizing.radiusFull),
                    border: isActive
                        ? null
                        : Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Text(
                      month.name,
                      style: TextStyle(
                        color: isActive
                            ? AppColors.background
                            : AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(height: 44),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _switchMonth(String monthId) async {
    setState(() => _selectedCategoryIndex = null); // Reset chart selection
    await ref.read(monthNotifierProvider.notifier).setActiveMonth(monthId);
    // Invalidate all dependent providers to force refresh
    ref.invalidate(activeMonthProvider);
    ref.invalidate(categoriesProvider);
    ref.invalidate(transactionsProvider);
    // Wait for activeMonthProvider to refresh so dependent providers rebuild with new month
    await ref.refresh(activeMonthProvider.future);
  }

  // ──────────────────────────────────────────────
  // DONUT CHART
  // ──────────────────────────────────────────────

  Widget _buildDonutChart(
    List<Category> spendingCategories,
    double totalActual,
    String currencySymbol,
  ) {
    if (spendingCategories.isEmpty) {
      return const SizedBox(height: AppSpacing.lg);
    }

    // Build segment data
    final segments = spendingCategories.map((c) => _DonutSegment(
      color: c.colorValue,
      value: c.totalActual,
    )).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizing.radiusXl),
        ),
        child: SizedBox(
          height: 280,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = math.min(constraints.maxWidth, constraints.maxHeight);
              // Calculate total from segments to ensure accuracy
              final segmentTotal = segments.fold<double>(0, (sum, s) => sum + s.value);
              
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Custom donut chart with gesture detection
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTapDown: (details) {
                      _handleChartTap(details, size, segments, segmentTotal);
                    },
                    child: CustomPaint(
                      size: Size(size, size),
                      painter: _DonutChartPainter(
                        segments: segments,
                        strokeWidth: 20,
                        gapDegrees: 10.0,
                        selectedIndex: _selectedCategoryIndex,
                        selectedStrokeWidth: 26,
                      ),
                    ),
                  ),
                  // Center info (non-interactive, allows taps to pass through)
                  IgnorePointer(
                    child: _buildChartCenter(
                      spendingCategories,
                      totalActual,
                      currencySymbol,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _handleChartTap(
    TapDownDetails details,
    double size,
    List<_DonutSegment> segments,
    double totalActual,
  ) {
    final center = Offset(size / 2, size / 2);
    final tapOffset = details.localPosition - center;
    final distance = tapOffset.distance;
    
    // Calculate the ring radius (center of the stroke)
    // Stroke width is 20 (normal) or 26 (selected), so use average
    final strokeWidth = 23.0;
    final radius = (size - strokeWidth) / 2;

    // Check if tap is on the ring (within stroke area)
    // Allow taps within the stroke width range (20-26px)
    final minRadius = radius - 15;
    final maxRadius = radius + 15;
    if (distance < minRadius || distance > maxRadius) {
      setState(() => _selectedCategoryIndex = null);
      return;
    }

    // Calculate angle of tap (in radians)
    // atan2 returns angle from positive x-axis (-π to π)
    // Painter starts from top (-π/2), so we need to match that
    var angle = math.atan2(tapOffset.dy, tapOffset.dx);
    
    // Convert to match painter's coordinate system (starting from -π/2 = top)
    // Add π/2 to rotate coordinate system so 0° is at top
    angle = angle + (math.pi / 2);
    // Normalize to 0-2π range
    if (angle < 0) angle += 2 * math.pi;

    // Find which segment was tapped (matching painter's logic exactly)
    final gapRad = 10.0 * math.pi / 180;
    final totalGap = gapRad * segments.length;
    final availableSweep = 2 * math.pi - totalGap;
    
    // Start from top (0 in normalized coordinates = -π/2 in painter)
    double startAngle = 0;

    for (int i = 0; i < segments.length; i++) {
      final fraction = segments[i].value / totalActual;
      final sweepAngle = fraction * availableSweep;
      final segmentEnd = startAngle + sweepAngle;
      
      // Check if tap angle falls within this segment
      // Use <= for end to include the boundary (but not the gap)
      bool isInSegment = false;
      
      if (segmentEnd <= 2 * math.pi) {
        // Normal case: segment doesn't wrap
        isInSegment = angle >= startAngle && angle < segmentEnd;
      } else {
        // Segment wraps around 2π (from 3π/2 to 2π and 0 to some value)
        // Check both ranges
        isInSegment = (angle >= startAngle && angle < 2 * math.pi) ||
                      (angle >= 0 && angle < (segmentEnd - 2 * math.pi));
      }
      
      if (isInSegment) {
        // Toggle selection: if already selected, deselect; otherwise select
        setState(() {
          _selectedCategoryIndex = (_selectedCategoryIndex == i) ? null : i;
        });
        return;
      }
      
      // Move to next segment: end of current segment + gap
      startAngle = segmentEnd + gapRad;
      // Normalize if wraps around
      if (startAngle >= 2 * math.pi) startAngle -= 2 * math.pi;
    }

    // If tap is in a gap, deselect
    setState(() => _selectedCategoryIndex = null);
  }

  Widget _buildChartCenter(
    List<Category> spendingCategories,
    double totalActual,
    String currencySymbol,
  ) {
    // Default: show total
    if (_selectedCategoryIndex == null ||
        _selectedCategoryIndex! >= spendingCategories.length) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.trendingUp,
            color: AppColors.savings,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            '$currencySymbol${_formatAmount(totalActual)}',
            style: AppTypography.amountMedium,
          ),
          const SizedBox(height: 4),
          const Text(
            'TOTAL',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.0,
            ),
          ),
        ],
      );
    }

    // Selected category
    final category = spendingCategories[_selectedCategoryIndex!];
    final percentage = totalActual > 0
        ? (category.totalActual / totalActual * 100)
        : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _getIcon(category.icon),
          color: category.colorValue,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          '$currencySymbol${_formatAmount(category.totalActual)}',
          style: AppTypography.amountMedium,
        ),
        const SizedBox(height: 4),
        Text(
          category.name.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${percentage.toStringAsFixed(0)}%',
          style: TextStyle(
            color: category.colorValue,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  // CATEGORIES LIST
  // ──────────────────────────────────────────────

  Widget _buildCategoryList(
    List<Category> categoryList,
    double totalActual,
    String currencySymbol,
    Map<String, int> txCountByCategory,
  ) {
    return Column(
      children: categoryList.asMap().entries.map((entry) {
        final category = entry.value;
        final percentage = totalActual > 0
            ? (category.totalActual / totalActual * 100)
            : 0.0;
        final txCount = txCountByCategory[category.id] ?? 0;

        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.sm,
          ),
          child: _buildCategoryRow(
            category: category,
            percentage: percentage,
            txCount: txCount,
            currencySymbol: currencySymbol,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryRow({
    required Category category,
    required double percentage,
    required int txCount,
    required String currencySymbol,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/budget/category/${category.id}'),
        onLongPress: () => _showEditSheet(category),
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        child: Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizing.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Circular colored icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: category.colorValue,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIcon(category.icon),
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Name + transaction count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: AppTypography.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$txCount ${txCount == 1 ? 'transaction' : 'transactions'}',
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
              ),

              // Amount + percentage
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$currencySymbol${_formatAmount(category.totalActual)}',
                    style: AppTypography.amountSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // MONTH/YEAR TOGGLE
  // ──────────────────────────────────────────────

  Widget _buildViewToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizing.radiusFull),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Month button
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _isYearView = false;
                  _selectedCategoryIndex = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: !_isYearView ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSizing.radiusFull),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        size: 16,
                        color: !_isYearView
                            ? AppColors.background
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Month',
                        style: TextStyle(
                          color: !_isYearView
                              ? AppColors.background
                              : AppColors.textMuted,
                          fontWeight:
                              !_isYearView ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Year button
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _isYearView = true;
                  _selectedCategoryIndex = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _isYearView ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSizing.radiusFull),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.barChart3,
                        size: 16,
                        color: _isYearView
                            ? AppColors.background
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Year',
                        style: TextStyle(
                          color: _isYearView
                              ? AppColors.background
                              : AppColors.textMuted,
                          fontWeight:
                              _isYearView ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // BAR CHART (Year view only)
  // ──────────────────────────────────────────────

  Widget _buildBarChart(
    List<MonthlyBarData> monthlyData,
    String currencySymbol,
  ) {
    if (monthlyData.isEmpty) {
      return const SizedBox(height: AppSpacing.lg);
    }

    final maxExpense = monthlyData
        .map((d) => d.totalExpenses)
        .reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizing.radiusXl),
        ),
        height: 280,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxExpense > 0 ? maxExpense * 1.2 : 100,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => AppColors.surfaceLight,
                tooltipPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                tooltipMargin: 8,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final data = monthlyData[group.x.toInt()];
                  return BarTooltipItem(
                    '$currencySymbol${_formatAmount(data.totalExpenses)}',
                    const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= monthlyData.length) {
                      return const SizedBox.shrink();
                    }
                    // Show first 3 chars of month name (e.g., "Jan")
                    final name = monthlyData[index].monthName;
                    final abbr =
                        name.length >= 3 ? name.substring(0, 3) : name;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        abbr,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: monthlyData.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: data.totalExpenses,
                    color: AppColors.savings,
                    width: monthlyData.length <= 6 ? 28 : 16,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // YEARLY CATEGORIES LIST (Year view only)
  // ──────────────────────────────────────────────

  Widget _buildYearlyCategoryList(
    List<YearlyCategorySummary> summaries,
    double totalYearlyExpenses,
    String currencySymbol,
  ) {
    return Column(
      children: summaries.map((summary) {
        final percentage = totalYearlyExpenses > 0
            ? (summary.totalActual / totalYearlyExpenses * 100)
            : 0.0;

        return Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.sm,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md + 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizing.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                // Circular colored icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: summary.color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIcon(summary.icon),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Name + transaction count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.name,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${summary.transactionCount} ${summary.transactionCount == 1 ? 'transaction' : 'transactions'}',
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
                ),

                // Amount + percentage
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$currencySymbol${_formatAmount(summary.totalActual)}',
                      style: AppTypography.amountSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ──────────────────────────────────────────────
  // ADD BUTTON
  // ──────────────────────────────────────────────

  Widget _buildAddButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showAddSheet(),
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        child: Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizing.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.plus, color: AppColors.savings, size: 20),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Add Category',
                style: TextStyle(
                  color: AppColors.savings,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // EMPTY & ERROR STATES
  // ──────────────────────────────────────────────

  Widget _buildEmptyState() {
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
            LucideIcons.folderOpen,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'No expense categories yet',
            style: AppTypography.h3,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Add your first expense category to start budgeting',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: () => _showAddSheet(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.savings,
            ),
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('Add Category'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
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
      ),
    );
  }

  // ──────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return NumberFormat('#,##,###').format(amount.toInt());
    }
    return amount.toStringAsFixed(amount == amount.roundToDouble() ? 0 : 2);
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
    };
    return icons[iconName] ?? LucideIcons.wallet;
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CategoryFormSheet(),
    );
  }

  void _showEditSheet(Category category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryFormSheet(category: category),
    );
  }
}

// ──────────────────────────────────────────────
// CUSTOM DONUT CHART
// ──────────────────────────────────────────────

class _DonutSegment {
  final Color color;
  final double value;

  const _DonutSegment({required this.color, required this.value});
}

class _DonutChartPainter extends CustomPainter {
  final List<_DonutSegment> segments;
  final double strokeWidth;
  final double gapDegrees;
  final int? selectedIndex;
  final double selectedStrokeWidth;

  _DonutChartPainter({
    required this.segments,
    this.strokeWidth = 22,
    this.gapDegrees = 3.0,
    this.selectedIndex,
    this.selectedStrokeWidth = 28,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - selectedStrokeWidth) / 2;

    final total = segments.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0) return;

    final gapRad = gapDegrees * math.pi / 180;
    final totalGap = gapRad * segments.length;
    final availableSweep = 2 * math.pi - totalGap;

    // Start from top (-90°)
    double startAngle = -math.pi / 2;

    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final fraction = segment.value / total;
      final sweepAngle = fraction * availableSweep;
      final isSelected = i == selectedIndex;

      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? selectedStrokeWidth : strokeWidth
        ..strokeCap = StrokeCap.round;

      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

      startAngle += sweepAngle + gapRad;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.segments.length != segments.length;
  }
}
