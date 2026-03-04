import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/errors/error_mapper.dart';
import '../../utils/validators/email_validator.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/neo_page_components.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authServiceProvider)
          .updatePassword(_passwordController.text.trim());
      ref.read(passwordRecoveryPendingProvider.notifier).state = false;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully.'),
        ),
      );
      context.go('/home');
    } catch (error, stackTrace) {
      final appError = ErrorMapper.toAppError(error, stackTrace: stackTrace);
      final message = _getErrorMessage(
        appError.technicalMessage,
        fallbackMessage: appError.userMessage,
      );
      setState(() {
        _errorMessage = message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleCancel() async {
    ref.read(passwordRecoveryPendingProvider.notifier).state = false;

    try {
      await ref.read(authNotifierProvider.notifier).signOut();
    } catch (_) {
      // Best-effort cleanup; route the user back to login either way.
    }

    if (!mounted) return;
    context.go('/login');
  }

  void _returnToLogin() {
    ref.read(passwordRecoveryPendingProvider.notifier).state = false;
    context.go('/login');
  }

  String _getErrorMessage(
    String error, {
    String? fallbackMessage,
  }) {
    final errorLower = error.toLowerCase();

    if (errorLower.contains('expired') ||
        errorLower.contains('not authenticated') ||
        errorLower.contains('session') ||
        errorLower.contains('jwt')) {
      return 'This password reset link is no longer valid. Request a new one and try again.';
    }
    if (errorLower.contains('data breach')) {
      return 'This password has appeared in a data breach. Please choose a different one.';
    }
    if (errorLower.contains('weak password') ||
        errorLower.contains('password is too weak')) {
      return 'Password must be at least 8 characters and include mixed character types.';
    }
    return fallbackMessage ?? 'Unable to update password. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);
    final accent = palette.accent;
    final currentUser = ref.watch(currentUserProvider) ??
        ref.read(authServiceProvider).currentUser;
    final hasRecoverySession = currentUser != null;

    return Scaffold(
      backgroundColor: palette.appBg,
      body: NeoPageBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(NeoLayout.screenPadding),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeaderCard(accent),
                    const SizedBox(height: AppSpacing.xl),
                    if (!hasRecoverySession)
                      _buildInvalidStateCard()
                    else
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_errorMessage != null) ...[
                              _buildErrorCard(),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            _buildFormCard(accent),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(Color color) {
    return NeoGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  NeoTheme.of(context).accentBlue,
                  NeoTheme.of(context).accentViolet
                ],
              ),
              borderRadius: BorderRadius.circular(AppSizing.radiusMd),
            ),
            child: const Icon(
              LucideIcons.lock,
              size: 28,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Set New Password',
            style: AppTypography.amountMedium.copyWith(
              color: NeoTheme.of(context).textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Choose a new password for your ${AppConstants.appName} account.',
            style: TextStyle(
              fontSize: 13,
              color: NeoTheme.of(context).textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(Color color) {
    final palette = NeoTheme.of(context);
    final isLight = NeoTheme.isLight(context);

    return NeoGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Update your password',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Use a strong password you have not used elsewhere.',
            style: TextStyle(
              fontSize: 12,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _passwordController,
            labelText: 'New Password',
            hintText: 'Enter your new password',
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (!mounted) return;
              setState(() {});
            },
            prefixIcon: Icon(LucideIcons.lock, size: 18, color: color),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                size: 18,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: PasswordValidator.validate,
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildPasswordStrengthIndicator(),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _confirmPasswordController,
            labelText: 'Confirm Password',
            hintText: 'Confirm your new password',
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            prefixIcon: Icon(LucideIcons.shieldCheck, size: 18, color: color),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? LucideIcons.eye : LucideIcons.eyeOff,
                size: 18,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            validator: (value) => PasswordValidator.validateConfirmPassword(
              value,
              _passwordController.text,
            ),
            onSubmitted: (_) => _handleUpdatePassword(),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleUpdatePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor:
                    isLight ? palette.textPrimary : palette.surface1,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                ),
              ),
              icon: _isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isLight ? palette.textPrimary : palette.surface1,
                      ),
                    )
                  : const Icon(LucideIcons.check, size: 18),
              label: Text(
                _isLoading ? 'Updating password...' : 'Update Password',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: _isLoading ? null : _handleCancel,
            child: const Text('Cancel and return to login'),
          ),
        ],
      ),
    );
  }

  Widget _buildInvalidStateCard() {
    final warning = NeoTheme.warningValue(context);

    return NeoGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: warning.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppSizing.radiusMd),
              border: Border.all(color: warning.withValues(alpha: 0.28)),
            ),
            child: Icon(
              LucideIcons.alertTriangle,
              color: warning,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Invalid or expired link',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: NeoTheme.of(context).textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'This password reset link is no longer valid. Request a new password reset email to continue.',
            style: TextStyle(
              fontSize: 13,
              color: NeoTheme.of(context).textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _returnToLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: warning.withValues(alpha: 0.16),
                foregroundColor: warning,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                  side: BorderSide(color: warning.withValues(alpha: 0.28)),
                ),
              ),
              icon: const Icon(LucideIcons.arrowLeft, size: 18),
              label: const Text(
                'Return to Login',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    final danger = NeoTheme.negativeValue(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: danger.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        border: Border.all(color: danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: danger.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSizing.radiusMd),
            ),
            child: Icon(
              LucideIcons.alertCircle,
              color: danger,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: danger.withValues(alpha: 0.9),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final value = _passwordController.text;
    final strength = PasswordValidator.strength(value);
    final palette = NeoTheme.of(context);

    final Color strengthColor;
    final String strengthLabel;
    final double progress;

    switch (strength) {
      case PasswordStrength.weak:
        strengthColor = NeoTheme.negativeValue(context);
        strengthLabel = 'Weak';
        progress = 0.33;
        break;
      case PasswordStrength.medium:
        strengthColor = NeoTheme.warningValue(context);
        strengthLabel = 'Medium';
        progress = 0.66;
        break;
      case PasswordStrength.strong:
        strengthColor = NeoTheme.positiveValue(context);
        strengthLabel = 'Strong';
        progress = 1.0;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Strength:',
              style: AppTypography.bodySmall.copyWith(
                color: palette.textMuted,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              strengthLabel,
              style: AppTypography.bodySmall.copyWith(
                color: strengthColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: value.isEmpty ? 0 : progress,
            minHeight: 4,
            backgroundColor: palette.stroke,
            valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Use 8+ chars and at least 3 of uppercase, lowercase, number, symbol.',
          style: AppTypography.bodySmall.copyWith(
            color: palette.textMuted,
          ),
        ),
      ],
    );
  }
}
