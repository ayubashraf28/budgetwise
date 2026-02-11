import 'package:uuid/uuid.dart';

import '../config/supabase_config.dart';
import '../models/transaction.dart';

class TransactionService {
  final _client = SupabaseConfig.client;
  static const _table = 'transactions';
  final _uuid = const Uuid();

  String get _userId => _client.auth.currentUser!.id;

  /// Select query with joins
  String get _selectWithJoins =>
      '*, categories(name, color, icon), items(name), subscriptions(name, icon), income_sources(name), accounts(name, type)';

  /// Get all transactions for a month
  Future<List<Transaction>> getTransactionsForMonth(String monthId) async {
    final response = await _client
        .from(_table)
        .select(_selectWithJoins)
        .eq('user_id', _userId)
        .eq('month_id', monthId)
        .order('date', ascending: false)
        .order('created_at', ascending: false);

    return (response as List).map((e) => Transaction.fromJson(e)).toList();
  }

  /// Get all transactions for multiple months (for yearly aggregation)
  Future<List<Transaction>> getTransactionsForMonths(
      List<String> monthIds) async {
    if (monthIds.isEmpty) return [];
    final response = await _client
        .from(_table)
        .select(_selectWithJoins)
        .eq('user_id', _userId)
        .inFilter('month_id', monthIds)
        .order('date', ascending: false);
    return (response as List).map((e) => Transaction.fromJson(e)).toList();
  }

  /// Get transactions for a specific item
  Future<List<Transaction>> getTransactionsForItem(String itemId) async {
    final response = await _client
        .from(_table)
        .select(_selectWithJoins)
        .eq('user_id', _userId)
        .eq('item_id', itemId)
        .order('date', ascending: false);

    return (response as List).map((e) => Transaction.fromJson(e)).toList();
  }

  /// Get transactions for a specific account
  Future<List<Transaction>> getTransactionsForAccount(String accountId) async {
    final response = await _client
        .from(_table)
        .select(_selectWithJoins)
        .eq('user_id', _userId)
        .eq('account_id', accountId)
        .order('date', ascending: false);

    return (response as List).map((e) => Transaction.fromJson(e)).toList();
  }

  /// Get transactions for a specific category
  Future<List<Transaction>> getTransactionsForCategory(
      String categoryId) async {
    final response = await _client
        .from(_table)
        .select(_selectWithJoins)
        .eq('user_id', _userId)
        .eq('category_id', categoryId)
        .order('date', ascending: false);

    return (response as List).map((e) => Transaction.fromJson(e)).toList();
  }

  /// Get transactions for a specific income source
  Future<List<Transaction>> getTransactionsForIncomeSource(
      String incomeSourceId) async {
    final response = await _client
        .from(_table)
        .select(_selectWithJoins)
        .eq('user_id', _userId)
        .eq('income_source_id', incomeSourceId)
        .order('date', ascending: false);

    return (response as List).map((e) => Transaction.fromJson(e)).toList();
  }

  /// Get a single transaction by ID
  Future<Transaction?> getTransactionById(String transactionId) async {
    final response = await _client
        .from(_table)
        .select(_selectWithJoins)
        .eq('id', transactionId)
        .eq('user_id', _userId)
        .maybeSingle();

    if (response == null) return null;
    return Transaction.fromJson(response);
  }

  /// Create an expense transaction
  Future<Transaction> createExpense({
    required String monthId,
    required String categoryId,
    required String itemId,
    String? subscriptionId,
    required String accountId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    final now = DateTime.now();
    final transaction = Transaction(
      id: _uuid.v4(),
      userId: _userId,
      monthId: monthId,
      categoryId: categoryId,
      itemId: itemId,
      subscriptionId: subscriptionId,
      accountId: accountId,
      type: TransactionType.expense,
      amount: amount,
      date: date,
      note: note,
      createdAt: now,
      updatedAt: now,
    );

    final response = await _client
        .from(_table)
        .insert(transaction.toJson())
        .select(_selectWithJoins)
        .single();

    return Transaction.fromJson(response);
  }

  /// Create an income transaction
  Future<Transaction> createIncome({
    required String monthId,
    required String incomeSourceId,
    required String accountId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    final now = DateTime.now();
    final transaction = Transaction(
      id: _uuid.v4(),
      userId: _userId,
      monthId: monthId,
      incomeSourceId: incomeSourceId,
      accountId: accountId,
      type: TransactionType.income,
      amount: amount,
      date: date,
      note: note,
      createdAt: now,
      updatedAt: now,
    );

    final response = await _client
        .from(_table)
        .insert(transaction.toJson())
        .select(_selectWithJoins)
        .single();

    return Transaction.fromJson(response);
  }

  /// Update a transaction
  Future<Transaction> updateTransaction({
    required String transactionId,
    String? categoryId,
    String? itemId,
    String? subscriptionId,
    String? incomeSourceId,
    String? accountId,
    double? amount,
    DateTime? date,
    String? note,
  }) async {
    final updates = <String, dynamic>{};
    if (categoryId != null) updates['category_id'] = categoryId;
    if (itemId != null) updates['item_id'] = itemId;
    if (subscriptionId != null) updates['subscription_id'] = subscriptionId;
    if (incomeSourceId != null) updates['income_source_id'] = incomeSourceId;
    if (accountId != null) {
      updates['account_id'] = accountId;
    }
    if (amount != null) updates['amount'] = amount;
    if (date != null) updates['date'] = _formatDate(date);
    if (note != null) updates['note'] = note;

    if (updates.isEmpty) {
      final current = await getTransactionById(transactionId);
      if (current == null) throw Exception('Transaction not found');
      return current;
    }

    final response = await _client
        .from(_table)
        .update(updates)
        .eq('id', transactionId)
        .eq('user_id', _userId)
        .select(_selectWithJoins)
        .single();

    return Transaction.fromJson(response);
  }

  /// Delete a transaction
  Future<void> deleteTransaction(String transactionId) async {
    await _client
        .from(_table)
        .delete()
        .eq('id', transactionId)
        .eq('user_id', _userId);
  }

  /// Get total expenses for a month
  Future<double> getTotalExpensesForMonth(String monthId) async {
    final transactions = await getTransactionsForMonth(monthId);
    return transactions
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  /// Get total income for a month
  Future<double> getTotalIncomeForMonth(String monthId) async {
    final transactions = await getTransactionsForMonth(monthId);
    return transactions
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  /// Get transactions by date range
  Future<List<Transaction>> getTransactionsByDateRange({
    required String monthId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _client
        .from(_table)
        .select(_selectWithJoins)
        .eq('user_id', _userId)
        .eq('month_id', monthId)
        .gte('date', _formatDate(startDate))
        .lte('date', _formatDate(endDate))
        .order('date', ascending: false);

    return (response as List).map((e) => Transaction.fromJson(e)).toList();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
