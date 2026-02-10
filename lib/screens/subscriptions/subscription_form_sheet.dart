import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/account.dart';
import '../../models/subscription.dart';
import '../../providers/providers.dart';
import '../../utils/app_icon_registry.dart';

class SubscriptionFormSheet extends ConsumerStatefulWidget {
  final Subscription? subscription;

  const SubscriptionFormSheet({
    super.key,
    this.subscription,
  });

  @override
  ConsumerState<SubscriptionFormSheet> createState() =>
      _SubscriptionFormSheetState();
}

class _SubscriptionFormSheetState extends ConsumerState<SubscriptionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _categoryNameController;
  late final TextEditingController _notesController;
  late final TextEditingController _customDaysController;
  late final TextEditingController _reminderDaysController;

  late BillingCycle _selectedBillingCycle;
  late DateTime _selectedDueDate;
  late bool _isAutoRenew;
  late String _selectedIcon;
  late String _selectedColor;
  String? _selectedDefaultAccountId;
  bool _isLoading = false;

  bool get isEditing => widget.subscription != null;

  static const List<String> _iconOptions = categoryIcons;

  static const List<String> _colorOptions = [
    '#3B82F6', // Blue
    '#F97316', // Orange
    '#10B981', // Green
    '#6366F1', // Indigo
    '#EF4444', // Red
    '#8B5CF6', // Purple
    '#EC4899', // Pink
    '#14B8A6', // Teal
    '#F59E0B', // Amber
    '#6B7280', // Gray
  ];

  @override
  void initState() {
    super.initState();
    final sub = widget.subscription;
    _nameController = TextEditingController(text: sub?.name ?? '');
    _amountController = TextEditingController(
      text: sub?.amount.toStringAsFixed(2) ?? '',
    );
    _categoryNameController =
        TextEditingController(text: sub?.categoryName ?? '');
    _notesController = TextEditingController(text: sub?.notes ?? '');
    _customDaysController = TextEditingController(
      text: sub?.customCycleDays?.toString() ?? '',
    );
    _reminderDaysController = TextEditingController(
      text: sub?.reminderDaysBefore.toString() ?? '2',
    );

    _selectedBillingCycle = sub?.billingCycle ?? BillingCycle.monthly;
    _selectedDueDate = sub?.nextDueDate ?? DateTime.now();
    _isAutoRenew = sub?.isAutoRenew ?? true;
    _selectedIcon = sub?.icon ?? 'credit-card';
    _selectedColor = sub?.color ?? '#6366f1';
    _selectedDefaultAccountId = sub?.defaultAccountId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _categoryNameController.dispose();
    _notesController.dispose();
    _customDaysController.dispose();
    _reminderDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = ref.watch(currencySymbolProvider);
    final allAccounts = ref.watch(allAccountsProvider).value ?? <Account>[];
    final activeAccounts = allAccounts.where((a) => !a.isArchived).toList();
    final formAccounts = <Account>[...activeAccounts];

    if (_selectedDefaultAccountId != null &&
        !formAccounts.any((a) => a.id == _selectedDefaultAccountId)) {
      final selected = allAccounts
          .where((a) => a.id == _selectedDefaultAccountId)
          .firstOrNull;
      if (selected != null) {
        formAccounts.insert(0, selected);
      }
    }

    final safeDefaultAccountId = (_selectedDefaultAccountId != null &&
            formAccounts.any((a) => a.id == _selectedDefaultAccountId))
        ? _selectedDefaultAccountId
        : null;

    if (safeDefaultAccountId != _selectedDefaultAccountId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _selectedDefaultAccountId = safeDefaultAccountId);
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
                        isEditing ? 'Edit Subscription' : 'Add Subscription',
                        style: AppTypography.h3,
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(LucideIcons.x),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Name Field
                  _buildLabel('Name'),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'e.g., Netflix, Spotify, Gym',
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
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

                  // Billing Cycle
                  _buildLabel('Billing Cycle'),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<BillingCycle>(
                    value: _selectedBillingCycle,
                    decoration: const InputDecoration(
                      hintText: 'Select billing cycle',
                    ),
                    dropdownColor: AppColors.surface,
                    items: BillingCycle.values.map((cycle) {
                      String label;
                      switch (cycle) {
                        case BillingCycle.weekly:
                          label = 'Weekly';
                        case BillingCycle.monthly:
                          label = 'Monthly';
                        case BillingCycle.quarterly:
                          label = 'Quarterly';
                        case BillingCycle.yearly:
                          label = 'Yearly';
                        case BillingCycle.custom:
                          label = 'Custom';
                      }
                      return DropdownMenuItem(
                        value: cycle,
                        child: Text(label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedBillingCycle = value);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Custom Cycle Days (only when custom selected)
                  if (_selectedBillingCycle == BillingCycle.custom) ...[
                    _buildLabel('Days per cycle'),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _customDaysController,
                      decoration: const InputDecoration(
                        hintText: 'e.g., 45',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (_selectedBillingCycle == BillingCycle.custom) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter days per cycle';
                          }
                          final days = int.tryParse(value);
                          if (days == null || days <= 0) {
                            return 'Please enter a valid number';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Next Due Date
                  _buildLabel('Next Due Date'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildDatePicker(context),
                  const SizedBox(height: AppSpacing.lg),

                  // Auto-Renew Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(LucideIcons.repeat,
                                size: 20, color: AppColors.textSecondary),
                            SizedBox(width: AppSpacing.sm),
                            Text('Auto-renew', style: AppTypography.bodyLarge),
                          ],
                        ),
                        Switch(
                          value: _isAutoRenew,
                          onChanged: (value) =>
                              setState(() => _isAutoRenew = value),
                          activeTrackColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Category Name (optional)
                  _buildLabel('Category Label (optional)'),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _categoryNameController,
                    decoration: const InputDecoration(
                      hintText: 'e.g., Entertainment, Utilities',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Default Account (optional)
                  _buildLabel('Default Payment Account (optional)'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildDefaultAccountDropdown(
                      formAccounts, safeDefaultAccountId),
                  const SizedBox(height: AppSpacing.lg),

                  // Icon Selector
                  _buildLabel('Icon'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildIconSelector(),
                  const SizedBox(height: AppSpacing.lg),

                  // Color Selector
                  _buildLabel('Color'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildColorSelector(),
                  const SizedBox(height: AppSpacing.lg),

                  // Reminder Days
                  _buildLabel('Reminder Days Before'),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _reminderDaysController,
                    decoration: const InputDecoration(
                      hintText: '2',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter reminder days';
                      }
                      final days = int.tryParse(value);
                      if (days == null || days < 0) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Notes Field
                  _buildLabel('Notes (optional)'),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      hintText: 'Add any notes...',
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
                              isEditing ? 'Save Changes' : 'Add Subscription'),
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
    return Text(text, style: AppTypography.labelMedium);
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
              DateFormat('d MMMM yyyy').format(_selectedDueDate),
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

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1, 1, 1);
    final lastDate = DateTime(now.year + 1, 12, 31);

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
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

    if (picked != null && picked != _selectedDueDate) {
      setState(() => _selectedDueDate = picked);
    }
  }

  Widget _buildIconSelector() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: _iconOptions.map((icon) {
          final isSelected = icon == _selectedIcon;
          return GestureDetector(
            onTap: () => setState(() => _selectedIcon = icon),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? _parseColor(_selectedColor)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSizing.radiusSm),
                border: isSelected ? null : Border.all(color: AppColors.border),
              ),
              child: Icon(
                _getIconData(icon),
                color: isSelected ? Colors.white : AppColors.textSecondary,
                size: 22,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildColorSelector() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: _colorOptions.map((color) {
          final isSelected = color == _selectedColor;
          return GestureDetector(
            onTap: () => setState(() => _selectedColor = color),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _parseColor(color),
                borderRadius: BorderRadius.circular(AppSizing.radiusSm),
                border: isSelected
                    ? Border.all(color: Colors.white, width: 3)
                    : Border.all(color: AppColors.border),
              ),
              child: isSelected
                  ? const Icon(LucideIcons.check, color: Colors.white, size: 20)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDefaultAccountDropdown(
    List<Account> accounts,
    String? safeValue,
  ) {
    return DropdownButtonFormField<String?>(
      value: safeValue,
      decoration: const InputDecoration(
        hintText: 'Choose default account',
      ),
      dropdownColor: AppColors.surface,
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('No default account'),
        ),
        ...accounts.map((account) {
          final isArchived = account.isArchived;
          return DropdownMenuItem<String?>(
            value: account.id,
            child: Row(
              children: [
                Icon(
                  _accountTypeIcon(account.type),
                  size: 16,
                  color: isArchived ? AppColors.textMuted : AppColors.savings,
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
        }),
      ],
      onChanged: (value) {
        setState(() => _selectedDefaultAccountId = value);
      },
    );
  }

  Color _parseColor(String hex) {
    try {
      final hexCode = hex.replaceFirst('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (e) {
      return const Color(0xFF6366F1);
    }
  }

  IconData _getIconData(String iconName) {
    return resolveAppIcon(iconName, fallback: LucideIcons.creditCard);
  }

  IconData _accountTypeIcon(AccountType type) {
    switch (type) {
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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(subscriptionNotifierProvider.notifier);
      final name = _nameController.text.trim();
      final amount = double.tryParse(_amountController.text) ?? 0;
      final categoryName = _categoryNameController.text.trim();
      final notes = _notesController.text.trim();
      final reminderDays = int.tryParse(_reminderDaysController.text) ?? 2;
      final customDays = _selectedBillingCycle == BillingCycle.custom
          ? int.tryParse(_customDaysController.text)
          : null;

      if (isEditing) {
        await notifier.updateSubscription(
          subscriptionId: widget.subscription!.id,
          name: name,
          amount: amount,
          nextDueDate: _selectedDueDate,
          billingCycle: _selectedBillingCycle.name,
          isAutoRenew: _isAutoRenew,
          customCycleDays: customDays,
          icon: _selectedIcon,
          color: _selectedColor,
          categoryName: categoryName.isEmpty ? null : categoryName,
          notes: notes.isEmpty ? null : notes,
          defaultAccountId: _selectedDefaultAccountId,
          clearDefaultAccountId:
              widget.subscription!.defaultAccountId != null &&
                  _selectedDefaultAccountId == null,
          reminderDaysBefore: reminderDays,
        );
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subscription updated')),
          );
        }
      } else {
        await notifier.addSubscription(
          name: name,
          amount: amount,
          nextDueDate: _selectedDueDate,
          billingCycle: _selectedBillingCycle.name,
          isAutoRenew: _isAutoRenew,
          customCycleDays: customDays,
          icon: _selectedIcon,
          color: _selectedColor,
          categoryName: categoryName.isEmpty ? null : categoryName,
          notes: notes.isEmpty ? null : notes,
          defaultAccountId: _selectedDefaultAccountId,
          reminderDaysBefore: reminderDays,
        );
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subscription added')),
          );
        }
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
