import 'package:flutter/material.dart';

/// App color palette - Dark theme focused
class AppColors {
  AppColors._();

  // Base colors
  static const Color background = Color(0xFF0E0E0E);
  static const Color surface = Color(0xFF171A20);
  static const Color surfaceLight = Color(0xFF1D2128);
  static const Color border = Color(0xFF2B313B);

  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF); // White
  static const Color textSecondary = Color(0xFFA8B0BF);
  static const Color textMuted = Color(0xFF737C8D);

  // Brand colors
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryLight = Color(0xFF818CF8); // Indigo 400
  static const Color primaryDark = Color(0xFF4F46E5); // Indigo 600

  // Semantic colors
  static const Color success = Color(0xFF22C55E); // Green
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // Red
  static const Color info = Color(0xFF3B82F6); // Blue

  // Budget-specific colors
  static const Color income = Color(0xFF22C55E); // Green
  static const Color expense = Color(0xFFEF4444); // Red
  static const Color savings = Color(0xFF14B8A6); // Teal
  static const Color tealDark = Color(0xFF0D9488); // Teal 600
  static const Color overBudget = Color(0xFFEF4444);
  static const Color underBudget = Color(0xFF22C55E);
  static const Color onBudget = Color(0xFF3B82F6);

  // Category colors
  static const List<Color> categoryColors = [
    Color(0xFF3B82F6), // Blue
    Color(0xFFF97316), // Orange
    Color(0xFF22C55E), // Green
    Color(0xFFA855F7), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFFEAB308), // Yellow
    Color(0xFF14B8A6), // Teal
    Color(0xFFEF4444), // Red
    Color(0xFF6366F1), // Indigo
    Color(0xFF84CC16), // Lime
  ];

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  );

  static const LinearGradient tealGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF22C55E), Color(0xFF10B981)],
  );

  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF4444), Color(0xFFF43F5E)],
  );
}

/// App typography styles
class AppTypography {
  AppTypography._();

  // Headings
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // Body text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.5,
  );

  // Labels
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // Numbers (for amounts)
  static const TextStyle amountLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle amountMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle amountSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
}

/// App spacing values
class AppSpacing {
  AppSpacing._();

  // Base spacing unit: 4px
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // Screen padding
  static const EdgeInsets screenPadding = EdgeInsets.all(16);
  static const EdgeInsets screenPaddingHorizontal =
      EdgeInsets.symmetric(horizontal: 16);

  // Card padding
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(12);
}

/// App sizing values
class AppSizing {
  AppSizing._();

  // Border radius
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 9999;

  // Icon sizes
  static const double iconXs = 14;
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double iconXl = 32;

  // Button heights
  static const double buttonHeight = 56;
  static const double buttonHeightCompact = 44;

  // Bottom nav
  static const double bottomNavHeight = 80;

  // FAB
  static const double fabSize = 56;
}

@immutable
class NeoPalette {
  final Color appBg;
  final Color surface1;
  final Color surface2;
  final Color stroke;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color iconPrimary;
  final Color iconSecondary;
  final Color accent;
  final Color accentViolet;
  final Color accentBlue;
  final Color balanceCardStart;
  final Color balanceCardEnd;
  final Color expenseCardStart;
  final Color expenseCardEnd;
  final Color incomeCardStart;
  final Color incomeCardEnd;

  const NeoPalette({
    required this.appBg,
    required this.surface1,
    required this.surface2,
    required this.stroke,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.iconPrimary,
    required this.iconSecondary,
    required this.accent,
    required this.accentViolet,
    required this.accentBlue,
    required this.balanceCardStart,
    required this.balanceCardEnd,
    required this.expenseCardStart,
    required this.expenseCardEnd,
    required this.incomeCardStart,
    required this.incomeCardEnd,
  });
}

class NeoTheme {
  NeoTheme._();

