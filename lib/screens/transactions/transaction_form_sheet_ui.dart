part of 'transaction_form_sheet.dart';

extension _TransactionFormSheetUi on _TransactionFormSheetState {
  Widget _buildDateTimeBar() {
    return Row(
      children: [
        Expanded(
          child: _buildTopMetaAction(
            icon: LucideIcons.calendar,
            label: 'Date',
            value: DateFormat('MMM d, yyyy').format(_selectedDate),
            onTap: _isLoading ? null : _selectDate,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildTopMetaAction(
            icon: LucideIcons.clock3,
            label: 'Time',
            value: DateFormat('h:mm a').format(_selectedDate),
            onTap: _isLoading ? null : _selectTime,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeToggle() {
    final palette = NeoTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.surface2,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeSegment(
              label: 'INCOME',
              isSelected: _transactionType == TransactionType.income,
              onTap: () {
                _updateState(() {
                  _transactionType = TransactionType.income;
                  _selectedCategoryId = null;
                  _selectedItemId = null;
                });
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildTypeSegment(
              label: 'EXPENSE',
              isSelected: _transactionType == TransactionType.expense,
              onTap: () {
                _updateState(() {
                  _transactionType = TransactionType.expense;
                  _selectedIncomeSourceId = null;
                });
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildTypeSegment(
              label: 'TRANSFER',
              isSelected: false,
              onTap: () {
                showNeoInfoSnackBar(context, 'Coming Soon');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSegment({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final palette = NeoTheme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppSizing.radiusSm),
      onTap: _isLoading ? null : onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? NeoTheme.controlSelectedBackground(context)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizing.radiusSm),
          border: Border.all(
            color: isSelected
                ? NeoTheme.controlSelectedBorder(context)
                : Colors.transparent,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 108;
            final labelStyle = AppTypography.labelMedium.copyWith(
              color: isSelected
                  ? NeoTheme.controlSelectedForeground(context)
                  : palette.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: isNarrow ? 11 : 12,
            );

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  Icon(
                    LucideIcons.check,
                    size: isNarrow ? 12 : AppSizing.iconXs,
                    color: NeoTheme.controlSelectedForeground(context),
                  ),
                  const SizedBox(width: 3),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: labelStyle,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSelectorPill({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback? onTap,
  }) {
    final palette = NeoTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: palette.surface2,
            borderRadius: BorderRadius.circular(AppSizing.radiusMd),
            border: Border.all(color: palette.stroke),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: AppSizing.iconSm,
                color: palette.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyLarge.copyWith(
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                LucideIcons.chevronDown,
                size: AppSizing.iconSm,
                color: palette.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    final palette = NeoTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: palette.surface2,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
      ),
      child: TextField(
        controller: _noteController,
        minLines: 1,
        maxLines: 2,
        inputFormatters: [
          LengthLimitingTextInputFormatter(
              InputValidator.maxTransactionNoteLength),
        ],
        style: AppTypography.bodyLarge.copyWith(
          color: palette.textPrimary,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          isCollapsed: true,
          hintText: 'Add notes',
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: palette.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildTopMetaAction({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback? onTap,
  }) {
    final palette = NeoTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: palette.surface2,
            borderRadius: BorderRadius.circular(AppSizing.radiusMd),
            border: Border.all(color: palette.stroke),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: AppSizing.iconSm,
                color: palette.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar({
    required bool isCompact,
    required double availableWidth,
  }) {
    final palette = NeoTheme.of(context);
    final centerGap = (availableWidth * 0.08).clamp(8.0, 28.0).toDouble();
    final buttonHeight =
        isCompact ? AppSizing.buttonHeightCompact : AppSizing.buttonHeight;
    final topPadding = isCompact ? AppSpacing.xs : AppSpacing.sm;
    final showSaveIcon = !isCompact || availableWidth > 360;

    return Container(
      padding: EdgeInsets.only(top: topPadding),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: palette.stroke.withValues(alpha: 0.8)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              text: 'Cancel',
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              variant: AppButtonVariant.outline,
              height: buttonHeight,
            ),
          ),
          SizedBox(width: centerGap),
          Expanded(
            child: AppButton(
              text: _isLoading ? 'Saving' : 'Save',
              onPressed: _isLoading ? null : _handleSubmit,
              icon: _isLoading || !showSaveIcon ? null : LucideIcons.check,
              isLoading: _isLoading,
              height: buttonHeight,
            ),
          ),
        ],
      ),
    );
  }
}
