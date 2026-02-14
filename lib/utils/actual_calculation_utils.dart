import '../models/category.dart';
import '../models/income_source.dart';
import '../models/transaction.dart';

List<Category> withCategoryActuals(
  List<Category> categories,
  List<Transaction> transactions,
) {
  return categories.map((category) {
    final visibleItems = category.items?.where((item) => !item.isArchived);
    final updatedItems = visibleItems?.map((item) {
      final itemTransactions = transactions.where(
        (transaction) =>
            transaction.itemId == item.id &&
            transaction.type == TransactionType.expense,
      );
      final actual = itemTransactions.fold<double>(
        0.0,
        (sum, transaction) => sum + transaction.amount,
      );
      return item.copyWith(actual: actual);
    }).toList();

    return category.copyWith(items: updatedItems);
  }).toList();
}

List<IncomeSource> withIncomeSourceActuals(
  List<IncomeSource> sources,
  List<Transaction> transactions,
) {
  return sources.map((source) {
    final sourceTransactions = transactions.where(
      (transaction) =>
          transaction.incomeSourceId == source.id &&
          transaction.type == TransactionType.income,
    );
    final actual = sourceTransactions.fold<double>(
      0.0,
      (sum, transaction) => sum + transaction.amount,
    );
    return source.copyWith(actual: actual);
  }).toList();
}
