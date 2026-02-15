part of 'transaction_form_sheet.dart';

extension _TransactionFormSheetSubmit on _TransactionFormSheetState {
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: NeoTheme.negativeValue(context),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final isSimpleMode = ref.read(isSimpleBudgetModeProvider);
    final activeAccounts = await ref.read(accountsProvider.future);
    final currencyCode = ref.read(currencyProvider);
    if (!mounted) return;

    if (activeAccounts.isEmpty) {
      _showError('Create an account first from Settings > Accounts');
      return;
    }

    final accountId = _selectedAccountId ?? activeAccounts.first.id;
    final decimalPlaces = InputValidator.decimalPlacesForCurrency(currencyCode);
    final amount = InputValidator.normalizeAmount(_resolveAmountForSubmit(),
        decimalPlaces: decimalPlaces);
    final amountError = InputValidator.validatePositiveAmountValue(
      amount,
      currencyCode: currencyCode,
    );
    if (amountError != null) {
      _showError(amountError);
      return;
    }

    final dateError = InputValidator.validateTransactionDate(_selectedDate);
    if (dateError != null) {
      _showError(dateError);
      return;
    }

    final note = _noteController.text.trim();
    final noteError = InputValidator.validateNoteLength(
      note,
      fieldName: 'Note',
      maxLength: InputValidator.maxTransactionNoteLength,
    );
    if (noteError != null) {
      _showError(noteError);
      return;
    }

    String? expenseItemId = _selectedItemId;
    if (_transactionType == TransactionType.expense) {
      if (_selectedCategoryId == null) {
        _showError('Select a category');
        return;
      }
      if (expenseItemId == null && isSimpleMode) {
        expenseItemId = await _ensureSimpleModeItemIdForCategory(
          categoryId: _selectedCategoryId!,
        );
        if (expenseItemId != null && mounted) {
          _updateState(() => _selectedItemId = expenseItemId);
        }
      }
      if (expenseItemId == null) {
        _showError('Select an item');
        return;
      }
    } else {
      if (_selectedIncomeSourceId == null) {
        _showError('Select an income source');
        return;
      }
    }

    _updateState(() => _isLoading = true);

    try {
      final notifier = ref.read(transactionNotifierProvider.notifier);

      if (isEditing) {
        if (_transactionType == TransactionType.expense) {
          await notifier.updateTransaction(
            transactionId: widget.transaction!.id,
            categoryId: _selectedCategoryId,
            itemId: expenseItemId,
            accountId: accountId,
            amount: amount,
            date: _selectedDate,
            note: note.isEmpty ? null : note,
          );
        } else {
          await notifier.updateTransaction(
            transactionId: widget.transaction!.id,
            incomeSourceId: _selectedIncomeSourceId,
            accountId: accountId,
            amount: amount,
            date: _selectedDate,
            note: note.isEmpty ? null : note,
          );
        }
      } else {
        if (_transactionType == TransactionType.expense) {
          await notifier.addExpense(
            categoryId: _selectedCategoryId!,
            itemId: expenseItemId!,
            accountId: accountId,
            amount: amount,
            date: _selectedDate,
            note: note.isEmpty ? null : note,
          );
        } else {
          await notifier.addIncome(
            incomeSourceId: _selectedIncomeSourceId!,
            accountId: accountId,
            amount: amount,
            date: _selectedDate,
            note: note.isEmpty ? null : note,
          );
        }
      }

      if (!mounted) return;

      ref.invalidate(categoriesProvider);
      await ref.read(categoriesProvider.future);
      ref.invalidate(incomeSourcesProvider);
      await ref.read(incomeSourcesProvider.future);

      if (_selectedCategoryId != null) {
        ref.invalidate(categoryByIdProvider(_selectedCategoryId!));
        await ref.read(categoryByIdProvider(_selectedCategoryId!).future);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(isEditing ? 'Transaction updated' : 'Transaction added'),
        ),
      );
    } catch (error, stackTrace) {
      if (!mounted) return;
      _showError(ErrorMapper.toUserMessage(error, stackTrace: stackTrace));
    } finally {
      if (mounted) {
        _updateState(() => _isLoading = false);
      }
    }
  }
}
