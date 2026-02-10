import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';

class NeoDropdownFormField<T> extends StatelessWidget {
  final T? value;
  final String hintText;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;
  final double menuMaxHeight;
  final double menuItemHeight;
  final double buttonHeight;

  const NeoDropdownFormField({
    super.key,
    required this.value,
    required this.hintText,
    required this.items,
    required this.onChanged,
    this.validator,
    this.menuMaxHeight = 320,
    this.menuItemHeight = 42,
    this.buttonHeight = 40,
  });

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);

    return DropdownButtonFormField2<T>(
      value: value,
      isExpanded: true,
      isDense: true,
      style: AppTypography.bodyLarge.copyWith(
        color: palette.textPrimary,
      ),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 10,
        ),
      ),
      hint: Text(
        hintText,
        style: AppTypography.bodyMedium.copyWith(
          color: palette.textMuted,
        ),
      ),
      items: items,
      onChanged: onChanged,
      validator: validator,
      buttonStyleData: ButtonStyleData(
        height: buttonHeight,
        padding: EdgeInsets.zero,
      ),
      iconStyleData: IconStyleData(
        icon: Icon(
          LucideIcons.chevronsUpDown,
          size: NeoIconSizes.md,
          color: palette.textSecondary,
        ),
      ),
      menuItemStyleData: MenuItemStyleData(
        height: menuItemHeight,
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 0,
        ),
      ),
      dropdownStyleData: DropdownStyleData(
        maxHeight: menuMaxHeight,
        padding: const EdgeInsets.symmetric(vertical: 2),
        offset: const Offset(0, -2),
        decoration: BoxDecoration(
          color: palette.surface1,
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          border: Border.all(color: palette.stroke),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        scrollbarTheme: ScrollbarThemeData(
          radius: const Radius.circular(AppSizing.radiusFull),
          thumbColor: WidgetStatePropertyAll(
            palette.stroke.withValues(alpha: 0.95),
          ),
          thickness: const WidgetStatePropertyAll(4),
        ),
      ),
    );
  }
}
