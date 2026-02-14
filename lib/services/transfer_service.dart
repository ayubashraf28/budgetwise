import '../config/supabase_config.dart';
import '../models/account_transfer.dart';
import '../utils/errors/app_error.dart';

class TransferService {
  final _client = SupabaseConfig.client;
  static const _table = 'account_transfers';

  String get _userId {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppError.unauthenticated();
    }
    return userId;
  }

  String get _selectWithJoins =>
      '*, from_account:accounts!account_transfers_from_account_id_fkey(name, type), to_account:accounts!account_transfers_to_account_id_fkey(name, type)';

  Future<List<AccountTransfer>> getTransfers({
    DateTime? startDate,
    DateTime? endDate,
    String? accountId,
  }) async {
    var query =
        _client.from(_table).select(_selectWithJoins).eq('user_id', _userId);

    if (startDate != null) {
      query = query.gte('date', _formatDate(startDate));
    }
    if (endDate != null) {
      query = query.lte('date', _formatDate(endDate));
    }
    if (accountId != null) {
      query =
          query.or('from_account_id.eq.$accountId,to_account_id.eq.$accountId');
    }

    final response = await query
        .order('date', ascending: false)
        .order('created_at', ascending: false);

    return (response as List).map((e) => AccountTransfer.fromJson(e)).toList();
  }

  Future<AccountTransfer?> getTransferById(String transferId) async {
    final response = await _client
        .from(_table)
        .select(_selectWithJoins)
        .eq('id', transferId)
        .eq('user_id', _userId)
        .maybeSingle();

    if (response == null) return null;
    return AccountTransfer.fromJson(response);
  }

  Future<AccountTransfer> createTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    final response = await _client
        .from(_table)
        .insert({
          'user_id': _userId,
          'from_account_id': fromAccountId,
          'to_account_id': toAccountId,
          'amount': amount,
          'date': _formatDate(date),
          'note': note,
        })
        .select(_selectWithJoins)
        .single();

    return AccountTransfer.fromJson(response);
  }

  Future<AccountTransfer> updateTransfer({
    required String transferId,
    String? fromAccountId,
    String? toAccountId,
    double? amount,
    DateTime? date,
    String? note,
    bool clearNote = false,
  }) async {
    final updates = <String, dynamic>{};
    if (fromAccountId != null) updates['from_account_id'] = fromAccountId;
    if (toAccountId != null) updates['to_account_id'] = toAccountId;
    if (amount != null) updates['amount'] = amount;
    if (date != null) updates['date'] = _formatDate(date);
    if (clearNote) {
      updates['note'] = null;
    } else if (note != null) {
      updates['note'] = note;
    }

    if (updates.isEmpty) {
      final current = await getTransferById(transferId);
      if (current == null) {
        throw const AppError.notFound(
          technicalMessage: 'Transfer not found',
        );
      }
      return current;
    }

    final response = await _client
        .from(_table)
        .update(updates)
        .eq('id', transferId)
        .eq('user_id', _userId)
        .select(_selectWithJoins)
        .single();

    return AccountTransfer.fromJson(response);
  }

  Future<void> deleteTransfer(String transferId) async {
    await _client
        .from(_table)
        .delete()
        .eq('id', transferId)
        .eq('user_id', _userId);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
