import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/account.dart';
import '../models/account_transfer.dart';
import '../services/account_service.dart';
import '../services/transfer_service.dart';

final accountServiceProvider = Provider<AccountService>((ref) {
  return AccountService();
});

final transferServiceProvider = Provider<TransferService>((ref) {
  return TransferService();
});

final accountsProvider = FutureProvider<List<Account>>((ref) async {
  final service = ref.read(accountServiceProvider);
  var accounts = await service.getAccounts();
  if (accounts.isEmpty) {
    await service.ensureDefaultAccount();
    accounts = await service.getAccounts();
  }
  return accounts;
});

final allAccountsProvider = FutureProvider<List<Account>>((ref) async {
  final service = ref.read(accountServiceProvider);
  final activeAccounts = await service.getAccounts();
  if (activeAccounts.isEmpty) {
    await service.ensureDefaultAccount();
  }
  return service.getAccounts(includeArchived: true);
});

final accountBalancesProvider =
    FutureProvider<Map<String, double>>((ref) async {
  final service = ref.read(accountServiceProvider);
  return service.getAccountBalances();
});

final allAccountBalancesProvider =
    FutureProvider<Map<String, double>>((ref) async {
  final service = ref.read(accountServiceProvider);
  return service.getAccountBalances(includeArchived: true);
});

final netWorthProvider = FutureProvider<double>((ref) async {
  final service = ref.read(accountServiceProvider);
  return service.getNetWorth();
});

final accountTransfersProvider =
    FutureProvider<List<AccountTransfer>>((ref) async {
  final service = ref.read(transferServiceProvider);
  return service.getTransfers();
});

final transfersByAccountProvider =
    FutureProvider.family<List<AccountTransfer>, String>(
        (ref, accountId) async {
  final service = ref.read(transferServiceProvider);
  return service.getTransfers(accountId: accountId);
});

class AccountNotifier extends AsyncNotifier<List<Account>> {
  @override
  Future<List<Account>> build() async {
    final service = ref.read(accountServiceProvider);
    return service.getAccounts();
  }

  AccountService get _service => ref.read(accountServiceProvider);

  Future<Account> createAccount({
    required String name,
    required AccountType type,
    double openingBalance = 0,
    double? creditLimit,
    bool includeInNetWorth = true,
    int sortOrder = 0,
  }) async {
    final account = await _service.createAccount(
      name: name,
      type: type,
      openingBalance: openingBalance,
      creditLimit: creditLimit,
      includeInNetWorth: includeInNetWorth,
      sortOrder: sortOrder,
    );
    _invalidateAll();
    return account;
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
    final account = await _service.updateAccount(
      accountId: accountId,
      name: name,
      type: type,
      openingBalance: openingBalance,
      creditLimit: creditLimit,
      clearCreditLimit: clearCreditLimit,
      includeInNetWorth: includeInNetWorth,
      isArchived: isArchived,
      sortOrder: sortOrder,
    );
    _invalidateAll();
    return account;
  }

  Future<Account> archiveAccount(String accountId) async {
    final account = await _service.archiveAccount(accountId);
    _invalidateAll();
    return account;
  }

  Future<Account> unarchiveAccount(String accountId) async {
    final account = await _service.unarchiveAccount(accountId);
    _invalidateAll();
    return account;
  }

  Future<void> deleteAccount(String accountId) async {
    await _service.deleteAccount(accountId);
    _invalidateAll();
  }

  Future<void> reorderAccounts(List<String> orderedAccountIds) async {
    await _service.reorderAccounts(orderedAccountIds);
    _invalidateAll();
  }

  void _invalidateAll() {
    ref.invalidateSelf();
    ref.invalidate(accountsProvider);
    ref.invalidate(allAccountsProvider);
    ref.invalidate(accountBalancesProvider);
    ref.invalidate(allAccountBalancesProvider);
    ref.invalidate(netWorthProvider);
  }
}

final accountNotifierProvider =
    AsyncNotifierProvider<AccountNotifier, List<Account>>(
  () => AccountNotifier(),
);

class TransferNotifier extends AsyncNotifier<List<AccountTransfer>> {
  @override
  Future<List<AccountTransfer>> build() async {
    final service = ref.read(transferServiceProvider);
    return service.getTransfers();
  }

  TransferService get _service => ref.read(transferServiceProvider);

  Future<AccountTransfer> createTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    final transfer = await _service.createTransfer(
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      amount: amount,
      date: date,
      note: note,
    );
    _invalidateAll();
    return transfer;
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
    final transfer = await _service.updateTransfer(
      transferId: transferId,
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      amount: amount,
      date: date,
      note: note,
      clearNote: clearNote,
    );
    _invalidateAll();
    return transfer;
  }

  Future<void> deleteTransfer(String transferId) async {
    await _service.deleteTransfer(transferId);
    _invalidateAll();
  }

  void _invalidateAll() {
    ref.invalidateSelf();
    ref.invalidate(accountTransfersProvider);
    ref.invalidate(accountBalancesProvider);
    ref.invalidate(allAccountBalancesProvider);
    ref.invalidate(netWorthProvider);
  }
}

final transferNotifierProvider =
    AsyncNotifierProvider<TransferNotifier, List<AccountTransfer>>(
  () => TransferNotifier(),
);
