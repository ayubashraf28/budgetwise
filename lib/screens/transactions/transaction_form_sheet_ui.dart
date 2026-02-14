part of 'transaction_form_sheet.dart';

extension _TransactionFormSheetUi on _TransactionFormSheetState {
  Widget _buildTopBar() {
    final palette = NeoTheme.of(context);
    return Row(
      children: [
        TextButton.icon(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          icon: const Icon(LucideIcons.x, size: AppSizing.iconSm),
          label: Text(
            'CANCEL',
            style: AppTypography.labelLarge.copyWith(letterSpacing: 0.2),
          ),
          style: TextButton.styleFrom(
            foregroundColor: palette.textSecondary,
          ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: _isLoading ? null : _handleSubmit,
          icon: _isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: palette.accent,
                  ),
                )
              : const Icon(LucideIcons.check, size: AppSizing.iconSm),
          label: Text(
            _isLoading ? 'SAVING' : 'SAVE',
            style: AppTypography.labelLarge.copyWith(letterSpacing: 0.2),
          ),
          style: TextButton.styleFrom(
            foregroundColor: palette.accent,
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming Soon')),
                );
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              Icon(
                LucideIcons.check,
                size: AppSizing.iconXs,
                color: NeoTheme.controlSelectedForeground(context),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected
                    ? NeoTheme.controlSelectedForeground(context)
                    : palette.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
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

  Widget _buildBottomBar() {
    final palette = NeoTheme.of(context);
    return Container(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: palette.stroke.withValues(alpha: 0.8)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildBottomAction(
              icon: LucideIcons.calendar,
              value: DateFormat('MMM d, yyyy').format(_selectedDate),
              onTap: _isLoading ? null : _selectDate,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildBottomAction(
              icon: LucideIcons.clock3,
              value: DateFormat('h:mm a').format(_selectedDate),
              onTap: _isLoading ? null : _selectTime,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction({
    required IconData icon,
    required String value,
    required VoidCallback? onTap,
  }) {
    final palette = NeoTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizing.radiusSm),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizing.radiusSm),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: AppSizing.iconSm,
                color: palette.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: palette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
