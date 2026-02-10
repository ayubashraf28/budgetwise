import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../models/income_source.dart';
import '../../providers/providers.dart';

class IncomeFormSheet extends ConsumerStatefulWidget {
  final IncomeSource? incomeSource;

  const IncomeFormSheet({
    super.key,
    this.incomeSource,
  });

  @override
  ConsumerState<IncomeFormSheet> createState() => _IncomeFormSheetState();
}

class _IncomeFormSheetState extends ConsumerState<IncomeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _projectedController;
  late final TextEditingController _actualController;
  late final TextEditingController _notesController;
  late bool _isRecurring;
  bool _isLoading = false;

  bool get isEditing => widget.incomeSource != null;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.incomeSource?.name ?? '');
    _projectedController = TextEditingController(
      text: widget.incomeSource?.projected.toStringAsFixed(2) ?? '',
    );
    _actualController = TextEditingController(
      text: widget.incomeSource?.actual.toStringAsFixed(2) ?? '',
    );
    _notesController =
        TextEditingController(text: widget.incomeSource?.notes ?? '');
    _isRecurring = widget.incomeSource?.isRecurring ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _projectedController.dispose();
    _actualController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);
    final currencySymbol = ref.watch(currencySymbolProvider);

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
                  // Handle
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

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Edit Income Source' : 'Add Income Source',
                        style: NeoTypography.sectionTitle(context),
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
                      hintText: 'e.g., Salary, Freelance, Bonus',
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

                  // Projected Amount Field
                  _buildLabel('Projected Amount'),
                  const SizedBox(height: AppSpacing.sm),
                  Opacity(
                    opacity: _isRecurring ? 1.0 : 0.4,
                    child: TextFormField(
                      controller: _projectedController,
                      enabled: _isRecurring,
                      decoration: InputDecoration(
                        hintText: '0.00',
                        prefixText: '$currencySymbol ',
                        helperText: !_isRecurring
                            ? 'Not required for non-recurring income'
                            : null,
                        helperStyle: TextStyle(
                          color: palette.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      validator: _isRecurring
                          ? (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter an amount';
                              }
                              final amount = double.tryParse(value);
                              if (amount == null || amount < 0) {
                                return 'Please enter a valid amount';
                              }
                              return null;
                            }
                          : null,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Actual Amount Field (only for editing)
                  if (isEditing) ...[
                    _buildLabel('Actual Amount Received'),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _actualController,
                      decoration: const InputDecoration(
                        hintText: '0.00',
                        prefixText: '\u00A3 ',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Recurring Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surface2,
                      borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(LucideIcons.repeat,
                                size: 20, color: palette.textSecondary),
                            SizedBox(width: AppSpacing.sm),
                            Text(
                              'Recurring income',
                              style: AppTypography.bodyLarge.copyWith(
                                color: palette.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _isRecurring,
                          onChanged: (value) => setState(() {
                            _isRecurring = value;
                            if (!value) {
                              _projectedController.text = '0.00';
                            }
                          }),
                          activeTrackColor: palette.accent,
                        ),
                      ],
                    ),
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
                              isEditing ? 'Save Changes' : 'Add Income Source'),
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
      style: AppTypography.labelMedium.copyWith(
        color: NeoTheme.of(context).textSecondary,
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(incomeNotifierProvider.notifier);
      final name = _nameController.text.trim();
      final projected = _isRecurring
          ? (double.tryParse(_projectedController.text) ?? 0)
          : 0.0;
      final actual = double.tryParse(_actualController.text) ?? 0;
      final notes = _notesController.text.trim();

      if (isEditing) {
        await notifier.updateIncomeSource(
          incomeSourceId: widget.incomeSource!.id,
          name: name,
          projected: projected,
          actual: actual,
          isRecurring: _isRecurring,
          notes: notes.isEmpty ? null : notes,
        );
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Income source updated')),
          );
        }
      } else {
        final newSource = await notifier.addIncomeSource(
          name: name,
          projected: projected,
          isRecurring: _isRecurring,
          notes: notes.isEmpty ? null : notes,
        );
        if (mounted) {
          Navigator.of(context)
              .pop(newSource.id); // Return ID for transaction form
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Income source added')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: NeoTheme.negativeValue(context),
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
