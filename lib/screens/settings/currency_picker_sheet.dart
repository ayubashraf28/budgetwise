import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';

class CurrencyPickerSheet extends ConsumerWidget {
  const CurrencyPickerSheet({super.key});

  static const Map<String, String> _currencyNames = {
    'GBP': 'British Pound (GBP)',
    'USD': 'US Dollar (USD)',
    'EUR': 'Euro (EUR)',
    'JPY': 'Japanese Yen (JPY)',
    'INR': 'Indian Rupee (INR)',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCurrency = ref.watch(currencyProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizing.radiusXl)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Currency',
                    style: AppTypography.h3,
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Currency list - Flexible allows scrolling when space is limited
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: AppConstants.currencySymbols.length,
                itemBuilder: (context, index) {
                  final code = AppConstants.currencySymbols.keys.elementAt(index);
                  final symbol = AppConstants.currencySymbols[code]!;
                  final name = _currencyNames[code]!;
                  final isSelected = code == currentCurrency;

                  return _CurrencyTile(
                    symbol: symbol,
                    name: name,
                    code: code,
                    isSelected: isSelected,
                    onTap: () async {
                      if (code != currentCurrency) {
                        // Update profile with new currency
                        await ref.read(profileNotifierProvider.notifier).updateProfile(
                              currency: code,
                            );

                        // Refresh user profile to trigger reactive updates
                        ref.invalidate(userProfileProvider);
                      }

                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _CurrencyTile extends StatelessWidget {
  final String symbol;
  final String name;
  final String code;
  final bool isSelected;
  final VoidCallback onTap;

  const _CurrencyTile({
    required this.symbol,
    required this.name,
    required this.code,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              // Currency symbol in circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                ),
                child: Center(
                  child: Text(
                    symbol,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Currency name
              Expanded(
                child: Text(
                  name,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),

              // Check icon if selected
              if (isSelected)
                const Icon(
                  LucideIcons.check,
                  color: AppColors.primary,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
