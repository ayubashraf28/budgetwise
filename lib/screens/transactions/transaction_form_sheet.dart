import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../models/account.dart';
import '../../models/category.dart';
import '../../models/income_source.dart';
import '../../models/item.dart';
import '../../models/transaction.dart';
import '../../providers/providers.dart';
import '../../utils/app_icon_registry.dart';
import '../../widgets/common/calculator_keypad.dart';
import '../../widgets/common/selection_picker_sheet.dart';
import '../expenses/category_form_sheet.dart';
import '../expenses/item_form_sheet.dart';
import '../income/income_form_sheet.dart';

class TransactionFormSheet extends ConsumerStatefulWidget {
  final Transaction? transaction;
  final String? initialCategoryId;

  const TransactionFormSheet({
    super.key,
    this.transaction,
    this.initialCategoryId,
  });

  @override
  ConsumerState<TransactionFormSheet> createState() =>
      _TransactionFormSheetState();
}

class _TransactionFormSheetState extends ConsumerState<TransactionFormSheet> {
  late final TextEditingController _noteController;

  late TransactionType _transactionType;
  String? _selectedCategoryId;
  String? _selectedItemId;
  String? _selectedIncomeSourceId;
  String? _selectedAccountId;
  late DateTime _selectedDate;
  bool _isLoading = false;

  String _displayValue = '0';
  double _runningTotal = 0;
  String? _pendingOperator;
  bool _shouldResetDisplay = false;

  bool get isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    final initialAmount = tx?.amount ?? 0;

    _noteController = TextEditingController(text: tx?.note ?? '');
    _transactionType = tx?.type ?? TransactionType.expense;
    _selectedCategoryId = tx?.categoryId ?? widget.initialCategoryId;
    _selectedItemId = tx?.itemId;
    _selectedIncomeSourceId = tx?.incomeSourceId;
    _selectedAccountId = tx?.accountId;
    _selectedDate = tx?.date ?? DateTime.now();

