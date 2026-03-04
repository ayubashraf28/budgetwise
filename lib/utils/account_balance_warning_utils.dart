import '../models/account.dart';
import '../models/transaction.dart';

bool shouldWarnNegativeBalance(AccountType type, double balance) {
  if (balance >= 0) return false;
  return type != AccountType.credit;
}

double transactionSignedAmount(TransactionType type, double amount) {
  return type == TransactionType.income ? amount : -amount;
}

Map<String, double> projectAccountBalancesAfterSubmit({
  required Map<String, double> currentBalances,
  required String selectedAccountId,
  required TransactionType transactionType,
  required double amount,
  Transaction? existingTransaction,
}) {
  final impacted = <String, double>{};

  final originalAccountId = existingTransaction?.accountId;
  if (originalAccountId != null && originalAccountId.isNotEmpty) {
    final originalBalance = currentBalances[originalAccountId] ?? 0;
    impacted[originalAccountId] = originalBalance -
        transactionSignedAmount(
          existingTransaction!.type,
          existingTransaction.amount,
        );
  }

  final nextBaseBalance =
      impacted[selectedAccountId] ?? currentBalances[selectedAccountId] ?? 0;
  impacted[selectedAccountId] =
      nextBaseBalance + transactionSignedAmount(transactionType, amount);

  return impacted;
}
