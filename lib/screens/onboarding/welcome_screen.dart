import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);
    return Scaffold(
      backgroundColor: palette.appBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(),

              // Logo/Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [palette.accentBlue, palette.accentViolet],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: palette.accent.withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.wallet,
                  size: 56,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Title
              const Text(
                'Welcome to\nBudgetWise',
                style: AppTypography.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),

              // Subtitle
              Text(
                'Take control of your finances with\nintentional budgeting',
                style: AppTypography.bodyLarge.copyWith(
                  color: palette.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Features
              _buildFeature(
                context: context,
                icon: LucideIcons.target,
                title: 'Plan Your Budget',
                description: 'Set spending goals before the month begins',
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildFeature(
                context: context,
                icon: LucideIcons.trendingUp,
                title: 'Track Progress',
                description: 'See how your spending compares to your plan',
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildFeature(
                context: context,
                icon: LucideIcons.piggyBank,
                title: 'Build Better Habits',
                description: 'Make informed financial decisions daily',
              ),

              const Spacer(),

              // Get Started Button
              SizedBox(
                width: double.infinity,
                height: AppSizing.buttonHeight,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    context.go('/onboarding/template');
                  },
                  child: const Text('Get Started'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeature({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final palette = NeoTheme.of(context);
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: palette.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: palette.accent,
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
                style: AppTypography.labelLarge,
              ),
              Text(
                description,
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
