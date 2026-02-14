part of 'home_screen.dart';

extension _HomeScreenSections on _HomeScreenState {
  Widget _buildAccountsPreview(
    List<Account> accounts,
    Map<String, double> accountBalances,
    String currencySymbol,
    bool isExpanded,
  ) {
    if (accounts.isEmpty) return const SizedBox.shrink();

    final visible = accounts.take(3).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _HomeScreenState._homeHorizontalPadding,
        0,
        _HomeScreenState._homeHorizontalPadding,
        _HomeScreenState._homeSectionSpacing,
      ),
      child: _buildGlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        tintColor: _neoSurface1,
        borderColor: _neoStroke,
        borderRadius: BorderRadius.circular(_HomeScreenState._homeCardRadius),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AdaptiveHeadingText(
                    text: 'Accounts',
                    style: _sectionTitleStyle,
                  ),
                ),
                const SizedBox(width: 8),
                _buildSectionActionButton(
                  label: 'Manage',
                  icon: LucideIcons.settings2,
                  onPressed: () => context.push('/settings/accounts'),
                ),
                const SizedBox(width: 8),
                _buildSectionChevronButton(
                  expanded: isExpanded,
                  onPressed: () {
                    ref.read(uiPreferencesProvider.notifier).setSectionExpanded(
                          UiSectionKeys.homeAccounts,
                          !isExpanded,
                        );
                  },
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: AppSpacing.sm),
              for (var i = 0; i < visible.length; i++) ...[
                _buildAccountPreviewRow(
                  visible[i],
                  accountBalances[visible[i].id] ?? visible[i].openingBalance,
                  currencySymbol,
                  onTap: () => context.push(
                    '/settings/accounts?accountId=${Uri.encodeComponent(visible[i].id)}',
                  ),
                ),
                if (i < visible.length - 1)
                  Divider(
                    height: 16,
                    color: _neoStroke.withValues(alpha: 0.85),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccountPreviewRow(
      Account account, double balance, String currencySymbol,
      {VoidCallback? onTap}) {
    final isNegative = balance < 0;
    final amountColor = isNegative ? _negativeColor : _positiveColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: _HomeScreenState._homeRowVerticalPadding),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _neoSurface2,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: _neoStroke),
              ),
              child: Icon(
                _getAccountTypeIcon(account.type),
                size: NeoIconSizes.lg,
                color: _neoTextSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                account.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _rowTitleStyle,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '$currencySymbol${_formatAmount(balance)}',
              style: _rowAmountStyle(amountColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    String? cornerLabel,
    required double amount,
    required bool isAmountVisible,
    required String currencySymbol,
    required IconData icon,
    required Color lightAccent,
    required Color darkAccent,
    required List<Color> gradientColors,
    required IconData footerIcon,
    required String footerLabel,
    required double amountFontSize,
    required double cardHeight,
    required double headerHeight,
    required double footerHeight,
    VoidCallback? onTap,
  }) {
    final isLight = _isLightMode(context);
    final textColor = isLight ? lightAccent : darkAccent;
    final iconBgColor = isLight
        ? lightAccent.withValues(alpha: 0.22)
        : darkAccent.withValues(alpha: 0.18);
    final footerColor = isLight
        ? textColor.withValues(alpha: 0.95)
        : textColor.withValues(alpha: 0.88);
    final textScale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(0.85, 1.3).toDouble();
    final cornerText = cornerLabel?.trim() ?? '';
    final hasCornerLabel = cornerText.isNotEmpty;
    final showCornerLabel = hasCornerLabel && textScale < 1.1;
    final chipBorderColor = isLight
        ? textColor.withValues(alpha: 0.42)
        : textColor.withValues(alpha: 0.34);
    final chipBgColor = isLight
        ? Colors.white.withValues(alpha: 0.30)
        : Colors.black.withValues(alpha: 0.18);
    final amountStyle = AppTypography.amountMedium.copyWith(
      color: textColor,
      fontWeight: FontWeight.w700,
      fontSize: amountFontSize,
      height: 1.0,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_HomeScreenState._homeCardRadius),
        child: SizedBox(
          height: cardHeight,
          child: _buildGlassCard(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            tintColor: gradientColors.first,
            gradientColors: gradientColors,
            borderColor: isLight
                ? lightAccent.withValues(alpha: 0.46)
                : darkAccent.withValues(alpha: 0.40),
            borderRadius:
                BorderRadius.circular(_HomeScreenState._homeCardRadius),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: headerHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: iconBgColor,
                          borderRadius:
                              BorderRadius.circular(AppSizing.radiusSm),
                          border: Border.all(
                            color: isLight
                                ? lightAccent.withValues(alpha: 0.42)
                                : darkAccent.withValues(alpha: 0.34),
                          ),
                        ),
                        child: Icon(
                          icon,
                          size: NeoIconSizes.xs,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: AdaptiveHeadingText(
                          text: title,
                          maxLines: 2,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.02,
                          ),
                        ),
                      ),
                      if (showCornerLabel) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: chipBgColor,
                            borderRadius:
                                BorderRadius.circular(AppSizing.radiusFull),
                            border: Border.all(color: chipBorderColor),
                          ),
                          child: Text(
                            cornerText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _rowSecondaryStyle.copyWith(
                              color: footerColor.withValues(alpha: 0.9),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        isAmountVisible
                            ? '$currencySymbol${_formatAmount(amount)}'
                            : '\u2022\u2022\u2022\u2022',
                        style: amountStyle,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: footerHeight,
                  child: Row(
                    children: [
                      Icon(
                        footerIcon,
                        size: 10,
                        color: footerColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          footerLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: footerColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.05,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final isLight = _isLightMode(context);
    final textScale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(0.85, 1.3).toDouble();
    final horizontalPadding =
        (12.0 - (textScale - 1.0) * 4.0).clamp(8.0, 12.0).toDouble();
    final verticalPadding =
        (8.0 + (textScale - 1.0) * 3.0).clamp(8.0, 11.0).toDouble();
    final minHeight = (34.0 + (textScale - 1.0) * 8.0).clamp(34.0, 40.0);
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: NeoIconSizes.sm, color: _neoLime),
      label: Text(label, style: _sectionActionStyle),
      style: OutlinedButton.styleFrom(
        foregroundColor: _neoLime,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        minimumSize: Size(0, minHeight),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        backgroundColor:
            isLight ? _neoLime.withValues(alpha: 0.10) : Colors.transparent,
        side: BorderSide(
          color: _neoLime.withValues(alpha: isLight ? 0.55 : 0.4),
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildSectionChevronButton({
    required bool expanded,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppSizing.radiusFull),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: _neoSurface2,
          borderRadius: BorderRadius.circular(AppSizing.radiusFull),
          border: Border.all(color: _neoStroke),
        ),
        child: Icon(
          expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
          size: NeoIconSizes.md,
          color: _neoTextSecondary,
        ),
      ),
    );
  }

  Widget _buildUpcomingPayments(
    String currencySymbol,
    AsyncValue<List<Subscription>> upcoming,
    bool isExpanded,
  ) {
    return upcoming.when(
      data: (upcomingList) {
        final sorted = [...upcomingList]
          ..sort((a, b) => a.daysUntilDue.compareTo(b.daysUntilDue));
        final visible = sorted.take(3).toList();

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            _HomeScreenState._homeHorizontalPadding,
            0,
            _HomeScreenState._homeHorizontalPadding,
            _HomeScreenState._homeSectionSpacing,
          ),
          child: _buildGlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            tintColor: _neoSurface1,
            borderColor: _neoStroke,
            borderRadius:
                BorderRadius.circular(_HomeScreenState._homeCardRadius),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AdaptiveHeadingText(
                        text: 'Upcoming payments',
                        style: _sectionTitleStyle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildSectionActionButton(
                      label: 'View all',
                      icon: LucideIcons.calendarRange,
                      onPressed: () => context.push('/subscriptions'),
                    ),
                    const SizedBox(width: 8),
                    _buildSectionChevronButton(
                      expanded: isExpanded,
                      onPressed: () {
                        ref
                            .read(uiPreferencesProvider.notifier)
                            .setSectionExpanded(
                              UiSectionKeys.homeUpcoming,
                              !isExpanded,
                            );
                      },
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const SizedBox(height: AppSpacing.sm),
                  if (sorted.isEmpty)
                    _buildNoUpcomingPaymentsState()
                  else ...[
                    for (var index = 0; index < visible.length; index++) ...[
                      _buildUpcomingPaymentTile(visible[index], currencySymbol),
                      if (index < visible.length - 1)
                        Divider(
                          height: 16,
                          color: _neoStroke.withValues(alpha: 0.85),
                        ),
                    ],
                    if (sorted.length > visible.length)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '+${sorted.length - visible.length} more upcoming',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _rowSecondaryStyle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => context.push('/subscriptions'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 0,
                                  vertical: 0,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'See all',
                                style: _sectionActionStyle,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildNoUpcomingPaymentsState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _neoSurface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _neoStroke),
            ),
            child: Icon(
              LucideIcons.calendarCheck2,
              color: _neoTextSecondary,
              size: NeoIconSizes.xl,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No upcoming payments',
            style: _rowTitleStyle,
          ),
          const SizedBox(height: 2),
          Text(
            'You are all caught up',
            style: _rowSecondaryStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingPaymentTile(Subscription sub, String currencySymbol) {
    final accentColor = sub.isOverdue ? _negativeColor : sub.colorValue;
    final statusColor = sub.isOverdue
        ? _negativeColor
        : sub.isDueToday
            ? _warningColor
            : _positiveColor;

    return InkWell(
      onTap: () => context.push('/subscriptions'),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: _HomeScreenState._homeRowVerticalPadding),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _neoSurface2,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: _neoStroke),
              ),
              child: Icon(
                _getIcon(sub.icon),
                size: NeoIconSizes.lg,
                color: accentColor,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sub.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _rowTitleStyle,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormat('MMM d').format(sub.nextDueDate)} - ${sub.billingCycleLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _rowSecondaryStyle,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$currencySymbol${_formatAmount(sub.amount)}',
                  style: _rowAmountStyle(_neoTextPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  sub.isOverdue
                      ? 'Overdue'
                      : sub.isDueToday
                          ? 'Due today'
                          : 'In ${sub.daysUntilDue}d',
                  style: _rowSecondaryStyle.copyWith(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
}
