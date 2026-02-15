part of 'transaction_form_sheet.dart';

extension _TransactionFormSheetPickers on _TransactionFormSheetState {
  Future<void> _pickAccount(List<Account> accounts) async {
    if (accounts.isEmpty) {
      _showError('Create an account first from Settings > Accounts');
      return;
    }

    final selectedId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final palette = NeoTheme.of(context);
        return SelectionPickerSheet<String>(
          title: 'Select Account',
          selectedValue: _selectedAccountId,
          options: accounts
              .map(
                (account) => SelectionPickerOption<String>(
                  value: account.id,
                  label: account.isArchived
                      ? '${account.name} (Archived)'
                      : account.name,
                  subtitle: account.isArchived ? 'Archived' : null,
                  icon: _getAccountTypeIcon(account.type),
                  iconColor: account.isArchived
                      ? palette.textMuted
                      : NeoTheme.infoValue(context),
                ),
              )
              .toList(),
        );
      },
    );

    if (selectedId != null && mounted) {
      _updateState(() => _selectedAccountId = selectedId);
    }
  }

  Future<void> _pickCategoryAndItem(
    List<Category> categories, {
    required bool isSimpleMode,
  }) async {
    final previousCategoryId = _selectedCategoryId;
    final selectedCategoryId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SelectionPickerSheet<String>(
        title: 'Select Category',
        selectedValue: _selectedCategoryId,
        addNewLabel: 'Add New Category',
        onAddNew: () => _handleAddCategory(context),
        emptyLabel: 'No categories yet. Add one to continue.',
        options: categories
            .map(
              (category) => SelectionPickerOption<String>(
                value: category.id,
                label: category.name,
                icon: _getCategoryIcon(category.icon),
                iconColor: Colors.white,
                iconBackgroundColor: category.colorValue,
              ),
            )
            .toList(),
      ),
    );

    if (!mounted || selectedCategoryId == null) return;

    final selectedCategory =
        categories.where((c) => c.id == selectedCategoryId).firstOrNull;
    if (selectedCategory == null) return;

    if (isSimpleMode) {
      String? itemId = _selectedItemId;
      final keepCurrentItem = isEditing &&
          previousCategoryId == selectedCategoryId &&
          _selectedItemId != null;

      if (!keepCurrentItem) {
        itemId = await _ensureSimpleModeItemIdForCategory(
          categoryId: selectedCategoryId,
          categoryNameHint: selectedCategory.name,
        );
      }

      if (!mounted) return;
      _updateState(() {
        _selectedCategoryId = selectedCategoryId;
        _selectedItemId = itemId;
      });
      return;
    }

    final initialItemId =
        previousCategoryId == selectedCategoryId ? _selectedItemId : null;

    _updateState(() {
      _selectedCategoryId = selectedCategoryId;
      if (previousCategoryId != selectedCategoryId) {
        _selectedItemId = null;
      }
    });

    final selectedItemId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SelectionPickerSheet<String>(
        title: 'Select Item',
        selectedValue: initialItemId,
        addNewLabel: 'Add New Item',
        onAddNew: () =>
            _handleAddItem(context, categoryId: selectedCategory.id),
        emptyLabel: 'No items yet. Add one to continue.',
        options: (selectedCategory.items ?? <Item>[])
            .map(
              (item) => SelectionPickerOption<String>(
                value: item.id,
                label: item.name,
                icon: LucideIcons.tag,
                iconColor: NeoTheme.of(context).textSecondary,
              ),
            )
            .toList(),
      ),
    );

    if (selectedItemId != null && mounted) {
      _updateState(() => _selectedItemId = selectedItemId);
    }
  }

  Future<String?> _ensureSimpleModeItemIdForCategory({
    required String categoryId,
    String? categoryNameHint,
  }) async {
    final loadedCategories = ref.read(categoriesProvider).value;
    final List<Category> categories = loadedCategories ??
        await ref.read(categoriesProvider.future) ??
        <Category>[];
    final category = categories.where((c) => c.id == categoryId).firstOrNull;
    final currentItemId = category?.items?.firstOrNull?.id;
    if (currentItemId != null) return currentItemId;

    final service = ref.read(itemServiceProvider);
    final createdOrExisting = await service.ensureDefaultItemForCategory(
      categoryId: categoryId,
      categoryName: category?.name ?? categoryNameHint ?? 'Category',
      isBudgeted: category?.isBudgeted ?? true,
      projected: category?.budgetAmount ?? category?.totalProjected ?? 0,
    );

    ref.invalidate(categoriesProvider);
    final refreshed = await ref.read(categoriesProvider.future);
    final refreshedCategory =
        refreshed.where((c) => c.id == categoryId).firstOrNull;
    return refreshedCategory?.items?.firstOrNull?.id ?? createdOrExisting.id;
  }

  Future<void> _pickIncomeSource(List<IncomeSource> incomeSources) async {
    final selectedId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SelectionPickerSheet<String>(
        title: 'Select Source',
        selectedValue: _selectedIncomeSourceId,
        addNewLabel: 'Add New Source',
        onAddNew: () => _handleAddIncomeSource(context),
        emptyLabel: 'No income sources yet. Add one to continue.',
        options: incomeSources
            .map(
              (source) => SelectionPickerOption<String>(
                value: source.id,
                label: source.name,
                icon: LucideIcons.wallet,
                iconColor: NeoTheme.positiveValue(context),
              ),
            )
            .toList(),
      ),
    );

    if (selectedId != null && mounted) {
      _updateState(() => _selectedIncomeSourceId = selectedId);
    }
  }

  Future<void> _selectDate() async {
    final palette = NeoTheme.of(context);
    final baseTheme = Theme.of(context);
    final now = DateTime.now();
    final firstDate = InputValidator.minTransactionDate;
    final lastDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(InputValidator.maxFutureTransactionOffset);
    var initialDate = _selectedDate;
    if (initialDate.isBefore(firstDate)) {
      initialDate = firstDate;
    } else if (initialDate.isAfter(lastDate)) {
      initialDate = lastDate;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: baseTheme.copyWith(
            colorScheme: baseTheme.colorScheme.copyWith(
              primary: palette.accent,
              onPrimary: Colors.white,
              surface: palette.surface1,
              onSurface: palette.textPrimary,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: palette.surface1,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) return;
    _updateState(() {
      _selectedDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _selectedDate.hour,
        _selectedDate.minute,
      );
    });
  }

  Future<void> _selectTime() async {
    final palette = NeoTheme.of(context);
    final baseTheme = Theme.of(context);

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
      builder: (context, child) {
        return Theme(
          data: baseTheme.copyWith(
            colorScheme: baseTheme.colorScheme.copyWith(
              primary: palette.accent,
              onPrimary: Colors.white,
              surface: palette.surface1,
              onSurface: palette.textPrimary,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: palette.surface1,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) return;
    _updateState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _handleAddCategory(BuildContext context) async {
    final newCategoryId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CategoryFormSheet(),
    );

    if (newCategoryId == null || !mounted) return;

    ref.invalidate(categoriesProvider);
    await ref.read(categoriesProvider.future);
    if (!mounted) return;

    String? resolvedItemId;
    if (ref.read(isSimpleBudgetModeProvider) &&
        _transactionType == TransactionType.expense) {
      final categories = ref.read(categoriesProvider).value ?? <Category>[];
      final category =
          categories.where((c) => c.id == newCategoryId).firstOrNull;
      resolvedItemId = await _ensureSimpleModeItemIdForCategory(
        categoryId: newCategoryId,
        categoryNameHint: category?.name,
      );
      if (!mounted) return;
    }

    _updateState(() {
      _selectedCategoryId = newCategoryId;
      _selectedItemId = resolvedItemId;
    });
  }

  Future<void> _handleAddItem(
    BuildContext context, {
    required String categoryId,
  }) async {
    final newItemId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ItemFormSheet(
        categoryId: categoryId,
      ),
    );

    if (newItemId == null || !mounted) return;

    ref.invalidate(categoriesProvider);
    await ref.read(categoriesProvider.future);
    if (!mounted) return;

    _updateState(() {
      _selectedCategoryId = categoryId;
      _selectedItemId = newItemId;
    });
  }

  Future<void> _handleAddIncomeSource(BuildContext context) async {
    final newSourceId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const IncomeFormSheet(),
    );

    if (newSourceId == null || !mounted) return;

    ref.invalidate(incomeSourcesProvider);
    await ref.read(incomeSourcesProvider.future);
    if (!mounted) return;

    _updateState(() => _selectedIncomeSourceId = newSourceId);
  }

  IconData _getCategoryIcon(String iconName) {
    return resolveAppIcon(iconName, fallback: LucideIcons.wallet);
  }

  IconData _getAccountTypeIcon(AccountType accountType) {
    switch (accountType) {
      case AccountType.cash:
        return LucideIcons.wallet;
      case AccountType.debit:
        return LucideIcons.creditCard;
      case AccountType.credit:
        return LucideIcons.landmark;
      case AccountType.savings:
        return LucideIcons.piggyBank;
      case AccountType.other:
        return LucideIcons.circleDollarSign;
    }
  }
}