  static final NeoPalette dark = NeoPalette(
    appBg: const HSLColor.fromAHSL(1, 0, 0, 0.055).toColor(),
    surface1: const HSLColor.fromAHSL(1, 220, 0.164, 0.108).toColor(),
    surface2: const HSLColor.fromAHSL(1, 218.2, 0.159, 0.135).toColor(),
    stroke: const HSLColor.fromAHSL(1, 217.5, 0.157, 0.200).toColor(),
    textPrimary: const HSLColor.fromAHSL(1, 217.5, 0.500, 0.969).toColor(),
    textSecondary: const HSLColor.fromAHSL(1, 219.1, 0.152, 0.704).toColor(),
    textMuted: const HSLColor.fromAHSL(1, 219.2, 0.102, 0.502).toColor(),
    iconPrimary: const HSLColor.fromAHSL(1, 217.5, 0.500, 0.969).toColor(),
    iconSecondary: const HSLColor.fromAHSL(1, 219.1, 0.152, 0.704).toColor(),
    accent: const HSLColor.fromAHSL(1, 69.7, 0.850, 0.686).toColor(),
    accentViolet: const HSLColor.fromAHSL(1, 263.5, 1.000, 0.775).toColor(),
    accentBlue: const HSLColor.fromAHSL(1, 223.6, 1.000, 0.763).toColor(),
    balanceCardStart: const HSLColor.fromAHSL(1, 189.3, 0.630, 0.180).toColor(),
    balanceCardEnd: const HSLColor.fromAHSL(1, 182.7, 0.556, 0.159).toColor(),
    expenseCardStart: const HSLColor.fromAHSL(1, 341.1, 0.432, 0.159).toColor(),
    expenseCardEnd: const HSLColor.fromAHSL(1, 333.6, 0.352, 0.139).toColor(),
    incomeCardStart: const HSLColor.fromAHSL(1, 164.7, 0.595, 0.155).toColor(),
    incomeCardEnd: const HSLColor.fromAHSL(1, 164.7, 0.558, 0.151).toColor(),
  );

  static final NeoPalette light = NeoPalette(
    appBg: const HSLColor.fromAHSL(1, 220, 0.18, 0.96).toColor(),
    surface1: const HSLColor.fromAHSL(1, 220, 0.22, 0.99).toColor(),
    surface2: const HSLColor.fromAHSL(1, 220, 0.18, 0.95).toColor(),
    stroke: const HSLColor.fromAHSL(1, 220, 0.18, 0.86).toColor(),
    textPrimary: const HSLColor.fromAHSL(1, 220, 0.28, 0.14).toColor(),
    textSecondary: const HSLColor.fromAHSL(1, 220, 0.14, 0.40).toColor(),
    textMuted: const HSLColor.fromAHSL(1, 220, 0.14, 0.52).toColor(),
    iconPrimary: const HSLColor.fromAHSL(1, 220, 0.28, 0.14).toColor(),
    iconSecondary: const HSLColor.fromAHSL(1, 220, 0.14, 0.40).toColor(),
    accent: const HSLColor.fromAHSL(1, 74, 0.52, 0.36).toColor(),
    accentViolet: const HSLColor.fromAHSL(1, 264.2, 0.633, 0.647).toColor(),
    accentBlue: const HSLColor.fromAHSL(1, 222.6, 0.734, 0.631).toColor(),
    balanceCardStart: const HSLColor.fromAHSL(1, 196, 0.66, 0.84).toColor(),
    balanceCardEnd: const HSLColor.fromAHSL(1, 196, 0.58, 0.78).toColor(),
    expenseCardStart: const HSLColor.fromAHSL(1, 351, 0.65, 0.86).toColor(),
    expenseCardEnd: const HSLColor.fromAHSL(1, 351, 0.56, 0.79).toColor(),
    incomeCardStart: const HSLColor.fromAHSL(1, 152, 0.56, 0.84).toColor(),
    incomeCardEnd: const HSLColor.fromAHSL(1, 152, 0.48, 0.77).toColor(),
  );

