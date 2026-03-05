import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';

class BudgetStructureSelectionScreen extends ConsumerStatefulWidget {
  const BudgetStructureSelectionScreen({super.key});

  @override
  ConsumerState<BudgetStructureSelectionScreen> createState() =>
      _BudgetStructureSelectionScreenState();
}

class _BudgetStructureSelectionScreenState
    extends ConsumerState<BudgetStructureSelectionScreen> {
  BudgetStructure? _selectedStructure;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedStructure = ref.read(budgetStructureProvider);
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
          onPressed: () => context.go('/onboarding/currency'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose your\nbudget style',
                style: AppTypography.h2,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'You can keep things simple or track every category in detail.',
                style: AppTypography.bodyMedium.copyWith(
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: ListView(
                  children: [
                    _buildStructureCard(
                      structure: BudgetStructure.simple,
                      title: 'Simple',
                      description:
                          'Track spending by category. Best for straightforward budgets.',
                      icon: LucideIcons.layers,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildStructureCard(
                      structure: BudgetStructure.detailed,
                      title: 'Detailed',
                      description:
                          'Break categories into items for more granular tracking.',
                      icon: LucideIcons.listTodo,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: AppSizing.buttonHeight,
                child: ElevatedButton(
                  onPressed: _isSaving || _selectedStructure == null
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

  Widget _buildStructureCard({
    required BudgetStructure structure,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final palette = NeoTheme.of(context);
    final isSelected = _selectedStructure == structure;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedStructure = structure);
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: palette.surface2,
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
              ),
              child: Icon(
                icon,
                color: isSelected ? palette.accent : palette.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelLarge.copyWith(
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
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
    final selectedStructure = _selectedStructure;
    if (selectedStructure == null) return;

    setState(() => _isSaving = true);

    await ref.read(uiPreferencesProvider.notifier).setBudgetStructure(
          selectedStructure,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);
    context.go('/onboarding/categories');
  }
}
