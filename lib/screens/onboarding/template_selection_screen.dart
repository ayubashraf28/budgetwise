import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../services/services.dart';
import '../../utils/category_name_utils.dart';

class TemplateSelectionScreen extends ConsumerStatefulWidget {
  const TemplateSelectionScreen({super.key});

  @override
  ConsumerState<TemplateSelectionScreen> createState() =>
      _TemplateSelectionScreenState();
}

class _TemplateSelectionScreenState
    extends ConsumerState<TemplateSelectionScreen> {
  String? _selectedTemplate;
  bool _isLoading = false;

  final List<_TemplateOption> _templates = const [
    _TemplateOption(
      id: 'individual',
      title: 'Individual',
      description: 'Perfect for personal budgeting',
      icon: LucideIcons.user,
      color: AppColors.info,
    ),
    _TemplateOption(
      id: 'student',
      title: 'Student',
      description: 'Optimized for student life',
      icon: LucideIcons.graduationCap,
      color: AppColors.warning,
    ),
    _TemplateOption(
      id: 'family',
      title: 'Family',
      description: 'Manage household expenses',
      icon: LucideIcons.users,
      color: AppColors.success,
    ),
    _TemplateOption(
      id: 'freelancer',
      title: 'Freelancer',
      description: 'Track business and personal',
      icon: LucideIcons.briefcase,
      color: AppColors.primary,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
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
                'Choose your\nbudget template',
                style: AppTypography.h2,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Select the option that best describes your situation',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Template Options
              Expanded(
                child: ListView.separated(
                  itemCount: _templates.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final template = _templates[index];
                    final isSelected = _selectedTemplate == template.id;

                    return _buildTemplateCard(template, isSelected);
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: AppSizing.buttonHeight,
                child: ElevatedButton(
                  onPressed: _selectedTemplate == null || _isLoading
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

  Widget _buildTemplateCard(_TemplateOption template, bool isSelected) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedTemplate = template.id);
      },
      child: AnimatedContainer(
        duration: AppConstants.shortAnimation,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? template.color.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
          border: Border.all(
            color: isSelected ? template.color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: template.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
              ),
              child: Icon(
                template.icon,
                color: template.color,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.title,
                    style: AppTypography.labelLarge.copyWith(
                      color:
                          isSelected ? template.color : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    template.description,
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                LucideIcons.checkCircle,
                color: template.color,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleContinue() async {
    if (_selectedTemplate == null) return;

    setState(() => _isLoading = true);

    try {
      // Get or create first month
      final monthService = MonthService();
      final month = await monthService.getOrCreateCurrentMonth();

      // Create default categories for selected template
      final categoryService = CategoryService();
      final itemService = ItemService();

      // Check if categories already exist for this month (from previous attempt)
      final existingCategories =
          await categoryService.getCategoriesForMonth(month.id);

      // Only create categories if none exist
      if (existingCategories.isEmpty) {
        final templateCategories = budgetTemplates[_selectedTemplate] ?? [];

        for (final categoryName in templateCategories) {
          if (isReservedCategoryName(categoryName)) continue;

          // Find category template
          final categoryTemplate = defaultCategories.firstWhere(
            (c) => c['name'] == categoryName,
            orElse: () => {
              'name': categoryName,
              'icon': 'wallet',
              'color': '#6366f1',
              'items': <Map<String, dynamic>>[],
            },
          );

          // Create category
          final category = await categoryService.createCategory(
            monthId: month.id,
            name: categoryTemplate['name'] as String,
            icon: categoryTemplate['icon'] as String? ?? 'wallet',
            color: categoryTemplate['color'] as String? ?? '#6366f1',
          );

          // Create items for category
          final items = categoryTemplate['items'] as List<dynamic>? ?? [];
          for (final itemData in items) {
            final itemMap = itemData as Map<String, dynamic>;
            await itemService.createItem(
              categoryId: category.id,
              name: itemMap['name'] as String,
              projected: (itemMap['projected'] as num?)?.toDouble() ?? 0,
            );
          }
        }
      }

      // Mark onboarding as completed
      final profileService = ProfileService();
      await profileService.completeOnboarding();

      if (mounted) {
        context.go('/onboarding/complete');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }
}

class _TemplateOption {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _TemplateOption({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