  static bool isLight(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light;

  static NeoPalette of(BuildContext context) => isLight(context) ? light : dark;

  static Color positiveValue(BuildContext context) => isLight(context)
      ? const HSLColor.fromAHSL(1, 94.3, 0.461, 0.327).toColor()
      : const HSLColor.fromAHSL(1, 96.5, 0.723, 0.675).toColor();

  static Color negativeValue(BuildContext context) => isLight(context)
      ? const HSLColor.fromAHSL(1, 349.3, 0.488, 0.525).toColor()
      : const HSLColor.fromAHSL(1, 0, 1.0, 0.739).toColor();

  static Color warningValue(BuildContext context) => isLight(context)
      ? const HSLColor.fromAHSL(1, 36.2, 0.608, 0.480).toColor()
      : const HSLColor.fromAHSL(1, 37.0, 1.0, 0.704).toColor();

  static Color infoValue(BuildContext context) => isLight(context)
      ? const HSLColor.fromAHSL(1, 202.4, 0.593, 0.433).toColor()
      : const HSLColor.fromAHSL(1, 202.1, 1.0, 0.708).toColor();

  static Color controlIdleBackground(BuildContext context) =>
      of(context).surface2;

  static Color controlIdleForeground(BuildContext context) =>
      of(context).textSecondary;

  static Color controlIdleBorder(BuildContext context) =>
      of(context).stroke.withValues(alpha: 0.9);

  static Color controlSelectedBackground(BuildContext context) =>
      of(context).accent.withValues(alpha: isLight(context) ? 0.18 : 0.15);

  static Color controlSelectedForeground(BuildContext context) =>
      of(context).accent.withValues(alpha: 0.95);

  static Color controlSelectedBorder(BuildContext context) =>
      controlSelectedForeground(context)
          .withValues(alpha: isLight(context) ? 0.55 : 0.42);
}

class NeoTypography {
  NeoTypography._();

  static TextStyle pageTitle(BuildContext context) => AppTypography.h2.copyWith(
        color: NeoTheme.of(context).textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.15,
      );

  static TextStyle pageContext(BuildContext context) =>
      AppTypography.bodySmall.copyWith(
        color: NeoTheme.of(context).textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.1,
      );

  static TextStyle sectionTitle(BuildContext context) =>
      AppTypography.h3.copyWith(
        color: NeoTheme.of(context).textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.2,
      );

  static TextStyle sectionAction(BuildContext context) =>
      AppTypography.labelMedium.copyWith(
        color: NeoTheme.of(context).accent,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.1,
      );

  static TextStyle cardTitle(BuildContext context) =>
      AppTypography.labelLarge.copyWith(
        color: NeoTheme.of(context).textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.12,
      );

  static TextStyle chipLabel(
    BuildContext context, {
    required bool isSelected,
  }) {
    final palette = NeoTheme.of(context);
    return AppTypography.labelMedium.copyWith(
      color: isSelected ? palette.iconPrimary : palette.textSecondary,
      fontSize: 12,
      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
      height: 1.0,
    );
  }

  static TextStyle rowTitle(BuildContext context) =>
      AppTypography.bodyLarge.copyWith(
        color: NeoTheme.of(context).textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 16,
        height: 1.2,
      );

  static TextStyle rowSecondary(BuildContext context) =>
      AppTypography.bodySmall.copyWith(
        color: NeoTheme.of(context).textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.2,
      );

  static TextStyle rowAmount(BuildContext context, Color color) =>
      AppTypography.amountSmall.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
        fontSize: 16,
        height: 1.1,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}

class NeoIconSizes {
  NeoIconSizes._();

  static const double xxs = 10;
  static const double xs = 11;
  static const double sm = 14;
  static const double md = 16;
  static const double lg = 18;
  static const double xl = 20;
  static const double xxl = AppSizing.iconLg;
}

class NeoControlSizing {
  NeoControlSizing._();

  static const double radius = 20;
  static const double minHeight = 44;
  static const double minWidth = 64;
  static const double compactActionSize = 34;
  static const double compactActionIconSize = NeoIconSizes.md;
}

class NeoLayout {
  NeoLayout._();

