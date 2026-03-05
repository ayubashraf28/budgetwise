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
import '../../widgets/common/neo_page_components.dart';

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
  bool _isEmailExpanded = false;
  bool _isEmailLoading = false;
  bool _isGoogleLoading = false;
  bool _isGuestLoading = false;
  String? _errorMessage;
  bool _isCredentialError = false;

  bool get _isBusy => _isEmailLoading || _isGoogleLoading || _isGuestLoading;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isEmailLoading = true;
      _isEmailExpanded = true;
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
    } catch (error, stackTrace) {
      final appError = ErrorMapper.toAppError(
        error,
        stackTrace: stackTrace,
      );
      final technicalMessage = appError.technicalMessage;
      final normalizedMessage = technicalMessage.toLowerCase();
      setState(() {
        _errorMessage = _getErrorMessage(
          technicalMessage,
          fallbackMessage: appError.userMessage,
        );
        _isCredentialError =
            normalizedMessage.contains('invalid login credentials') ||
                normalizedMessage.contains('invalid email or password');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isEmailLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
      _isCredentialError = false;
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
        _isCredentialError = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  Future<void> _handleContinueAsGuest() async {
    setState(() {
      _isGuestLoading = true;
      _errorMessage = null;
      _isCredentialError = false;
    });

    try {
      await ref.read(authNotifierProvider.notifier).signInAnonymously();
    } catch (error, stackTrace) {
      final appError = ErrorMapper.toAppError(
        error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() {
          _errorMessage = appError.userMessage;
          _isCredentialError = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGuestLoading = false;
        });
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    if (!_isEmailExpanded) {
      setState(() {
        _isEmailExpanded = true;
      });
    }

    final emailController = TextEditingController(
      text: _emailController.text.trim(),
    );

    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: NeoTheme.of(dialogContext).surface1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizing.radiusLg),
            side: BorderSide(color: NeoTheme.of(dialogContext).stroke),
          ),
          title: Text(
            'Reset Password',
            style: AppTypography.h3.copyWith(
              color: NeoTheme.of(dialogContext).textPrimary,
            ),
          ),
          content: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'you@example.com',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final email = emailController.text.trim();
                final validationError = EmailValidator.validate(email);
                if (validationError != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(validationError)),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop(email);
              },
              child: const Text('Send link'),
            ),
          ],
        );
      },
    );

    emailController.dispose();
    if (!mounted || email == null || email.isEmpty) return;

    try {
      await ref.read(authNotifierProvider.notifier).resetPassword(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password reset email sent. Check your inbox and return to the app from the email link.',
          ),
        ),
      );
    } catch (error, stackTrace) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ErrorMapper.toUserMessage(error, stackTrace: stackTrace),
          ),
        ),
      );
    }
  }

  String _getErrorMessage(
    String error, {
    String? fallbackMessage,
  }) {
    final errorLower = error.toLowerCase();

    if (errorLower.contains('invalid login credentials') ||
        errorLower.contains('invalid email or password')) {
      return 'The email or password you entered is incorrect. Please check your email address exists and your password is correct.';
    }
    if (errorLower.contains('email not confirmed')) {
      return 'Please verify your email before logging in';
    }
    if (errorLower.contains('user not found')) {
      return 'The email or password you entered is incorrect.';
    }
    if (errorLower.contains('too many requests')) {
      return 'Too many login attempts. Please try again later';
    }
    if (errorLower.contains('network') || errorLower.contains('connection')) {
      return 'Network error. Please check your internet connection';
    }
    if (errorLower.contains('google sign-in is not enabled') ||
        errorLower.contains('provider is not enabled')) {
      return 'Google sign-in is not enabled yet. Please contact support.';
    }
    if (errorLower.contains('google sign-in is only available')) {
      return 'Google sign-in is available on Android and iOS only.';
    }
    if (errorLower.contains('google authentication failed')) {
      return 'Google sign-in failed. Please try again.';
    }
    return fallbackMessage ?? 'Unable to sign in. Please try again';
  }

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);
    final color = palette.accent;

    return Scaffold(
      backgroundColor: palette.appBg,
      body: NeoPageBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(NeoLayout.screenPadding),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildLogoCard(),
                      const SizedBox(height: AppSpacing.xl),
                      if (_errorMessage != null) ...[
                        _buildErrorCard(),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      _buildGuestButton(color),
                      const SizedBox(height: AppSpacing.lg),
                      _buildMethodDivider('OR'),
                      const SizedBox(height: AppSpacing.lg),
                      _buildAuthOptionsCard(color),
                      const SizedBox(height: AppSpacing.lg),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              fontSize: 14,
                              color: palette.textSecondary,
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
        ),
      ),
    );
  }

  Widget _buildLogoCard() {
    final palette = NeoTheme.of(context);

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
                colors: [palette.accentBlue, palette.accentViolet],
              ),
              borderRadius: BorderRadius.circular(AppSizing.radiusMd),
            ),
            child: const Icon(
              LucideIcons.wallet,
              size: 28,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppConstants.appName,
            style: AppTypography.amountMedium.copyWith(
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Plan your finances, track your spending',
            style: TextStyle(
              fontSize: 13,
              color: palette.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    final danger = NeoTheme.negativeValue(context);

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Login Failed',
                    style: TextStyle(
                      color: danger,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: danger.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                  if (_isCredentialError) ...[
                    const SizedBox(height: 2),
                    Text(
                      "If you don't have an account, sign up below.",
                      style: TextStyle(
                        color: danger.withValues(alpha: 0.6),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                LucideIcons.x,
                size: 16,
                color: danger,
              ),
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

  Widget _buildGuestButton(Color color) {
    final palette = NeoTheme.of(context);

    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isBusy ? null : _handleContinueAsGuest,
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.surface1,
          foregroundColor: palette.textPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizing.radiusLg),
            side: BorderSide(color: palette.stroke),
          ),
        ),
        child: _isGuestLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              )
            : const Text(
                'Continue as Guest',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }

  Widget _buildAuthOptionsCard(Color color) {
    final showGoogleButton = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    return NeoGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAuthMethodButton(
                icon: LucideIcons.mail,
                semanticLabel: 'Continue with Email',
                isSelected: _isEmailExpanded,
                isLoading: _isEmailLoading,
                onTap: _isBusy && !_isEmailExpanded
                    ? null
                    : () {
                        setState(() {
                          _isEmailExpanded = !_isEmailExpanded;
                        });
                      },
              ),
              if (showGoogleButton) ...[
                const SizedBox(width: AppSpacing.md),
                _buildAuthMethodButton(
                  semanticLabel: 'Continue with Google',
                  isSelected: false,
                  isLoading: _isGoogleLoading,
                  onTap: _isBusy ? null : _handleGoogleSignIn,
                  child: SvgPicture.asset(
                    'assets/icons/google_g_logo.svg',
                    width: 22,
                    height: 22,
                  ),
                ),
              ],
            ],
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: _buildEmailForm(color),
            ),
            crossFadeState: _isEmailExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: AppConstants.shortAnimation,
            firstCurve: Curves.easeOut,
            secondCurve: Curves.easeOut,
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  Widget _buildAuthMethodButton({
    required String semanticLabel,
    required bool isSelected,
    required bool isLoading,
    required VoidCallback? onTap,
    IconData? icon,
    Widget? child,
  }) {
    final palette = NeoTheme.of(context);
    final accent = palette.accent;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizing.radiusFull),
          child: AnimatedContainer(
            duration: AppConstants.shortAnimation,
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: isSelected
                  ? accent.withValues(alpha: 0.14)
                  : palette.surface2,
              borderRadius: BorderRadius.circular(AppSizing.radiusFull),
              border: Border.all(
                color:
                    isSelected ? accent.withValues(alpha: 0.5) : palette.stroke,
              ),
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: accent,
                      ),
                    )
                  : child ??
                      Icon(
                        icon,
                        size: 22,
                        color: isSelected ? accent : palette.textPrimary,
                      ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm(Color color) {
    final palette = NeoTheme.of(context);
    final isLight = NeoTheme.isLight(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: _isCredentialError
              ? BoxDecoration(
                  border: Border.all(
                    color: NeoTheme.negativeValue(context),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(AppSizing.radiusMd),
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
              color:
                  _isCredentialError ? NeoTheme.negativeValue(context) : color,
            ),
            validator: EmailValidator.validate,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: _isCredentialError
              ? BoxDecoration(
                  border: Border.all(
                    color: NeoTheme.negativeValue(context),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(AppSizing.radiusMd),
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
              color:
                  _isCredentialError ? NeoTheme.negativeValue(context) : color,
            ),
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
            validator: PasswordValidator.validateForSignIn,
            onSubmitted: (_) => _handleLogin(),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _isBusy ? null : _handleForgotPassword,
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
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isBusy ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: isLight ? palette.textPrimary : palette.surface1,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
              ),
            ),
            icon: _isEmailLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isLight ? palette.textPrimary : palette.surface1,
                    ),
                  )
                : const Icon(LucideIcons.logIn, size: 18),
            label: Text(
              _isEmailLoading ? 'Signing in...' : 'Log In',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMethodDivider(String label) {
    final palette = NeoTheme.of(context);

    return Row(
      children: [
        Expanded(
          child: Divider(
            color: palette.stroke,
            height: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: palette.textMuted,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: palette.stroke,
            height: 1,
          ),
        ),
      ],
    );
  }
}
