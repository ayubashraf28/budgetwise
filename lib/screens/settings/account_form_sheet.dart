import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../models/account.dart';
import '../../providers/providers.dart';
import '../../widgets/common/neo_dropdown_form_field.dart';

class AccountFormSheet extends ConsumerStatefulWidget {
  final Account? account;

  const AccountFormSheet({
    super.key,
    this.account,
  });

  @override
  ConsumerState<AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends ConsumerState<AccountFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _openingBalanceController;
  late final TextEditingController _creditLimitController;

  late AccountType _type;
  late bool _includeInNetWorth;
  bool _isSubmitting = false;

  bool get isEditing => widget.account != null;

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    _nameController = TextEditingController(text: account?.name ?? '');
    _openingBalanceController = TextEditingController(
      text:
          account != null ? account.openingBalance.toStringAsFixed(2) : '0.00',
    );
    _creditLimitController = TextEditingController(
      text: account?.creditLimit?.toStringAsFixed(2) ?? '',
    );
    _type = account?.type ?? AccountType.cash;
    _includeInNetWorth = account?.includeInNetWorth ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _openingBalanceController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final currencyCode = ref.watch(currencyProvider);

    return Container(
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSizing.radiusXl)),
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
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: palette.stroke,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: AdaptiveHeadingText(
                          text: isEditing ? 'Edit Account' : 'Add Account',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(LucideIcons.x),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildLabel('Account Name'),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Cash, Monzo Debit, Amex',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an account name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildLabel('Account Type'),
                  const SizedBox(height: AppSpacing.sm),
                  NeoDropdownFormField<AccountType>(
                    value: _type,
                    hintText: 'Select account type',
                    items: AccountType.values
                        .map(
                          (type) => DropdownMenuItem<AccountType>(
                            value: type,
                            child: Text(_accountTypeLabel(type)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _type = value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildLabel('Opening Balance'),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _openingBalanceController,
                    decoration: InputDecoration(
                      hintText: '0.00',
                      prefixText: '$currencySymbol ',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^-?\d*\.?\d{0,2}')),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter opening balance';
                      }
                      if (double.tryParse(value.trim()) == null) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (_type == AccountType.credit) ...[
                    _buildLabel('Credit Limit (optional)'),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _creditLimitController,
                      decoration: InputDecoration(
                        hintText: '0.00',
                        prefixText: '$currencySymbol ',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        final parsed = double.tryParse(value.trim());
                        if (parsed == null || parsed < 0) {
                          return 'Please enter a valid non-negative amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: palette.surface2,
                      borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                      border: Border.all(color: palette.stroke),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.pieChart,
                          size: 18,
                          color: NeoTheme.positiveValue(context),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Include in net worth',
                                style: AppTypography.labelLarge.copyWith(
                                  color: palette.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Toggle whether this account affects home net worth',
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _includeInNetWorth,
                          onChanged: (value) {
                            setState(() => _includeInNetWorth = value);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Currency: $currencyCode (locked to profile in V1)',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    height: AppSizing.buttonHeight,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(isEditing ? 'Save Changes' : 'Create Account'),
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

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: AppTypography.labelMedium.copyWith(
        color: NeoTheme.of(context).textSecondary,
      ),
    );
  }

  String _accountTypeLabel(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return 'Cash';
      case AccountType.debit:
        return 'Debit Card';
      case AccountType.credit:
        return 'Credit Card';
      case AccountType.savings:
        return 'Savings';
      case AccountType.other:
        return 'Other';
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final notifier = ref.read(accountNotifierProvider.notifier);
    final name = _nameController.text.trim();
    final openingBalance = double.parse(_openingBalanceController.text.trim());
    final creditLimitText = _creditLimitController.text.trim();
    final creditLimit =
        creditLimitText.isEmpty ? null : double.parse(creditLimitText);

    try {
      if (isEditing) {
        final previousType = widget.account!.type;
        await notifier.updateAccount(
          accountId: widget.account!.id,
          name: name,
          type: _type,
          openingBalance: openingBalance,
          creditLimit: _type == AccountType.credit ? creditLimit : null,
          clearCreditLimit:
              previousType == AccountType.credit && _type != AccountType.credit,
          includeInNetWorth: _includeInNetWorth,
        );
      } else {
        await notifier.createAccount(
          name: name,
          type: _type,
          openingBalance: openingBalance,
          creditLimit: _type == AccountType.credit ? creditLimit : null,
          includeInNetWorth: _includeInNetWorth,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Account updated' : 'Account created'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: NeoTheme.negativeValue(context),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
