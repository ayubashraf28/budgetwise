import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators/email_validator.dart';
import '../../widgets/common/app_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isCredentialError = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isCredentialError = false;
    });

    try {
      await ref.read(authNotifierProvider.notifier).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.toString());
        _isCredentialError =
            e.toString().toLowerCase().contains('invalid login credentials') ||
                e
                    .toString()
                    .toLowerCase()
                    .contains('invalid email or password');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(String error) {
    final errorLower = error.toLowerCase();

    if (errorLower.contains('invalid login credentials') ||
        errorLower.contains('invalid email or password')) {
      return 'The email or password you entered is incorrect. Please check your email address exists and your password is correct.';
    }
    if (errorLower.contains('email not confirmed')) {
      return 'Please verify your email before logging in';
    }
    if (errorLower.contains('user not found')) {
      return 'No account found with this email address';
    }
    if (errorLower.contains('too many requests')) {
      return 'Too many login attempts. Please try again later';
    }
    if (errorLower.contains('network') || errorLower.contains('connection')) {
      return 'Network error. Please check your internet connection';
    }
    return 'Unable to sign in. Please try again';
  }

  @override
  Widget build(BuildContext context) {
    const color = AppColors.savings;

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
                  // Logo card
                  _buildLogoCard(color),
                  const SizedBox(height: AppSpacing.xl),

                  // Error Message
                  if (_errorMessage != null) ...[
                    _buildErrorCard(),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Form card
                  _buildFormCard(color),
                  const SizedBox(height: AppSpacing.lg),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/register'),
                        style: TextButton.styleFrom(foregroundColor: color),
                        child: const Text(
                          'Sign Up',
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

  Widget _buildLogoCard(Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSizing.radiusMd),
            ),
            child: Icon(
              LucideIcons.wallet,
              size: 28,
              color: color,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // App Name
          Text(
            AppConstants.appName,
            style: AppTypography.amountMedium.copyWith(color: color),
          ),
          const SizedBox(height: AppSpacing.xs),
          // Tagline
          Text(
            'Plan your finances, track your spending',
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
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
              ),
              child: const Icon(
                LucideIcons.alertCircle,
                color: AppColors.error,
                size: 18,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Login Failed',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: AppColors.error.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                  if (_isCredentialError) ...[
                    const SizedBox(height: 2),
                    Text(
                      "If you don't have an account, sign up below.",
                      style: TextStyle(
                        color: AppColors.error.withValues(alpha: 0.6),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.x, size: 16, color: AppColors.error),
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                  _isCredentialError = false;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard(Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section title
          const Text(
            'Welcome back',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Sign in to your account',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Email Field
          Container(
            decoration: _isCredentialError
                ? BoxDecoration(
                    border:
                        Border.all(color: AppColors.error, width: 1.5),
                    borderRadius:
                        BorderRadius.circular(AppSizing.radiusMd),
                  )
                : null,
            child: AppTextField(
              controller: _emailController,
              labelText: 'Email',
              hintText: 'Enter your email',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              prefixIcon: Icon(
                LucideIcons.mail,
                size: 18,
                color: _isCredentialError ? AppColors.error : color,
              ),
              validator: EmailValidator.validate,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Password Field
          Container(
            decoration: _isCredentialError
                ? BoxDecoration(
                    border:
                        Border.all(color: AppColors.error, width: 1.5),
                    borderRadius:
                        BorderRadius.circular(AppSizing.radiusMd),
                  )
                : null,
            child: AppTextField(
              controller: _passwordController,
              labelText: 'Password',
              hintText: 'Enter your password',
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              prefixIcon: Icon(
                LucideIcons.lock,
                size: 18,
                color: _isCredentialError ? AppColors.error : color,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? LucideIcons.eye
                      : LucideIcons.eyeOff,
                  size: 18,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              validator: PasswordValidator.validate,
              onSubmitted: (_) => _handleLogin(),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Forgot Password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // TODO: Navigate to forgot password screen
              },
              style: TextButton.styleFrom(
                foregroundColor: color,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
              ),
              child: const Text(
                'Forgot Password?',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Login Button — frosted glass style
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleLogin,
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
                  : const Icon(LucideIcons.logIn, size: 18),
              label: Text(
                _isLoading ? 'Signing in...' : 'Log In',
                style: const TextStyle(
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
}
