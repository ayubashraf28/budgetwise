import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';

class SelectionPickerOption<T> {
  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;

  const SelectionPickerOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
  });
}

class SelectionPickerSheet<T> extends StatelessWidget {
  final String title;
  final List<SelectionPickerOption<T>> options;
  final T? selectedValue;
  final String? addNewLabel;
  final Future<void> Function()? onAddNew;
  final String emptyLabel;

  const SelectionPickerSheet({
    super.key,
    required this.title,
    required this.options,
    this.selectedValue,
    this.addNewLabel,
    this.onAddNew,
    this.emptyLabel = 'No options found',
  }) : assert(
          (addNewLabel == null && onAddNew == null) ||
              (addNewLabel != null && onAddNew != null),
          'addNewLabel and onAddNew must be provided together',
        );

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSizing.radiusXl),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: AdaptiveHeadingText(
                      text: title,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Flexible(
              child: options.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          emptyLabel,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(
                            color: palette.textSecondary,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options[index];
                        final isSelected = option.value == selectedValue;
                        final iconColor = option.iconColor ?? palette.accent;
                        final iconBg = option.iconBackgroundColor ??
                            iconColor.withValues(alpha: 0.16);

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () =>
                                Navigator.of(context).pop(option.value),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm + 2,
                              ),
                              child: Row(
                                children: [
                                  if (option.icon != null)
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: iconBg,
                                        borderRadius: BorderRadius.circular(
                                          AppSizing.radiusSm,
                                        ),
                                      ),
                                      child: Icon(
                                        option.icon,
                                        color: iconColor,
                                        size: AppSizing.iconSm,
                                      ),
                                    ),
                                  if (option.icon != null)
                                    const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          option.label,
                                          style:
                                              AppTypography.bodyLarge.copyWith(
                                            color: palette.textPrimary,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                          ),
                                        ),
                                        if (option.subtitle != null)
                                          Text(
                                            option.subtitle!,
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                              color: palette.textMuted,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      LucideIcons.check,
                                      color: palette.accent,
                                      size: AppSizing.iconMd,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (addNewLabel != null && onAddNew != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: AppSizing.buttonHeightCompact,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await onAddNew!();
                    },
                    icon: const Icon(LucideIcons.plus, size: AppSizing.iconSm),
                    label: Text(addNewLabel!),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
