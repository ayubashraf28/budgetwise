import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../utils/app_icon_registry.dart';
import '../../utils/errors/error_mapper.dart';

class TemplateSelectionScreen extends ConsumerStatefulWidget {
  const TemplateSelectionScreen({super.key});

  @override
  ConsumerState<TemplateSelectionScreen> createState() =>
      _TemplateSelectionScreenState();
}

class _TemplateSelectionScreenState
    extends ConsumerState<TemplateSelectionScreen> {
  late final List<_CategoryOption> _categories;
  late final Set<String> _selectedCategoryNames;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _categories = defaultCategories
        .map(
          (category) => _CategoryOption(
            name: category['name'] as String,
            iconName: category['icon'] as String? ?? 'wallet',
            colorHex: category['color'] as String? ?? '#6366F1',
            itemCount: (category['items'] as List<dynamic>? ?? const []).length,
          ),
        )
        .toList(growable: false);
    _selectedCategoryNames =
        _categories.map((category) => category.name).toSet();
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
          onPressed: () => context.go('/onboarding/budget-structure'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose your\nstarting categories',
                style: AppTypography.h2,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Pick the categories you want to start with. You can edit them later.',
                style: AppTypography.bodyMedium.copyWith(
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Text(
                    '${_selectedCategoryNames.length} selected',
                    style: AppTypography.labelMedium.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedCategoryNames
                                ..clear()
                                ..addAll(
                                  _categories.map((category) => category.name),
                                );
                            });
                          },
                    child: const Text('Select all'),
                  ),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedCategoryNames.clear();
                            });
                          },
                    child: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Category Options
              Expanded(
                child: ListView.separated(
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected =
                        _selectedCategoryNames.contains(category.name);

                    return _buildCategoryCard(category, isSelected);
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: AppSizing.buttonHeight,
                child: ElevatedButton(
                  onPressed: _selectedCategoryNames.isEmpty || _isLoading
                      ? null
                      : _handleContinue,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Continue'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(_CategoryOption category, bool isSelected) {
    final color = _parseColor(category.colorHex);
    final palette = NeoTheme.of(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          if (isSelected) {
            _selectedCategoryNames.remove(category.name);
          } else {
            _selectedCategoryNames.add(category.name);
          }
        });
      },
      child: AnimatedContainer(
        duration: AppConstants.shortAnimation,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : palette.surface1,
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
          border: Border.all(
            color: isSelected ? color : palette.stroke,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
              ),
              child: Icon(
                resolveAppIcon(category.iconName, fallback: LucideIcons.wallet),
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: AppTypography.labelLarge.copyWith(
                      color: isSelected ? color : palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category.itemCount == 1
                        ? '1 starter item'
                        : '${category.itemCount} starter items',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                LucideIcons.checkCircle,
                color: color,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleContinue() async {
    if (_selectedCategoryNames.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final selectedCategoryNames = _categories
          .where((category) => _selectedCategoryNames.contains(category.name))
          .map((category) => category.name)
          .toList(growable: false);

      await ref
          .read(onboardingNotifierProvider.notifier)
          .applySelectedCategories(selectedCategoryNames);

      if (mounted) {
        context.go('/onboarding/notifications');
      }
    } catch (error, stackTrace) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ErrorMapper.toUserMessage(error, stackTrace: stackTrace),
            ),
            backgroundColor: NeoTheme.negativeValue(context),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Color _parseColor(String hex) {
    try {
      final hexCode = hex.replaceFirst('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (_) {
      return NeoTheme.of(context).accent;
    }
  }
}

class _CategoryOption {
  final String name;
  final String iconName;
  final String colorHex;
  final int itemCount;

  const _CategoryOption({
    required this.name,
    required this.iconName,
    required this.colorHex,
    required this.itemCount,
  });
}
