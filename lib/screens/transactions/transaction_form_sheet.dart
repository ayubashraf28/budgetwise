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
import '../../utils/errors/error_mapper.dart';
import '../../widgets/common/calculator_keypad.dart';
import '../../widgets/common/selection_picker_sheet.dart';
import '../expenses/category_form_sheet.dart';
import '../expenses/item_form_sheet.dart';
import '../income/income_form_sheet.dart';

part 'transaction_form_sheet_ui.dart';
part 'transaction_form_sheet_calculator.dart';
part 'transaction_form_sheet_pickers.dart';
part 'transaction_form_sheet_submit.dart';

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

  void _updateState(VoidCallback update) {
    if (!mounted) return;
    setState(update);
  }

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
}
