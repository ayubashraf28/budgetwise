import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../models/item.dart';
import '../../providers/providers.dart';

class ItemFormSheet extends ConsumerStatefulWidget {
  final String categoryId;
  final Item? item;
  final bool isBudgeted;

  const ItemFormSheet({
    super.key,
    required this.categoryId,
    this.item,
    this.isBudgeted = true,
  });

  @override
  ConsumerState<ItemFormSheet> createState() => _ItemFormSheetState();
}

class _ItemFormSheetState extends ConsumerState<ItemFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _projectedController;
  late final TextEditingController _notesController;
  late bool _isRecurring;
  bool _isLoading = false;

  bool get isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _projectedController = TextEditingController(
      text: widget.item?.projected.toStringAsFixed(2) ?? '',
    );
    _notesController = TextEditingController(text: widget.item?.notes ?? '');
    _isRecurring = widget.item?.isRecurring ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _projectedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = ref.watch(currencySymbolProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizing.radiusXl)),
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
                        isEditing ? 'Edit Item' : 'Add Item',
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
                      hintText: 'e.g., Rent, Groceries, Netflix',
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

                  // Budget Amount Field
                  _buildLabel('Budget Amount'),
                  const SizedBox(height: AppSpacing.sm),
                  Opacity(
                    opacity: widget.isBudgeted ? 1.0 : 0.4,
                    child: TextFormField(
                      controller: _projectedController,
                      enabled: widget.isBudgeted,
                      decoration: InputDecoration(
                        hintText: '0.00',
                        prefixText: '$currencySymbol ',
                        helperText: !widget.isBudgeted
                            ? 'Budgeting is disabled for this category'
                            : null,
                        helperStyle: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      validator: widget.isBudgeted
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

                  // Recurring Toggle
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
                            Icon(LucideIcons.repeat, size: 20, color: AppColors.textSecondary),
                            SizedBox(width: AppSpacing.sm),
                            Text('Recurring expense', style: AppTypography.bodyLarge),
                          ],
                        ),
                        Switch(
                          value: _isRecurring,
                          onChanged: (value) => setState(() => _isRecurring = value),
                          activeTrackColor: AppColors.primary,
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
                          : Text(isEditing ? 'Save Changes' : 'Add Item'),
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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(itemNotifierProvider(widget.categoryId).notifier);
      final name = _nameController.text.trim();
      final projected = widget.isBudgeted ? (double.tryParse(_projectedController.text) ?? 0) : 0.0;
      final notes = _notesController.text.trim();

      if (isEditing) {
        await notifier.updateItem(
          itemId: widget.item!.id,
          name: name,
          projected: projected,
          isRecurring: _isRecurring,
          notes: notes.isEmpty ? null : notes,
        );
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item updated')),
          );
        }
      } else {
        final newItem = await notifier.addItem(
          name: name,
          projected: projected,
          isRecurring: _isRecurring,
          notes: notes.isEmpty ? null : notes,
        );
        if (mounted) {
          Navigator.of(context).pop(newItem.id); // Return ID for transaction form
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item added')),
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
