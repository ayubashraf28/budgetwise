import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';

class SetupCompleteScreen extends StatefulWidget {
  const SetupCompleteScreen({super.key});

  @override
  State<SetupCompleteScreen> createState() => _SetupCompleteScreenState();
}

class _SetupCompleteScreenState extends State<SetupCompleteScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);
    final success = NeoTheme.positiveValue(context);
    return Scaffold(
      backgroundColor: palette.appBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(),

              // Success Icon
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            success.withValues(alpha: 0.92),
                            success.withValues(alpha: 0.75),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(60),
                        boxShadow: [
                          BoxShadow(
                            color: success.withValues(alpha: 0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.check,
                        size: 56,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              // Title
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'You\'re all set!',
                  style: AppTypography.h1,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Description
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Your budget is ready. Start by adding your\nincome sources and adjusting your budget.',
                  style: AppTypography.bodyLarge.copyWith(
                    color: palette.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Tips
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: palette.surface1,
                    borderRadius: BorderRadius.circular(AppSizing.radiusLg),
                  ),
                  child: Column(
                    children: [
                      _buildTip(
                        icon: LucideIcons.plus,
                        text: 'Add your income sources first',
                      ),
                      Divider(height: 24, color: palette.stroke),
                      _buildTip(
                        icon: LucideIcons.edit,
                        text: 'Set budget amounts for each category',
                      ),
                      Divider(height: 24, color: palette.stroke),
                      _buildTip(
                        icon: LucideIcons.zap,
                        text: 'Log transactions as you spend',
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Start Button
              SizedBox(
                width: double.infinity,
                height: AppSizing.buttonHeight,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    context.go('/home');
                  },
                  child: const Text('Start Budgeting'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTip({required IconData icon, required String text}) {
    final palette = NeoTheme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: palette.accent,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMedium.copyWith(
              color: palette.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
