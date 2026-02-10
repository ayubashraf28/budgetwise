import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/category.dart';
import '../../providers/providers.dart';
import '../../utils/app_icon_registry.dart';
import '../../utils/category_name_utils.dart';

class CategoryFormSheet extends ConsumerStatefulWidget {
  final Category? category;

  const CategoryFormSheet({
    super.key,
    this.category,
  });

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _selectedIcon;
  late String _selectedColor;
  late bool _isBudgeted;
  bool _isLoading = false;

  bool get isEditing => widget.category != null;

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
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedIcon = widget.category?.icon ?? 'wallet';
    _selectedColor = widget.category?.color ?? '#6366F1';
    _isBudgeted = widget.category?.isBudgeted ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);
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
                        isEditing ? 'Edit Category' : 'Add Category',
                        style: NeoTypography.sectionTitle(context),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(LucideIcons.x),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Preview
                  _buildPreview(),
                  const SizedBox(height: AppSpacing.lg),

                  // Name Field
                  _buildLabel('Name'),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'e.g., Housing, Food, Transport',
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a name';
                      }
                      final rawName = value.trim();
                      final isCurrentReserved = isEditing &&
                          isReservedCategoryName(widget.category!.name);
                      final isTargetReserved = isReservedCategoryName(rawName);

                      if (!isCurrentReserved && isTargetReserved) {
                        return '"$systemSubscriptionsCategoryName" is reserved for the subscriptions feature';
                      }

                      if (isCurrentReserved && !isTargetReserved) {
                        return 'This system category cannot be renamed';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Budget Toggle
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
                            Icon(LucideIcons.target,
                                size: 20, color: palette.textSecondary),
                            SizedBox(width: AppSpacing.sm),
                            Text(
                              'Enable budgeting',
                              style: AppTypography.bodyLarge.copyWith(
                                color: palette.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _isBudgeted,
                          onChanged: (value) =>
                              setState(() => _isBudgeted = value),
                          activeTrackColor: palette.accent,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: Text(
                      _isBudgeted
                          ? 'Track spending against a budget for each item'
                          : 'Track spending only — no budget targets',
                      style: TextStyle(
                        color: palette.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
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
                          : Text(isEditing ? 'Save Changes' : 'Add Category'),
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

  Widget _buildPreview() {
    final palette = NeoTheme.of(context);
    final color = _parseColor(_selectedColor);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.surface2,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppSizing.radiusMd),
            ),
            child: Icon(
              _getIconData(_selectedIcon),
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              _nameController.text.isEmpty
                  ? 'Category Name'
                  : _nameController.text,
              style: AppTypography.labelLarge.copyWith(
                color: palette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconSelector() {
    final palette = NeoTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: palette.surface2,
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
                border: isSelected ? null : Border.all(color: palette.stroke),
              ),
              child: Icon(
                _getIconData(icon),
                color: isSelected ? Colors.white : palette.textSecondary,
                size: 22,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildColorSelector() {
    final palette = NeoTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: palette.surface2,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: _colorOptions.map((colorHex) {
          final color = _parseColor(colorHex);
          final isSelected = colorHex == _selectedColor;
          return GestureDetector(
            onTap: () => setState(() => _selectedColor = colorHex),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppSizing.radiusSm),
                border: isSelected
                    ? Border.all(color: Colors.white, width: 3)
                    : null,
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

  Color _parseColor(String hex) {
    try {
      final hexCode = hex.replaceFirst('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (e) {
      return NeoTheme.dark.accent;
    }
  }

  IconData _getIconData(String iconName) {
    return resolveAppIcon(iconName, fallback: LucideIcons.wallet);
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(categoryNotifierProvider.notifier);
      final name = _nameController.text.trim();

      if (isEditing) {
        await notifier.updateCategory(
          categoryId: widget.category!.id,
          name: name,
          icon: _selectedIcon,
          color: _selectedColor,
          isBudgeted: _isBudgeted,
        );
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Category updated')),
          );
        }
      } else {
        final newCategory = await notifier.addCategory(
          name: name,
          icon: _selectedIcon,
          color: _selectedColor,
          isBudgeted: _isBudgeted,
        );
        if (mounted) {
          Navigator.of(context)
              .pop(newCategory.id); // Return ID for transaction form
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Category added')),
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
