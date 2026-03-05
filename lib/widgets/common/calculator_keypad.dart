import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';

class CalculatorKeypad extends StatelessWidget {
  final String displayValue;
  final String? activeOperator;
  final String currencySymbol;
  final ValueChanged<String> onDigit;
  final ValueChanged<String> onOperator;
  final VoidCallback onEquals;
  final VoidCallback onBackspace;

  const CalculatorKeypad({
    super.key,
    required this.displayValue,
    required this.activeOperator,
    required this.currencySymbol,
    required this.onDigit,
    required this.onOperator,
    required this.onEquals,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);
    const keys = <_CalculatorKey>[
      _CalculatorKey(label: '+', type: _CalculatorKeyType.operator),
      _CalculatorKey(label: '7', type: _CalculatorKeyType.digit),
      _CalculatorKey(label: '8', type: _CalculatorKeyType.digit),
      _CalculatorKey(label: '9', type: _CalculatorKeyType.digit),
      _CalculatorKey(label: '-', type: _CalculatorKeyType.operator),
      _CalculatorKey(label: '4', type: _CalculatorKeyType.digit),
      _CalculatorKey(label: '5', type: _CalculatorKeyType.digit),
      _CalculatorKey(label: '6', type: _CalculatorKeyType.digit),
      _CalculatorKey(label: '\u00D7', type: _CalculatorKeyType.operator),
      _CalculatorKey(label: '1', type: _CalculatorKeyType.digit),
      _CalculatorKey(label: '2', type: _CalculatorKeyType.digit),
      _CalculatorKey(label: '3', type: _CalculatorKeyType.digit),
      _CalculatorKey(label: '\u00F7', type: _CalculatorKeyType.operator),
      _CalculatorKey(label: '0', type: _CalculatorKeyType.digit),
      _CalculatorKey(label: '.', type: _CalculatorKeyType.digit),
      _CalculatorKey(label: '=', type: _CalculatorKeyType.equals),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : (width * 1.24).clamp(280.0, 460.0).toDouble();
        final gridSpacing = height < 260 ? AppSpacing.xs : AppSpacing.sm;
        final panelHeight = (height * 0.24).clamp(66.0, 108.0).toDouble();
        final gridHeight =
            (height - panelHeight - gridSpacing).clamp(150.0, 430.0).toDouble();

        final panelVerticalPadding =
            (panelHeight * 0.18).clamp(8.0, 16.0).toDouble();
        final panelHorizontalPadding =
            (width * 0.035).clamp(12.0, 18.0).toDouble();
        final amountFontSize =
            (panelHeight * 0.42).clamp(24.0, 34.0).toDouble();
        final currencyFontSize =
            (panelHeight * 0.30).clamp(16.0, 22.0).toDouble();
        final backspaceButtonSize =
            (panelHeight * 0.66).clamp(38.0, 50.0).toDouble();
        final backspaceIconSize =
            (backspaceButtonSize * 0.50).clamp(18.0, 24.0).toDouble();

        final gridCellHeight = (gridHeight - (gridSpacing * 3)) / 4;
        final keyRowExtent = gridCellHeight.clamp(34.0, 120.0).toDouble();
        final keyFontSize = (keyRowExtent * 0.36).clamp(16.0, 36.0).toDouble();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: panelHeight,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: panelHorizontalPadding,
                  vertical: panelVerticalPadding,
                ),
                decoration: BoxDecoration(
                  color: palette.surface2,
                  borderRadius: BorderRadius.circular(AppSizing.radiusLg),
                  border: Border.all(color: palette.stroke),
                ),
                child: Row(
                  children: [
                    Text(
                      currencySymbol,
                      style: AppTypography.amountMedium.copyWith(
                        color: palette.textSecondary,
                        fontSize: currencyFontSize,
                      ),
                    ),
                    SizedBox(width: gridSpacing),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            displayValue,
                            textAlign: TextAlign.right,
                            style: AppTypography.amountLarge.copyWith(
                              color: palette.textPrimary,
                              fontSize: amountFontSize,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: gridSpacing),
                    IconButton(
                      onPressed: onBackspace,
                      icon: Icon(
                        LucideIcons.delete,
                        color: palette.textSecondary,
                        size: backspaceIconSize,
                      ),
                      constraints: BoxConstraints.tightFor(
                        width: backspaceButtonSize,
                        height: backspaceButtonSize,
                      ),
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(
                        backgroundColor: palette.surface1,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizing.radiusMd),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: gridSpacing),
            SizedBox(
              height: gridHeight,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: keys.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: gridSpacing,
                  crossAxisSpacing: gridSpacing,
                  mainAxisExtent: keyRowExtent,
                ),
                itemBuilder: (context, index) {
                  final key = keys[index];
                  final isOperator = key.type == _CalculatorKeyType.operator;
                  final isEquals = key.type == _CalculatorKeyType.equals;
                  final isActiveOperator =
                      isOperator && key.label == activeOperator;

                  final Color bgColor;
                  if (isEquals) {
                    bgColor = palette.accent;
                  } else if (isOperator) {
                    bgColor = isActiveOperator
                        ? palette.accent.withValues(alpha: 0.2)
                        : palette.surface2;
                  } else {
                    bgColor = palette.surface1;
                  }

                  final Color textColor;
                  if (isEquals) {
                    textColor = Colors.white;
                  } else if (isOperator && isActiveOperator) {
                    textColor = palette.accent;
                  } else {
                    textColor = palette.textPrimary;
                  }

                  final BorderSide? borderSide;
                  if (isEquals) {
                    borderSide = null;
                  } else if (isOperator && isActiveOperator) {
                    borderSide = BorderSide(color: palette.accent);
                  } else {
                    borderSide = BorderSide(color: palette.stroke);
                  }

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                      onTap: () {
                        if (isEquals) {
                          onEquals();
                          return;
                        }
                        if (isOperator) {
                          onOperator(key.label);
                          return;
                        }
                        onDigit(key.label);
                      },
                      child: Ink(
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius:
                              BorderRadius.circular(AppSizing.radiusMd),
                          border: borderSide == null
                              ? null
                              : Border.fromBorderSide(borderSide),
                        ),
                        child: Center(
                          child: Text(
                            key.label,
                            style: AppTypography.h3.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: keyFontSize,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

enum _CalculatorKeyType {
  digit,
  operator,
  equals,
}

class _CalculatorKey {
  final String label;
  final _CalculatorKeyType type;

  const _CalculatorKey({
    required this.label,
    required this.type,
  });
}
