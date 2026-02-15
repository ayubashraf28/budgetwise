import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/errors/error_mapper.dart';
import '../../utils/validators/email_validator.dart';
import '../../widgets/common/app_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  bool get _isBusy => _isLoading || _isGoogleLoading;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authNotifierProvider.notifier).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _nameController.text.trim(),
          );

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (error, stackTrace) {
      final appError = ErrorMapper.toAppError(
        error,
        stackTrace: stackTrace,
      );
      setState(() {
        _errorMessage = _getErrorMessage(
          appError.technicalMessage,
          fallbackMessage: appError.userMessage,
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authNotifierProvider.notifier).signInWithGoogle();
      // OAuth flow completes through deep-link callback and router auth refresh.
    } catch (error, stackTrace) {
      final appError = ErrorMapper.toAppError(
        error,
        stackTrace: stackTrace,
      );
      final technicalMessage = appError.technicalMessage;
      final normalized = technicalMessage.toLowerCase();
      if (normalized.contains('cancel')) {
        return;
      }

      setState(() {
        _errorMessage = _getErrorMessage(
          technicalMessage,
          fallbackMessage: appError.userMessage,
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(
    String error, {
    String? fallbackMessage,
  }) {
    final errorLower = error.toLowerCase();

    if (errorLower.contains('already registered') ||
        errorLower.contains('user already exists')) {
      return 'An account with this email already exists';
    }
    if (errorLower.contains('data breach')) {
      return 'This password has appeared in a data breach. Please choose a different one.';
    }
    if (errorLower.contains('weak password') ||
        errorLower.contains('password is too weak')) {
      return 'Password is too weak. Use at least 8 characters with uppercase, lowercase, and a number.';
    }
    if (errorLower.contains('invalid email')) {
      return 'Please enter a valid email address';
    }
    if (errorLower.contains('network') || errorLower.contains('connection')) {
      return 'Network error. Please check your internet connection';
    }
    if (errorLower.contains('too many requests')) {
      return 'Too many attempts. Please try again later';
    }
    if (errorLower.contains('google sign-in is not enabled') ||
        errorLower.contains('provider is not enabled')) {
      return 'Google sign-in is not enabled yet. Please contact support.';
    }
    if (errorLower.contains('google sign-in is only available')) {
      return 'Google sign-in is available on Android and iOS only.';
    }
    if (errorLower.contains('google authentication failed')) {
      return 'Google sign-in failed. Please try again';
    }
    return fallbackMessage ?? 'Unable to create account. Please try again';
  }

  void _showSuccessDialog() {
    final color = NeoTheme.positiveValue(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: NeoTheme.of(context).surface1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        ),
        contentPadding: const EdgeInsets.all(AppSpacing.lg),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(
                LucideIcons.checkCircle2,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Account Created!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: NeoTheme.of(context).textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Please check your email to verify your account before logging in.',
              style: TextStyle(
                fontSize: 13,
                color: NeoTheme.of(context).textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.withValues(alpha: 0.15),
                  foregroundColor: color,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                    side: BorderSide(color: color.withValues(alpha: 0.3)),
                  ),
                ),
                icon: const Icon(LucideIcons.logIn, size: 18),
                label: const Text(
                  'Go to Login',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = NeoTheme.of(context).accent;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header card
                  _buildHeaderCard(color),
                  const SizedBox(height: AppSpacing.xl),

                  // Error Message
                  if (_errorMessage != null) ...[
                    _buildErrorCard(),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Form card
                  _buildFormCard(color),
                  const SizedBox(height: AppSpacing.lg),

                  // Login Link
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontSize: 14,
                          color: NeoTheme.of(context).textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        style: TextButton.styleFrom(foregroundColor: color),
                        child: const Text(
                          'Log In',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSizing.radiusMd),
            ),
            child: Icon(
              LucideIcons.userPlus,
              size: 28,
              color: color,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Join ${AppConstants.appName}',
            style: AppTypography.amountMedium.copyWith(color: color),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Start managing your budget today',
            style: TextStyle(
              fontSize: 13,
              color: color.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value.clamp(0.0, 1.0),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: NeoTheme.negativeValue(context).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
          border: Border.all(
              color: NeoTheme.negativeValue(context).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: NeoTheme.negativeValue(context).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
              ),
              child: Icon(
                LucideIcons.alertCircle,
                color: NeoTheme.negativeValue(context),
                size: 18,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Registration Failed',
                    style: TextStyle(
                      color: NeoTheme.negativeValue(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: NeoTheme.negativeValue(context)
                          .withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                LucideIcons.x,
                size: 16,
                color: NeoTheme.negativeValue(context),
              ),
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard(Color color) {
    final showGoogleButton = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: NeoTheme.of(context).surface1.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        border: Border.all(color: NeoTheme.of(context).stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Create your account',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: NeoTheme.of(context).textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Fill in the details below',
            style: TextStyle(
              fontSize: 12,
              color: NeoTheme.of(context).textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Name Field
          AppTextField(
            controller: _nameController,
            labelText: 'Full Name',
            hintText: 'Enter your name',
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            prefixIcon: Icon(LucideIcons.user, size: 18, color: color),
            validator: NameValidator.validate,
          ),
          const SizedBox(height: AppSpacing.md),

          // Email Field
          AppTextField(
            controller: _emailController,
            labelText: 'Email',
            hintText: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            prefixIcon: Icon(LucideIcons.mail, size: 18, color: color),
            validator: EmailValidator.validate,
          ),
          const SizedBox(height: AppSpacing.md),

          // Password Field
          AppTextField(
            controller: _passwordController,
            labelText: 'Password',
            hintText: 'Create a password',
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
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
          const SizedBox(height: AppSpacing.md),

          // Confirm Password Field
          AppTextField(
            controller: _confirmPasswordController,
            labelText: 'Confirm Password',
            hintText: 'Confirm your password',
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
            onSubmitted: (_) => _handleRegister(),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Register Button — frosted glass style
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isBusy ? null : _handleRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: color.withValues(alpha: 0.15),
                foregroundColor: color,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                  side: BorderSide(color: color.withValues(alpha: 0.3)),
                ),
              ),
              icon: _isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  : const Icon(LucideIcons.userPlus, size: 18),
              label: Text(
                _isLoading ? 'Creating account...' : 'Create Account',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          if (showGoogleButton) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: NeoTheme.of(context).stroke,
                    height: 1,
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Text(
                    'or continue with',
                    style: TextStyle(
                      fontSize: 12,
                      color: NeoTheme.of(context).textMuted,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: NeoTheme.of(context).stroke,
                    height: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _isBusy ? null : _handleGoogleSignIn,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: NeoTheme.of(context).stroke),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                  ),
                ),
                icon: _isGoogleLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      )
                    : SvgPicture.asset(
                        'assets/icons/google_g_logo.svg',
                        width: 18,
                        height: 18,
                      ),
                label: const Text(
                  'Continue with Google',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