  static const double screenPadding = AppSpacing.md;
  static const double sectionGap = 12;
  static const double cardRadius = AppSizing.radiusLg;
  static const double bottomNavSafeBuffer = 92;
}

/// App theme configuration
class AppTheme {
  AppTheme._();

  static final Color _lightBackground =
      const HSLColor.fromAHSL(1, 220.0, 0.176, 0.967).toColor();
  static final Color _lightSurface =
      const HSLColor.fromAHSL(1, 0, 0, 1.0).toColor();
  static final Color _lightSurfaceAlt =
      const HSLColor.fromAHSL(1, 220.0, 0.250, 0.953).toColor();
  static final Color _lightBorder =
      const HSLColor.fromAHSL(1, 218.6, 0.212, 0.871).toColor();
  static final Color _lightTextPrimary =
      const HSLColor.fromAHSL(1, 218.8, 0.288, 0.116).toColor();
  static final Color _lightTextSecondary =
      const HSLColor.fromAHSL(1, 219.1, 0.109, 0.414).toColor();
  static final Color _lightTextMuted =
      const HSLColor.fromAHSL(1, 218.6, 0.132, 0.584).toColor();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,

      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: AppColors.surface,
        error: AppColors.error,
      ),

      // App bar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.h3,
      ),

      // Bottom navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Cards
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),

      // Elevated button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      // Text button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTypography.labelLarge,
        ),
      ),

      // Bottom sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppSizing.radiusXl)),
        ),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        contentTextStyle:
            AppTypography.bodyMedium.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizing.radiusSm),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Floating action button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),

      // Text theme
      textTheme: const TextTheme(
        displayLarge: AppTypography.h1,
        displayMedium: AppTypography.h2,
        displaySmall: AppTypography.h3,
        headlineMedium: AppTypography.h3,
        headlineSmall: AppTypography.labelLarge,
        titleLarge: AppTypography.labelLarge,
        titleMedium: AppTypography.bodyLarge,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.labelMedium,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _lightBackground,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: _lightSurface,
        error: AppColors.error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _lightBackground,
        foregroundColor: _lightTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _lightTextPrimary,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _lightSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: _lightTextMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: _lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
          side: BorderSide(color: _lightBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: _lightTextMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: _lightSurface,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppSizing.radiusXl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _lightSurface,
        contentTextStyle: TextStyle(
          fontSize: 14,
          color: _lightTextPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizing.radiusSm),
          side: BorderSide(color: _lightBorder),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      dividerTheme: DividerThemeData(
        color: _lightBorder,
        thickness: 1,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: _lightTextPrimary,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: _lightTextPrimary,
          height: 1.3,
        ),
        displaySmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _lightTextPrimary,
          height: 1.4,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _lightTextPrimary,
          height: 1.4,
        ),
        headlineSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _lightTextPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _lightTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: _lightTextPrimary,
          height: 1.5,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: _lightTextPrimary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: _lightTextSecondary,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: _lightTextMuted,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _lightTextPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _lightTextSecondary,
        ),
      ),
    );
  }

  // Legacy color accessors for existing code
  static const Color primaryColor = AppColors.primary;
  static const Color primaryLight = AppColors.primaryLight;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color successColor = AppColors.success;
  static const Color warningColor = AppColors.warning;
  static const Color errorColor = AppColors.error;
  static const Color infoColor = AppColors.info;
  static const Color backgroundColor = AppColors.background;
  static const Color surfaceColor = AppColors.surface;
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;
  static const Color textHint = AppColors.textMuted;
  static const Color borderColor = AppColors.border;
  static const Color incomeColor = AppColors.income;
  static const Color expenseColor = AppColors.expense;
  static const Color savingsColor = AppColors.savings;
  static const Color overBudgetColor = AppColors.overBudget;
  static const Color underBudgetColor = AppColors.underBudget;
  static const Color onBudgetColor = AppColors.onBudget;
}
