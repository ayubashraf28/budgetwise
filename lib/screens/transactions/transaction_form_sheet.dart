import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../models/item.dart';
import '../../models/income_source.dart';
import '../../models/account.dart';
import '../../providers/providers.dart';
import '../../utils/app_icon_registry.dart';
import '../expenses/category_form_sheet.dart';
import '../expenses/item_form_sheet.dart';
import '../income/income_form_sheet.dart';

class TransactionFormSheet extends ConsumerStatefulWidget {
  final Transaction? transaction;

  const TransactionFormSheet({
    super.key,
    this.transaction,
  });

  @override
  ConsumerState<TransactionFormSheet> createState() =>
      _TransactionFormSheetState();
}

class _TransactionFormSheetState extends ConsumerState<TransactionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  late TransactionType _transactionType;
  String? _selectedCategoryId;
  String? _selectedItemId;
  String? _selectedIncomeSourceId;
  String? _selectedAccountId;
  late DateTime _selectedDate;
  bool _isLoading = false;
  int _dropdownResetCounter = 0;

  static const _addNewCategoryValue = '__add_new_category__';
  static const _addNewItemValue = '__add_new_item__';
  static const _addNewIncomeValue = '__add_new_income_source__';

  bool get isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;

    _amountController = TextEditingController(
      text: tx?.amount.toStringAsFixed(2) ?? '',
    );
    _noteController = TextEditingController(text: tx?.note ?? '');

    _transactionType = tx?.type ?? TransactionType.expense;
    _selectedCategoryId = tx?.categoryId;
    _selectedItemId = tx?.itemId;
    _selectedIncomeSourceId = tx?.incomeSourceId;
    _selectedAccountId = tx?.accountId;
    _selectedDate = tx?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).value ?? [];
    final incomeSources = ref.watch(incomeSourcesProvider).value ?? [];
    final allAccounts = ref.watch(allAccountsProvider).value ?? [];
    final currencySymbol = ref.watch(currencySymbolProvider);

    final activeAccounts = allAccounts.where((a) => !a.isArchived).toList();
    final formAccounts = <Account>[...activeAccounts];

    // Allow editing a transaction that references an archived account.
    if (_selectedAccountId != null &&
        !formAccounts.any((a) => a.id == _selectedAccountId)) {
      final selectedAccount =
          allAccounts.where((a) => a.id == _selectedAccountId).firstOrNull;
      if (selectedAccount != null) {
        formAccounts.insert(0, selectedAccount);
      }
    }

    // Defensive: if selected IDs don't exist in the loaded lists (e.g., the
    // transaction references entities from a different month), compute safe
    // values for this frame and schedule a state reset for the next frame.
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

    // Get items for the safe category
    List<Item> items = [];
    if (safeCategoryId != null) {
      final matchedCategory =
          categories.where((c) => c.id == safeCategoryId).firstOrNull;
      if (matchedCategory != null) {
        items = matchedCategory.items ?? [];
      }
    }

    final safeItemId =
        (_selectedItemId != null && items.any((i) => i.id == _selectedItemId))
            ? _selectedItemId
            : null;

    // Schedule state reset so subsequent builds use corrected values
    if (safeCategoryId != _selectedCategoryId ||
        safeItemId != _selectedItemId ||
        safeIncomeSourceId != _selectedIncomeSourceId ||
        safeAccountId != _selectedAccountId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedCategoryId = safeCategoryId;
            _selectedItemId = safeItemId;
            _selectedIncomeSourceId = safeIncomeSourceId;
            _selectedAccountId = safeAccountId;
          });
        }
      });
    }

    // For new transactions, preselect first active account for smoother UX.
    if (!isEditing && _selectedAccountId == null && activeAccounts.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedAccountId == null) {
          setState(() {
            _selectedAccountId = activeAccounts.first.id;
          });
        }
      });
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizing.radiusXl)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Edit Transaction' : 'Add Transaction',
                        style: AppTypography.h3,
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(LucideIcons.x),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Type Toggle
                  _buildTypeToggle(),
                  const SizedBox(height: AppSpacing.lg),

                  // Amount Field
                  _buildLabel('Amount'),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      hintText: '0.00',
                      prefixText: '$currencySymbol ',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an amount';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Account Dropdown
                  _buildLabel('Account'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildAccountDropdown(formAccounts, safeAccountId),
                  if (activeAccounts.isEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'No active accounts found. Add one in Settings > Accounts.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),

                  // Show Category/Item for expenses, Income Source for income
                  if (_transactionType == TransactionType.expense) ...[
                    // Category Dropdown
                    _buildLabel('Category'),
                    const SizedBox(height: AppSpacing.sm),
                    _buildCategoryDropdown(categories, safeCategoryId),
                    const SizedBox(height: AppSpacing.lg),

                    // Item Dropdown
                    _buildLabel('Item'),
                    const SizedBox(height: AppSpacing.sm),
                    _buildItemDropdown(items, safeItemId),
                    const SizedBox(height: AppSpacing.lg),
                  ] else ...[
                    // Income Source Dropdown
                    _buildLabel('Income Source'),
                    const SizedBox(height: AppSpacing.sm),
                    _buildIncomeSourceDropdown(
                        incomeSources, safeIncomeSourceId),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Date Picker
                  _buildLabel('Date'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildDatePicker(context),
                  const SizedBox(height: AppSpacing.lg),

                  // Note Field
                  _buildLabel('Note (optional)'),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      hintText: 'Add a note...',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: AppSizing.buttonHeight,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isEditing ? 'Save Changes' : 'Add Transaction'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTypography.labelMedium,
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeButton(
              label: 'Expense',
              icon: LucideIcons.trendingDown,
              isSelected: _transactionType == TransactionType.expense,
              color: AppColors.error,
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
            child: _buildTypeButton(
              label: 'Income',
              icon: LucideIcons.trendingUp,
              isSelected: _transactionType == TransactionType.income,
              color: AppColors.success,
              onTap: () {
                setState(() {
                  _transactionType = TransactionType.income;
                  _selectedCategoryId = null;
                  _selectedItemId = null;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color:
              isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizing.radiusSm),
          border: isSelected
              ? Border.all(color: color.withValues(alpha: 0.5))
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? color : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(List<Category> categories, String? safeValue) {
    return DropdownButtonFormField<String>(
      key: ValueKey('category_dropdown_$_dropdownResetCounter'),
      value: safeValue,
      decoration: const InputDecoration(
        hintText: 'Select category',
      ),
      dropdownColor: AppColors.surface,
      items: [
        ...categories.map((category) {
          return DropdownMenuItem<String>(
            value: category.id,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: category.colorValue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _getCategoryIcon(category.icon),
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(category.name),
              ],
            ),
          );
        }),
        DropdownMenuItem<String>(
          value: _addNewCategoryValue,
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  LucideIcons.plus,
                  color: AppColors.primary,
                  size: 14,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Add New Category',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
      onChanged: (value) {
        if (value == _addNewCategoryValue) {
          _handleAddCategory(context);
          return;
        }
        setState(() {
          _selectedCategoryId = value;
          _selectedItemId = null;
        });
      },
      validator: (value) {
        if (_transactionType == TransactionType.expense &&
            (value == null || value == _addNewCategoryValue)) {
          return 'Please select a category';
        }
        return null;
      },
    );
  }

  Widget _buildItemDropdown(List<Item> items, String? safeValue) {
    return DropdownButtonFormField<String>(
      key: ValueKey('item_dropdown_$_dropdownResetCounter'),
      value: safeValue,
      decoration: const InputDecoration(
        hintText: 'Select item',
      ),
      dropdownColor: AppColors.surface,
      items: [
        ...items.map((item) {
          return DropdownMenuItem<String>(
            value: item.id,
            child: Text(item.name),
          );
        }),
        if (_selectedCategoryId != null)
          DropdownMenuItem<String>(
            value: _addNewItemValue,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    LucideIcons.plus,
                    color: AppColors.primary,
                    size: 14,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Add New Item',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
      onChanged: (value) {
        if (value == _addNewItemValue) {
          _handleAddItem(context);
          return;
        }
        setState(() {
          _selectedItemId = value;
        });
      },
      validator: (value) {
        if (_transactionType == TransactionType.expense &&
            (value == null || value == _addNewItemValue)) {
          return 'Please select an item';
        }
        return null;
      },
    );
  }

  Widget _buildIncomeSourceDropdown(
      List<IncomeSource> incomeSources, String? safeValue) {
    return DropdownButtonFormField<String>(
      key: ValueKey('income_dropdown_$_dropdownResetCounter'),
      value: safeValue,
      decoration: const InputDecoration(
        hintText: 'Select income source',
      ),
      dropdownColor: AppColors.surface,
      items: [
        ...incomeSources.map((source) {
          return DropdownMenuItem<String>(
            value: source.id,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    LucideIcons.wallet,
                    color: AppColors.success,
                    size: 14,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(source.name),
              ],
            ),
          );
        }),
        DropdownMenuItem<String>(
          value: _addNewIncomeValue,
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  LucideIcons.plus,
                  color: AppColors.primary,
                  size: 14,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Add New Source',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
      onChanged: (value) {
        if (value == _addNewIncomeValue) {
          _handleAddIncomeSource(context);
          return;
        }
        setState(() {
          _selectedIncomeSourceId = value;
        });
      },
      validator: (value) {
        if (_transactionType == TransactionType.income &&
            (value == null || value == _addNewIncomeValue)) {
          return 'Please select an income source';
        }
        return null;
      },
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              LucideIcons.calendar,
              size: 20,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              DateFormat('d MMMM yyyy').format(_selectedDate),
              style: AppTypography.bodyLarge,
            ),
            const Spacer(),
            const Icon(
              LucideIcons.chevronDown,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountDropdown(List<Account> accounts, String? safeValue) {
    return DropdownButtonFormField<String>(
      key: ValueKey('account_dropdown_$_dropdownResetCounter'),
      value: safeValue,
      decoration: const InputDecoration(
        hintText: 'Select account',
      ),
      dropdownColor: AppColors.surface,
      items: accounts.map((account) {
        final isArchived = account.isArchived;
        return DropdownMenuItem<String>(
          value: account.id,
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: (isArchived ? AppColors.textMuted : AppColors.savings)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _getAccountTypeIcon(account.type),
                  color: isArchived ? AppColors.textMuted : AppColors.savings,
                  size: 14,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  isArchived ? '${account.name} (Archived)' : account.name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: accounts.isEmpty
          ? null
          : (value) {
              setState(() {
                _selectedAccountId = value;
              });
            },
      validator: (value) {
        if (accounts.isNotEmpty && value == null) {
          return 'Please select an account';
        }
        return null;
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
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
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
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

  Future<void> _handleAddCategory(BuildContext context) async {
    final newCategoryId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CategoryFormSheet(),
    );
    if (newCategoryId != null && mounted) {
      // Wait for new categories to load BEFORE setting the selected ID
      ref.invalidate(categoriesProvider);
      await ref.read(categoriesProvider.future);
      if (mounted) {
        setState(() {
          _selectedCategoryId = newCategoryId;
          _selectedItemId = null;
          _dropdownResetCounter++;
        });
      }
    } else if (mounted) {
      // Cancelled — reset dropdown to previous value
      setState(() => _dropdownResetCounter++);
    }
  }

  Future<void> _handleAddItem(BuildContext context) async {
    if (_selectedCategoryId == null) return;
    // Pass the parent category's isBudgeted flag
    final categories = ref.read(categoriesProvider).value ?? [];
    final parentCat =
        categories.where((c) => c.id == _selectedCategoryId).firstOrNull;
    final newItemId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ItemFormSheet(
        categoryId: _selectedCategoryId!,
        categoryIsBudgeted: parentCat?.isBudgeted ?? true,
      ),
    );
    if (newItemId != null && mounted) {
      // Wait for categories (with items) to load BEFORE setting the selected ID
      ref.invalidate(categoriesProvider);
      await ref.read(categoriesProvider.future);
      if (mounted) {
        setState(() {
          _selectedItemId = newItemId;
          _dropdownResetCounter++;
        });
      }
    } else if (mounted) {
      // Cancelled — reset dropdown to previous value
      setState(() => _dropdownResetCounter++);
    }
  }

  Future<void> _handleAddIncomeSource(BuildContext context) async {
    final newSourceId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const IncomeFormSheet(),
    );
    if (newSourceId != null && mounted) {
      // Wait for income sources to load BEFORE setting the selected ID
      ref.invalidate(incomeSourcesProvider);
      await ref.read(incomeSourcesProvider.future);
      if (mounted) {
        setState(() {
          _selectedIncomeSourceId = newSourceId;
          _dropdownResetCounter++;
        });
      }
    } else if (mounted) {
      // Cancelled — reset dropdown to previous value
      setState(() => _dropdownResetCounter++);
    }
  }

  Future<void> _handleSubmit() async {
    final activeAccounts = await ref.read(accountsProvider.future);
    if (!mounted) return;
    if (activeAccounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Create an account first from Settings > Accounts',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final accountId = _selectedAccountId ?? activeAccounts.first.id;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(transactionNotifierProvider.notifier);
      final amount = double.tryParse(_amountController.text) ?? 0;
      final note = _noteController.text.trim();

      if (isEditing) {
        // Update existing transaction
        if (_transactionType == TransactionType.expense) {
          await notifier.updateTransaction(
            transactionId: widget.transaction!.id,
            categoryId: _selectedCategoryId,
            itemId: _selectedItemId,
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
        // Create new transaction
        if (_transactionType == TransactionType.expense) {
          await notifier.addExpense(
            categoryId: _selectedCategoryId!,
            itemId: _selectedItemId!,
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

      if (mounted) {
        // Refresh category and income data to update actual amounts
        // Use refresh().future to WAIT for data to load before closing
        ref.invalidate(categoriesProvider);
        await ref.read(categoriesProvider.future);
        ref.invalidate(incomeSourcesProvider);
        await ref.read(incomeSourcesProvider.future);

        // Also refresh specific category to update item-level amounts
        if (_selectedCategoryId != null) {
          ref.invalidate(categoryByIdProvider(_selectedCategoryId!));
          await ref.read(categoryByIdProvider(_selectedCategoryId!).future);
        }

        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Transaction updated' : 'Transaction added',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
