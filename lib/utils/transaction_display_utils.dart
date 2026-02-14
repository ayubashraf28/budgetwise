import '../models/transaction.dart';

String transactionPrimaryLabel(
  Transaction transaction, {
  required bool isSimpleMode,
}) {
  if (!isSimpleMode) return transaction.displayName;

  final trimmedNote = transaction.note?.trim();
  if (trimmedNote != null && trimmedNote.isNotEmpty) {
    return trimmedNote;
  }

  if (transaction.isIncome) {
    final source = transaction.incomeSourceName?.trim();
    return (source != null && source.isNotEmpty) ? source : 'Income';
  }

  final category = transaction.categoryName?.trim();
  return (category != null && category.isNotEmpty) ? category : 'Expense';
}
