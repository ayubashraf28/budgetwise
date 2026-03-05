import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../utils/errors/error_mapper.dart';

class CurrencySelectionScreen extends ConsumerStatefulWidget {
  const CurrencySelectionScreen({super.key});

  @override
  ConsumerState<CurrencySelectionScreen> createState() =>
      _CurrencySelectionScreenState();
}

class _CurrencySelectionScreenState
    extends ConsumerState<CurrencySelectionScreen> {
  static const Map<String, String> _currencyNames = {
    'GBP': 'British Pound',
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'JPY': 'Japanese Yen',
    'INR': 'Indian Rupee',
  };

  String? _selectedCurrency;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedCurrency = ref.read(currencyProvider);
  }

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);

    return Scaffold(
      backgroundColor: palette.appBg,
      appBar: AppBar(
        backgroundColor: palette.appBg,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go('/onboarding'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose your\ncurrency',
                style: AppTypography.h2,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Pick the currency you want to use across your budget.',
                style: AppTypography.bodyMedium.copyWith(
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: ListView.separated(
                  itemCount: AppConstants.currencySymbols.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final code = AppConstants.currencySymbols.keys.elementAt(
                      index,
                    );
                    final symbol = AppConstants.currencySymbols[code]!;
                    final name = _currencyNames[code] ?? code;
                    final isSelected = _selectedCurrency == code;

                    return _buildCurrencyCard(
                      code: code,
                      symbol: symbol,
                      name: name,
                      isSelected: isSelected,
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: AppSizing.buttonHeight,
                child: ElevatedButton(
                  onPressed: _isSaving || _selectedCurrency == null
                      ? null
                      : _handleContinue,
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyCard({
    required String code,
    required String symbol,
    required String name,
    required bool isSelected,
  }) {
    final palette = NeoTheme.of(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedCurrency = code);
      },
      child: AnimatedContainer(
        duration: AppConstants.shortAnimation,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? palette.accent.withValues(alpha: 0.14)
              : palette.surface1,
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
          border: Border.all(
            color: isSelected
                ? palette.accent.withValues(alpha: 0.5)
                : palette.stroke,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: palette.surface2,
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
              ),
              child: Center(
                child: Text(
                  symbol,
                  style: AppTypography.amountMedium.copyWith(
                    color: palette.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTypography.labelLarge.copyWith(
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    code,
                    style: AppTypography.bodySmall.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                LucideIcons.checkCircle2,
                color: palette.accent,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleContinue() async {
    final selectedCurrency = _selectedCurrency;
    if (selectedCurrency == null) return;

    setState(() => _isSaving = true);

    try {
      await ref.read(profileNotifierProvider.notifier).updateProfile(
            currency: selectedCurrency,
          );
      ref.invalidate(userProfileProvider);

      if (!mounted) return;
      context.go('/onboarding/budget-structure');
    } catch (error, stackTrace) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ErrorMapper.toUserMessage(error, stackTrace: stackTrace),
          ),
          backgroundColor: NeoTheme.negativeValue(context),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
