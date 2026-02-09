import '../config/supabase_config.dart';
import '../models/account.dart';

class AccountService {
  final _client = SupabaseConfig.client;
  static const _table = 'accounts';

  String get _userId => _client.auth.currentUser!.id;

  Future<String> _getProfileCurrency() async {
    final response = await _client
        .from('profiles')
        .select('currency')
        .eq('user_id', _userId)
        .maybeSingle();

    return response?['currency'] as String? ?? 'GBP';
  }

  Future<List<Account>> getAccounts({bool includeArchived = false}) async {
    var query = _client.from(_table).select().eq('user_id', _userId);

    if (!includeArchived) {
      query = query.eq('is_archived', false);
    }

    final response = await query
        .order('sort_order', ascending: true)
        .order('created_at', ascending: true);

    return (response as List).map((e) => Account.fromJson(e)).toList();
  }

  Future<Account?> getAccountById(String accountId) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('id', accountId)
        .eq('user_id', _userId)
        .maybeSingle();

    if (response == null) return null;
    return Account.fromJson(response);
  }

  Future<Account> createAccount({
    required String name,
    required AccountType type,
    double openingBalance = 0,
    double? creditLimit,
    bool includeInNetWorth = true,
    int sortOrder = 0,
  }) async {
    final currency = await _getProfileCurrency();

    final response = await _client
        .from(_table)
        .insert({
          'user_id': _userId,
          'name': name,
          'type': type.value,
          'currency': currency,
          'opening_balance': openingBalance,
          'credit_limit': creditLimit,
          'include_in_net_worth': includeInNetWorth,
          'is_archived': false,
          'sort_order': sortOrder,
        })
        .select()
        .single();

    return Account.fromJson(response);
  }

  Future<Account> updateAccount({
    required String accountId,
    String? name,
    AccountType? type,
    double? openingBalance,
    double? creditLimit,
    bool clearCreditLimit = false,
    bool? includeInNetWorth,
    bool? isArchived,
    int? sortOrder,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (type != null) updates['type'] = type.value;
    if (openingBalance != null) updates['opening_balance'] = openingBalance;
    if (clearCreditLimit) {
      updates['credit_limit'] = null;
    } else if (creditLimit != null) {
      updates['credit_limit'] = creditLimit;
    }
    if (includeInNetWorth != null) {
      updates['include_in_net_worth'] = includeInNetWorth;
    }
    if (isArchived != null) updates['is_archived'] = isArchived;
    if (sortOrder != null) updates['sort_order'] = sortOrder;

    if (updates.isEmpty) {
      final current = await getAccountById(accountId);
      if (current == null) throw Exception('Account not found');
      return current;
    }

    final response = await _client
        .from(_table)
        .update(updates)
        .eq('id', accountId)
        .eq('user_id', _userId)
        .select()
        .single();

    return Account.fromJson(response);
  }

  Future<Account> archiveAccount(String accountId) {
    return updateAccount(accountId: accountId, isArchived: true);
  }

  Future<Account> unarchiveAccount(String accountId) {
    return updateAccount(accountId: accountId, isArchived: false);
  }

  Future<void> deleteAccount(String accountId) async {
    final txUsage = await _client
        .from('transactions')
        .select('id')
        .eq('user_id', _userId)
        .eq('account_id', accountId)
        .limit(1);
    if ((txUsage as List).isNotEmpty) {
      throw Exception(
          'Cannot delete account with transaction history. Archive it instead.');
    }

    final fromUsage = await _client
        .from('account_transfers')
        .select('id')
        .eq('user_id', _userId)
        .eq('from_account_id', accountId)
        .limit(1);
    if ((fromUsage as List).isNotEmpty) {
      throw Exception(
          'Cannot delete account with transfer history. Archive it instead.');
    }

    final toUsage = await _client
        .from('account_transfers')
        .select('id')
        .eq('user_id', _userId)
        .eq('to_account_id', accountId)
        .limit(1);
    if ((toUsage as List).isNotEmpty) {
      throw Exception(
          'Cannot delete account with transfer history. Archive it instead.');
    }

    await _client
        .from(_table)
        .delete()
        .eq('id', accountId)
        .eq('user_id', _userId);
  }

  Future<void> reorderAccounts(List<String> orderedAccountIds) async {
    for (var i = 0; i < orderedAccountIds.length; i++) {
      await _client
          .from(_table)
          .update({'sort_order': i})
          .eq('id', orderedAccountIds[i])
          .eq('user_id', _userId);
    }
  }

  Future<Map<String, double>> getAccountBalances({
    bool includeArchived = false,
  }) async {
    final accounts = await getAccounts(includeArchived: includeArchived);
    if (accounts.isEmpty) return {};

    final balances = <String, double>{
      for (final account in accounts) account.id: account.openingBalance,
    };

    final accountIds = accounts.map((a) => a.id).toList();

    final txResponse = await _client
        .from('transactions')
        .select('account_id, type, amount')
        .eq('user_id', _userId)
        .inFilter('account_id', accountIds);

    for (final raw in txResponse as List) {
      final accountId = raw['account_id'] as String?;
      if (accountId == null || !balances.containsKey(accountId)) continue;

      final amount = (raw['amount'] as num).toDouble();
      final type = raw['type'] as String;
      if (type == 'income') {
        balances[accountId] = balances[accountId]! + amount;
      } else if (type == 'expense') {
        balances[accountId] = balances[accountId]! - amount;
      }
    }

    final transferResponse = await _client
        .from('account_transfers')
        .select('from_account_id, to_account_id, amount')
        .eq('user_id', _userId);

    for (final raw in transferResponse as List) {
      final fromAccountId = raw['from_account_id'] as String;
      final toAccountId = raw['to_account_id'] as String;
      final amount = (raw['amount'] as num).toDouble();

      if (balances.containsKey(fromAccountId)) {
        balances[fromAccountId] = balances[fromAccountId]! - amount;
      }
      if (balances.containsKey(toAccountId)) {
        balances[toAccountId] = balances[toAccountId]! + amount;
      }
    }

    return balances;
  }

  Future<double> getAccountBalance(String accountId) async {
    final balances = await getAccountBalances(includeArchived: true);
    return balances[accountId] ?? 0;
  }

  Future<double> getNetWorth() async {
    final accounts = await getAccounts(includeArchived: false);
    if (accounts.isEmpty) return 0;

    final balances = await getAccountBalances(includeArchived: false);
    return accounts
        .where((a) => a.includeInNetWorth)
        .fold<double>(0, (sum, a) => sum + (balances[a.id] ?? 0));
  }

  /// Ensure the user has at least one active account.
  /// Returns the first active account (existing or newly created).
  Future<Account> ensureDefaultAccount() async {
    final existing = await getAccounts(includeArchived: false);
    if (existing.isNotEmpty) return existing.first;

    final currency = await _getProfileCurrency();

    try {
      final response = await _client
          .from(_table)
          .insert({
            'user_id': _userId,
            'name': 'Cash',
            'type': AccountType.cash.value,
            'currency': currency,
            'opening_balance': 0,
            'credit_limit': null,
            'include_in_net_worth': true,
            'is_archived': false,
            'sort_order': 0,
          })
          .select()
          .single();

      return Account.fromJson(response);
    } catch (_) {
      // Handle concurrent creation race by reloading.
      final reloaded = await getAccounts(includeArchived: false);
      if (reloaded.isNotEmpty) return reloaded.first;
      rethrow;
    }
  }
}
