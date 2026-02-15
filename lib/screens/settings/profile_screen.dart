import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../utils/validators/input_validator.dart';
import '../../widgets/common/neo_page_components.dart';
import 'currency_picker_sheet.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _nameController;
  bool _isLoading = false;
  bool _hasChanges = false;

  NeoPalette get _palette => NeoTheme.of(context);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(userProfileProvider).valueOrNull;
      _nameController.text = profile?.displayName ?? '';
      _nameController.addListener(_onNameChanged);
    });
  }

  void _onNameChanged() {
    final profile = ref.read(userProfileProvider).valueOrNull;
    final originalName = profile?.displayName ?? '';
    setState(() {
      _hasChanges = _nameController.text.trim() != originalName;
    });
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    final profile = ref.watch(userProfileProvider);
    final currentCurrency = ref.watch(currencyProvider);
    final currentSymbol = ref.watch(currencySymbolProvider);

    final displayName = profile.valueOrNull?.displayName ?? '';
    final email = user?.email ?? 'Not signed in';
    final memberSince = profile.valueOrNull?.createdAt;

    return Scaffold(
      backgroundColor: _palette.appBg,
      body: NeoPageBackground(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            NeoLayout.screenPadding,
            0,
            NeoLayout.screenPadding,
            AppSpacing.xl +
                MediaQuery.paddingOf(context).bottom +
                NeoLayout.bottomNavSafeBuffer,
          ),
          children: [
            const SizedBox(height: AppSpacing.sm),
            const NeoPageHeader(
              title: 'Profile',
              subtitle: 'Identity, account info, and personal settings',
            ),
            const SizedBox(height: NeoLayout.sectionGap),
            Center(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Photo upload coming soon')),
                  );
                },
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: _palette.accent.withValues(alpha: 0.18),
                      child: Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : 'U',
                        style: AppTypography.h1.copyWith(
                          color: _palette.accent,
                          fontSize: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Tap to change',
                      style: NeoTypography.rowSecondary(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: NeoLayout.sectionGap),
            _buildSectionHeader('Personal Info'),
            const SizedBox(height: AppSpacing.sm),
            NeoGlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.user,
                          size: NeoIconSizes.xl,
                          color: _palette.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: TextFormField(
                            controller: _nameController,
                            maxLength: InputValidator.maxDisplayNameLength,
                            style: AppTypography.bodyLarge.copyWith(
                              color: _palette.textPrimary,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Display Name',
                              labelStyle: TextStyle(color: _palette.textMuted),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                      height: 1,
                      color: _palette.stroke.withValues(alpha: 0.85)),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.mail,
                          size: NeoIconSizes.xl,
                          color: _palette.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email',
                                style: NeoTypography.rowSecondary(context),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                email,
                                style: NeoTypography.rowTitle(context),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          LucideIcons.lock,
                          size: NeoIconSizes.sm,
                          color: _palette.textMuted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: NeoLayout.sectionGap),
            _buildSectionHeader('Account'),
            const SizedBox(height: AppSpacing.sm),
            NeoGlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.calendarDays,
                          size: NeoIconSizes.xl,
                          color: _palette.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'Member since',
                            style: NeoTypography.rowTitle(context),
                          ),
                        ),
                        Text(
                          memberSince != null
                              ? DateFormat('MMMM yyyy').format(memberSince)
                              : '-',
                          style: NeoTypography.rowSecondary(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Divider(
                      height: 1,
                      color: _palette.stroke.withValues(alpha: 0.85)),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const CurrencyPickerSheet(),
                        );
                      },
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(AppSizing.radiusLg),
                        bottomRight: Radius.circular(AppSizing.radiusLg),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.poundSterling,
                              size: NeoIconSizes.xl,
                              color: _palette.textSecondary,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                'Currency',
                                style: NeoTypography.rowTitle(context),
                              ),
                            ),
                            Text(
                              '$currentSymbol $currentCurrency',
                              style: NeoTypography.rowSecondary(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Icon(
                              LucideIcons.chevronRight,
                              size: NeoIconSizes.lg,
                              color: _palette.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: NeoLayout.sectionGap),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _hasChanges && !_isLoading ? _saveProfile : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _palette.accent,
                  disabledBackgroundColor:
                      _palette.accent.withValues(alpha: 0.3),
                  foregroundColor: NeoTheme.isLight(context)
                      ? _palette.textPrimary
                      : _palette.surface1,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: NeoTypography.sectionAction(context).copyWith(
        color: _palette.textMuted,
      ),
    );
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final nameError = InputValidator.validateBoundedName(
      name,
      fieldName: 'Display name',
      maxLength: InputValidator.maxDisplayNameLength,
      minLength: 1,
    );
    if (nameError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(nameError)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(profileNotifierProvider.notifier).updateProfile(
            displayName: name,
          );
      ref.invalidate(userProfileProvider);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasChanges = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: NeoTheme.negativeValue(context),
          ),
        );
      }
    }
  }
}