    _displayValue = _formatDisplayNumber(initialAmount);
    _runningTotal = initialAmount;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);
    final isSimpleMode = ref.watch(isSimpleBudgetModeProvider);
    final categories = ref.watch(categoriesProvider).value ?? <Category>[];
    final incomeSources =
        ref.watch(incomeSourcesProvider).value ?? <IncomeSource>[];
    final allAccounts = ref.watch(allAccountsProvider).value ?? <Account>[];
    final currencySymbol = ref.watch(currencySymbolProvider);

    final activeAccounts = allAccounts.where((a) => !a.isArchived).toList();
    final formAccounts = <Account>[...activeAccounts];

    if (_selectedAccountId != null &&
        !formAccounts.any((a) => a.id == _selectedAccountId)) {
      final selectedAccount =
          allAccounts.where((a) => a.id == _selectedAccountId).firstOrNull;
      if (selectedAccount != null) {
        formAccounts.insert(0, selectedAccount);
      }
    }

    final safeCategoryId = (_selectedCategoryId != null &&
            categories.any((c) => c.id == _selectedCategoryId))
        ? _selectedCategoryId
        : null;
    final safeIncomeSourceId = (_selectedIncomeSourceId != null &&
            incomeSources.any((s) => s.id == _selectedIncomeSourceId))
        ? _selectedIncomeSourceId
        : null;
    final safeAccountId = (_selectedAccountId != null &&
            formAccounts.any((a) => a.id == _selectedAccountId))
        ? _selectedAccountId
        : null;

    List<Item> items = <Item>[];
    if (safeCategoryId != null) {
      final category =
          categories.where((c) => c.id == safeCategoryId).firstOrNull;
      items = category?.items ?? <Item>[];
    }

    final canKeepEditingSimpleModeItem = isSimpleMode &&
        isEditing &&
        safeCategoryId == widget.transaction?.categoryId &&
        _selectedItemId == widget.transaction?.itemId &&
        _selectedItemId != null;
    final safeItemId = (_selectedItemId != null &&
                items.any((i) => i.id == _selectedItemId)) ||
            canKeepEditingSimpleModeItem
        ? _selectedItemId
        : null;

    if (safeCategoryId != _selectedCategoryId ||
        safeItemId != _selectedItemId ||
        safeIncomeSourceId != _selectedIncomeSourceId ||
        safeAccountId != _selectedAccountId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedCategoryId = safeCategoryId;
          _selectedItemId = safeItemId;
          _selectedIncomeSourceId = safeIncomeSourceId;
          _selectedAccountId = safeAccountId;
        });
      });
    }

    if (!isEditing && _selectedAccountId == null && activeAccounts.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _selectedAccountId != null) return;
        setState(() => _selectedAccountId = activeAccounts.first.id);
      });
    }

    final selectedAccount =
        formAccounts.where((a) => a.id == safeAccountId).firstOrNull;
    final selectedCategory =
        categories.where((c) => c.id == safeCategoryId).firstOrNull;
    final selectedItem = items.where((i) => i.id == safeItemId).firstOrNull;
    final selectedIncomeSource =
        incomeSources.where((s) => s.id == safeIncomeSourceId).firstOrNull;

    final categoryPillValue = selectedCategory == null
        ? 'Category'
        : isSimpleMode
            ? selectedCategory.name
            : selectedItem == null
                ? selectedCategory.name
                : '${selectedCategory.name} - ${selectedItem.name}';
    final sourcePillValue = selectedIncomeSource?.name ?? 'Source';
    final accountPillValue = selectedAccount == null
        ? 'Account'
        : selectedAccount.isArchived
            ? '${selectedAccount.name} (Archived)'
            : selectedAccount.name;

    return Container(
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSizing.radiusXl),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.94,
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _buildTopBar(),
                  const SizedBox(height: AppSpacing.md),
                  _buildTypeToggle(),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSelectorPill(
                          icon: LucideIcons.landmark,
                          label: 'Account',
                          value: accountPillValue,
                          onTap: _isLoading
                              ? null
                              : () => _pickAccount(formAccounts),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _buildSelectorPill(
                          icon: _transactionType == TransactionType.expense
                              ? LucideIcons.tag
                              : LucideIcons.wallet,
                          label: _transactionType == TransactionType.expense
                              ? 'Category'
                              : 'Source',
                          value: _transactionType == TransactionType.expense
                              ? categoryPillValue
                              : sourcePillValue,
                          onTap: _isLoading
                              ? null
                              : () {
                                  if (_transactionType ==
                                      TransactionType.expense) {
                                    _pickCategoryAndItem(
                                      categories,
                                      isSimpleMode: isSimpleMode,
                                    );
                                  } else {
                                    _pickIncomeSource(incomeSources);
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                  if (activeAccounts.isEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'No active accounts found. Add one in Settings > Accounts.',
                        style: AppTypography.bodySmall.copyWith(
                          color: NeoTheme.negativeValue(context),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  _buildNotesField(),
                  const Spacer(),
                  CalculatorKeypad(
                    displayValue: _displayValue,
                    activeOperator: _pendingOperator,
                    currencySymbol: currencySymbol,
                    onDigit: _handleDigit,
                    onOperator: _handleOperator,
                    onEquals: _handleEquals,
                    onBackspace: _handleBackspace,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildBottomBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final palette = NeoTheme.of(context);
    return Row(
      children: [
        TextButton.icon(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          icon: const Icon(LucideIcons.x, size: AppSizing.iconSm),
          label: Text(
            'CANCEL',
            style: AppTypography.labelLarge.copyWith(letterSpacing: 0.2),
          ),
          style: TextButton.styleFrom(
            foregroundColor: palette.textSecondary,
          ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: _isLoading ? null : _handleSubmit,
          icon: _isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: palette.accent,
                  ),
                )
              : const Icon(LucideIcons.check, size: AppSizing.iconSm),
          label: Text(
            _isLoading ? 'SAVING' : 'SAVE',
            style: AppTypography.labelLarge.copyWith(letterSpacing: 0.2),
          ),
          style: TextButton.styleFrom(
            foregroundColor: palette.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeToggle() {
    final palette = NeoTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.surface2,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeSegment(
              label: 'INCOME',
              isSelected: _transactionType == TransactionType.income,
              onTap: () {
                setState(() {
                  _transactionType = TransactionType.income;
                  _selectedCategoryId = null;
                  _selectedItemId = null;
                });
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildTypeSegment(
              label: 'EXPENSE',
              isSelected: _transactionType == TransactionType.expense,
              onTap: () {
                setState(() {
                  _transactionType = TransactionType.expense;
                  _selectedIncomeSourceId = null;
                });
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildTypeSegment(
              label: 'TRANSFER',
              isSelected: false,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming Soon')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSegment({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final palette = NeoTheme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppSizing.radiusSm),
      onTap: _isLoading ? null : onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? NeoTheme.controlSelectedBackground(context)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizing.radiusSm),
          border: Border.all(
            color: isSelected
                ? NeoTheme.controlSelectedBorder(context)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              Icon(
                LucideIcons.check,
                size: AppSizing.iconXs,
                color: NeoTheme.controlSelectedForeground(context),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected
                    ? NeoTheme.controlSelectedForeground(context)
                    : palette.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorPill({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback? onTap,
  }) {
    final palette = NeoTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: palette.surface2,
            borderRadius: BorderRadius.circular(AppSizing.radiusMd),
            border: Border.all(color: palette.stroke),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: AppSizing.iconSm,
                color: palette.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyLarge.copyWith(
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                LucideIcons.chevronDown,
                size: AppSizing.iconSm,
                color: palette.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    final palette = NeoTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: palette.surface2,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
      ),
      child: TextField(
        controller: _noteController,
        minLines: 1,
        maxLines: 2,
        style: AppTypography.bodyLarge.copyWith(
          color: palette.textPrimary,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          isCollapsed: true,
          hintText: 'Add notes',
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: palette.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final palette = NeoTheme.of(context);
    return Container(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: palette.stroke.withValues(alpha: 0.8)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildBottomAction(
              icon: LucideIcons.calendar,
              value: DateFormat('MMM d, yyyy').format(_selectedDate),
              onTap: _isLoading ? null : _selectDate,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildBottomAction(
              icon: LucideIcons.clock3,
              value: DateFormat('h:mm a').format(_selectedDate),
              onTap: _isLoading ? null : _selectTime,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction({
    required IconData icon,
    required String value,
    required VoidCallback? onTap,
  }) {
    final palette = NeoTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizing.radiusSm),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizing.radiusSm),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: AppSizing.iconSm,
                color: palette.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: palette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  void _handleDigit(String digit) {
    _dismissKeyboard();

    setState(() {
      if (_shouldResetDisplay) {
        _displayValue = digit == '.' ? '0.' : digit;
        _shouldResetDisplay = false;
        return;
      }

      if (digit == '.') {
        if (_displayValue.contains('.')) return;
        if (_displayValue.length >= 12) return;
        _displayValue = '$_displayValue.';
        return;
      }

      if (_displayValue == '0') {
        _displayValue = digit;
        return;
      }

      if (_displayValue.length >= 12) return;
      _displayValue = '$_displayValue$digit';
    });
  }

  void _handleOperator(String operator) {
    _dismissKeyboard();

    final currentValue = double.tryParse(_displayValue) ?? 0;
    setState(() {
      if (_pendingOperator == null) {
        _runningTotal = currentValue;
      } else if (!_shouldResetDisplay) {
        _applyPendingOperation(currentValue);
      }

      _pendingOperator = operator;
      _displayValue = _formatDisplayNumber(_runningTotal);
      _shouldResetDisplay = true;
    });
  }

  void _handleEquals() {
    _dismissKeyboard();
    if (_pendingOperator == null) return;

    setState(() {
      final operand = _shouldResetDisplay
          ? _runningTotal
          : double.tryParse(_displayValue) ?? 0;
      _applyPendingOperation(operand);
      _pendingOperator = null;
      _displayValue = _formatDisplayNumber(_runningTotal);
      _shouldResetDisplay = true;
    });
  }

  void _handleBackspace() {
    _dismissKeyboard();

    setState(() {
      if (_shouldResetDisplay) {
        _displayValue = '0';
        _shouldResetDisplay = false;
        return;
      }

      if (_displayValue.length <= 1) {
        _displayValue = '0';
        return;
      }

      _displayValue = _displayValue.substring(0, _displayValue.length - 1);
    });
  }

  void _applyPendingOperation(double operand) {
    switch (_pendingOperator) {
      case '+':
        _runningTotal += operand;
      case '-':
        _runningTotal -= operand;
      case '\u00D7':
        _runningTotal *= operand;
      case '\u00F7':
        if (operand == 0) {
          _showError('Cannot divide by zero');
          return;
        }
        _runningTotal /= operand;
    }

    if (_runningTotal.abs() < 0.0000001) {
      _runningTotal = 0;
    } else {
      _runningTotal = double.parse(_runningTotal.toStringAsFixed(6));
    }
  }

  double _resolveAmountForSubmit() {
    if (_pendingOperator != null) {
      return _runningTotal;
    }
    return double.tryParse(_displayValue) ?? 0;
  }

  String _formatDisplayNumber(double value) {
    if (value.isNaN || value.isInfinite) return '0';

    var formatted = value.toStringAsFixed(6);
    formatted = formatted.replaceFirst(RegExp(r'\.?0+$'), '');
    if (formatted.isEmpty || formatted == '-0') {
      formatted = '0';
    }

    if (formatted.length > 12) {
      formatted = value.toStringAsPrecision(8);
      if (formatted.contains('e') || formatted.contains('E')) {
        formatted = value.toStringAsFixed(2);
      }
      if (formatted.length > 12) {
        formatted = formatted.substring(0, 12);
      }
    }

    return formatted;
  }

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
      setState(() => _selectedAccountId = selectedId);
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
      setState(() {
        _selectedCategoryId = selectedCategoryId;
        _selectedItemId = itemId;
      });
      return;
    }

    final initialItemId =
        previousCategoryId == selectedCategoryId ? _selectedItemId : null;

    setState(() {
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
      setState(() => _selectedItemId = selectedItemId);
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
      setState(() => _selectedIncomeSourceId = selectedId);
    }
  }

  Future<void> _selectDate() async {
    final palette = NeoTheme.of(context);
    final baseTheme = Theme.of(context);
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1, 1, 1);
    final lastDate = DateTime(now.year + 1, 12, 31);

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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
    setState(() {
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
    setState(() {
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

    setState(() {
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

    setState(() {
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

    setState(() => _selectedIncomeSourceId = newSourceId);
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
    if (!mounted) return;

    if (activeAccounts.isEmpty) {
      _showError('Create an account first from Settings > Accounts');
      return;
    }

    final accountId = _selectedAccountId ?? activeAccounts.first.id;
    final amount = _resolveAmountForSubmit();

    if (amount <= 0) {
      _showError('Enter an amount greater than zero');
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
          setState(() => _selectedItemId = expenseItemId);
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

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(transactionNotifierProvider.notifier);
      final note = _noteController.text.trim();

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
    } catch (e) {
      if (!mounted) return;
      _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
