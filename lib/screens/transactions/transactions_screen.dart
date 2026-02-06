import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../models/monthly_summary.dart';
import '../../models/transaction.dart';
import '../../providers/providers.dart';
import '../../widgets/budget/budget_widgets.dart';
import 'transaction_form_sheet.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  TransactionType? _filterType; // null = all

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Filter transactions by search query and type filter
  List<Transaction> _applyFilters(List<Transaction> transactions) {
    var filtered = transactions;

    // Apply type filter
    if (_filterType != null) {
      filtered = filtered.where((t) => t.type == _filterType).toList();
    }

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((t) {
        final name = t.displayName.toLowerCase();
        final category = (t.categoryName ?? '').toLowerCase();
        final note = (t.note ?? '').toLowerCase();
        return name.contains(query) || category.contains(query) || note.contains(query);
      }).toList();
    }

    return filtered;
  }

  /// Group filtered transactions by date (descending)
  Map<DateTime, List<Transaction>> _groupByDate(List<Transaction> transactions) {
    final grouped = <DateTime, List<Transaction>>{};
    for (final tx in transactions) {
      final key = DateTime(tx.date.year, tx.date.month, tx.date.day);
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (var key in sortedKeys) key: grouped[key]!};
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final summary = ref.watch(monthlySummaryProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(transactionsProvider);
          ref.invalidate(incomeSourcesProvider);
          ref.invalidate(categoriesProvider);
        },
        child: transactionsAsync.when(
          data: (transactions) {
            final filtered = _applyFilters(transactions);
            final grouped = _groupByDate(filtered);

            return CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(child: _buildHeader()),

                // Search bar
                SliverToBoxAdapter(child: _buildSearchBar()),

                // Summary cards
                SliverToBoxAdapter(
                  child: _buildSummaryCards(summary, currencySymbol),
                ),

                // Net balance card
                SliverToBoxAdapter(
                  child: _buildNetBalanceCard(summary, currencySymbol),
                ),

                // Transactions header with count + Add button
                SliverToBoxAdapter(
                  child: _buildTransactionsHeader(filtered.length),
                ),

                // Transaction list or empty state
                if (filtered.isEmpty)
                  SliverToBoxAdapter(child: _buildEmptyState())
                else
                  ..._buildGroupedTransactions(grouped, currencySymbol),

                // Bottom padding
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
  // HEADER
  // ──────────────────────────────────────────────

  Widget _buildHeader() {
    return const SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transactions', style: AppTypography.h2),
            SizedBox(height: AppSpacing.xs),
            Text(
              'Track your income and expenses',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // SEARCH BAR
  // ──────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          // Search field
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search by name or category...',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                  prefixIcon: const Icon(
                    LucideIcons.search,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Filter button
          GestureDetector(
            onTap: _showFilterOptions,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _filterType != null ? AppColors.savings : AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                border: _filterType == null
                    ? Border.all(color: AppColors.border)
                    : null,
              ),
              child: Icon(
                LucideIcons.slidersHorizontal,
                size: 20,
                color: _filterType != null ? Colors.white : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizing.radiusXl),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text('Filter Transactions', style: AppTypography.h3),
                const SizedBox(height: AppSpacing.md),
                _buildFilterOption('All Transactions', null),
                _buildFilterOption('Income Only', TransactionType.income),
                _buildFilterOption('Expenses Only', TransactionType.expense),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String label, TransactionType? type) {
    final isSelected = _filterType == type;
    return ListTile(
      onTap: () {
        setState(() => _filterType = type);
        Navigator.pop(context);
      },
      leading: Icon(
        isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
        color: isSelected ? AppColors.savings : AppColors.textMuted,
        size: 20,
      ),
      title: Text(
        label,
        style: AppTypography.bodyLarge.copyWith(
          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // SUMMARY CARDS
  // ──────────────────────────────────────────────

  Widget _buildSummaryCards(MonthlySummary? summary, String currencySymbol) {
    final actualIncome = summary?.actualIncome ?? 0.0;
    final actualExpenses = summary?.actualExpenses ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          // Income card
          Expanded(
            child: _buildSummaryCard(
              title: 'Income',
              amount: actualIncome,
              currencySymbol: currencySymbol,
              icon: LucideIcons.trendingUp,
              color: AppColors.success,
              onTap: () => context.push('/income'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Expenses card
          Expanded(
            child: _buildSummaryCard(
              title: 'Expenses',
              amount: actualExpenses,
              currencySymbol: currencySymbol,
              icon: LucideIcons.trendingDown,
              color: AppColors.error,
              onTap: () => context.push('/expenses'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required String currencySymbol,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppSizing.radiusLg),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon + title row
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Amount
              Text(
                '$currencySymbol${_formatAmount(amount)}',
                style: AppTypography.amountMedium.copyWith(color: color),
              ),
              const SizedBox(height: 2),
              Text(
                'This month',
                style: TextStyle(
                  fontSize: 12,
                  color: color.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // NET BALANCE CARD
  // ──────────────────────────────────────────────

  Widget _buildNetBalanceCard(MonthlySummary? summary, String currencySymbol) {
    final netBalance = summary?.actualBalance ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: AppColors.tealGradient,
          borderRadius: BorderRadius.circular(AppSizing.radiusXl),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Net Balance This Month',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '$currencySymbol${_formatAmount(netBalance)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
              ),
              child: const Icon(
                LucideIcons.trendingUp,
                color: Colors.white,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // TRANSACTIONS HEADER
  // ──────────────────────────────────────────────

  Widget _buildTransactionsHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('All Transactions', style: AppTypography.h3),
              Text(
                '$count ${count == 1 ? 'transaction' : 'transactions'} found',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
          GestureDetector(
            onTap: () => _showAddSheet(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.savings,
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.plus, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Add',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // GROUPED TRANSACTION LIST
  // ──────────────────────────────────────────────

  List<Widget> _buildGroupedTransactions(
    Map<DateTime, List<Transaction>> grouped,
    String currencySymbol,
  ) {
    final slivers = <Widget>[];
    for (final entry in grouped.entries) {
      final date = entry.key;
      final transactions = entry.value;

      // Date header
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm,
            ),
            child: Text(
              _formatDateHeader(date),
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );

      // Transaction items in a card container
      slivers.add(
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizing.radiusLg),
            ),
            child: Column(
              children: transactions.asMap().entries.map((entry) {
                final txIndex = entry.key;
                final transaction = entry.value;
                final isLast = txIndex == transactions.length - 1;

                return Column(
                  children: [
                    Dismissible(
                      key: Key(transaction.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
                        ),
                        child: const Icon(LucideIcons.trash2, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await _showDeleteConfirmation();
                      },
                      onDismissed: (direction) {
                        ref
                            .read(transactionNotifierProvider.notifier)
                            .deleteTransaction(transaction.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Transaction deleted')),
                        );
                      },
                      child: TransactionListItem(
                        transaction: transaction,
                        currencySymbol: currencySymbol,
                        onTap: () => _showEditSheet(transaction),
                      ),
                    ),
                    if (!isLast)
                      const Divider(
                        height: 1,
                        indent: AppSpacing.md + 44 + AppSpacing.md,
                        color: AppColors.border,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      );
    }
    return slivers;
  }

  // ──────────────────────────────────────────────
  // EMPTY & ERROR STATES
  // ──────────────────────────────────────────────

  Widget _buildEmptyState() {
    final hasFilters = _searchQuery.isNotEmpty || _filterType != null;
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
          Icon(
            hasFilters ? LucideIcons.searchX : LucideIcons.receipt,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            hasFilters ? 'No matching transactions' : 'No transactions yet',
            style: AppTypography.h3,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            hasFilters
                ? 'Try adjusting your search or filter'
                : 'Add your first transaction to start tracking',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (!hasFilters) ...[
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => _showAddSheet(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.savings,
              ),
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Add Transaction'),
            ),
          ],
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

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == yesterday) return 'Yesterday';
    if (dateOnly.year == today.year) return DateFormat('d MMMM').format(date);
    return DateFormat('d MMMM yyyy').format(date);
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return NumberFormat('#,##,###').format(amount.toInt());
    }
    return amount.toStringAsFixed(0);
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TransactionFormSheet(),
    );
  }

  void _showEditSheet(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionFormSheet(transaction: transaction),
    );
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Delete Transaction?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
