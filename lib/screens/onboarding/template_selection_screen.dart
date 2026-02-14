import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../utils/errors/error_mapper.dart';

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

  List<_TemplateOption> _templatesFor(BuildContext context) => [
        _TemplateOption(
          id: 'individual',
          title: 'Individual',
          description: 'Perfect for personal budgeting',
          icon: LucideIcons.user,
          color: NeoTheme.infoValue(context),
        ),
        _TemplateOption(
          id: 'student',
          title: 'Student',
          description: 'Optimized for student life',
          icon: LucideIcons.graduationCap,
          color: NeoTheme.warningValue(context),
        ),
        _TemplateOption(
          id: 'family',
          title: 'Family',
          description: 'Manage household expenses',
          icon: LucideIcons.users,
          color: NeoTheme.positiveValue(context),
        ),
        _TemplateOption(
          id: 'freelancer',
          title: 'Freelancer',
          description: 'Track business and personal',
          icon: LucideIcons.briefcase,
          color: NeoTheme.of(context).accent,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final templates = _templatesFor(context);
    return Scaffold(
      backgroundColor: NeoTheme.of(context).appBg,
      appBar: AppBar(
        backgroundColor: NeoTheme.of(context).appBg,
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
                  color: NeoTheme.of(context).textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Template Options
              Expanded(
                child: ListView.separated(
                  itemCount: templates.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final template = templates[index];
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
              : NeoTheme.of(context).surface1,
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
          border: Border.all(
            color: isSelected ? template.color : NeoTheme.of(context).stroke,
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
                      color: isSelected
                          ? template.color
                          : NeoTheme.of(context).textPrimary,
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
      await ref
          .read(onboardingNotifierProvider.notifier)
          .applyTemplate(_selectedTemplate!);

      if (mounted) {
        context.go('/onboarding/complete');
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
