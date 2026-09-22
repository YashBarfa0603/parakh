import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// PARAKH Design System — Single Source of Truth for all visual tokens.
/// Government of India · Legal Metrology Inspection Platform · SIH 2026
///
/// COLOR RULES:
/// - Do NOT define Color(...) values inside individual screen or widget files.
/// - Reference ParakhColors.* everywhere in the application.
/// - Navy blue (#0D1B3E) is NOT used as a primary background or dominant color.
/// - Purple/violet is NOT used anywhere.
/// - Primary action color is ParakhColors.accent (#2563EB).
class ParakhColors {
  ParakhColors._();

  // Primary Action Color
  /// Primary interactive blue — use for CTAs, selected states, progress, links.
  static const Color accent = Color(0xFF2563EB);
  static const Color accentLight = Color(0xFF3B82F6);

  // Soft Blue Tints (backgrounds only)
  static const Color softBlue = Color(0xFFDBEAFE);      // Strong soft-blue bg
  static const Color veryLightBlue = Color(0xFFEFF6FF);  // Subtlest blue tint

  // Legacy aliases (kept for backward compat — do not use in NEW code)
  /// @deprecated Use [accent] instead.
  static const Color primary = Color(0xFF2563EB);
  /// @deprecated Use [accent] instead.
  static const Color primaryNavy = Color(0xFF0D1B3E);
  /// @deprecated Use [accent] instead.
  static const Color primaryLight = Color(0xFF1A2D5A);
  /// @deprecated Use [accent] instead.
  static const Color primaryDark = Color(0xFF080F24);
  /// @deprecated Use [accent] instead.
  static const Color secondaryNavy = Color(0xFF1A2D5A);

  // Accent Gold (for Ashoka emblem tint if needed)
  static const Color accentGold = Color(0xFFD97706);

  // Backgrounds
  /// App scaffold background — very light cool gray.
  static const Color background = Color(0xFFF8FAFC);
  static const Color backgroundDarker = Color(0xFFF1F5F9);

  // Surfaces
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF1F5F9);
  static const Color sectionBackground = Color(0xFFEFF6FF);

  // Status Colors
  static const Color compliant = Color(0xFF16A34A);
  static const Color compliantLight = Color(0xFFDCFCE7);
  static const Color nonCompliant = Color(0xFFDC2626);
  static const Color nonCompliantLight = Color(0xFFFEE2E2);
  static const Color needsReview = Color(0xFFF59E0B);
  static const Color needsReviewLight = Color(0xFFFEF3C7);
  static const Color pending = Color(0xFF6B7280);
  static const Color pendingLight = Color(0xFFF3F4F6);

  // Text
  static const Color textPrimary = Color(0xFF172554);    // Dark blue-gray
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // Borders
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);

  // Misc
  static const Color divider = Color(0xFFE2E8F0);
  static const Color shadow = Color(0x0A000000);
  static const Color error = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);

  // Camera / Dark Surface
  /// Only for camera viewfinder background — intentionally dark.
  static const Color cameraDark = Color(0xFF0F172A);
  static const Color cameraOverlay = Color(0x8C000000);
}

class ParakhSpacing {
  ParakhSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double section = 40.0;
}

class ParakhRadius {
  ParakhRadius._();

  static const double xs = 4.0;
  static const double sm = 6.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double card = 14.0;
  static const double button = 12.0;
  static const double input = 12.0;
  static const double full = 999.0;
}

class ParakhTypography {
  ParakhTypography._();

  static const TextStyle heading1 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: ParakhColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: ParakhColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: ParakhColors.textPrimary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: ParakhColors.textPrimary,
  );

  static const TextStyle body1 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: ParakhColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle body2 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: ParakhColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: ParakhColors.textSecondary,
    height: 1.3,
  );

  static const TextStyle label = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: ParakhColors.textTertiary,
    letterSpacing: 0.5,
  );
}

class ParakhTheme {
  ParakhTheme._();

  static TextTheme _buildTextTheme() {
    return GoogleFonts.interTextTheme(
      const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: ParakhColors.textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: ParakhColors.textPrimary,
          letterSpacing: -0.5,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: ParakhColors.textPrimary,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: ParakhColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: ParakhColors.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: ParakhColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: ParakhColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: ParakhColors.textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: ParakhColors.textSecondary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: ParakhColors.textPrimary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: ParakhColors.textPrimary,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: ParakhColors.textSecondary,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: ParakhColors.textPrimary,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: ParakhColors.textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: ParakhColors.textTertiary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    final textTheme = _buildTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      textTheme: textTheme,

      colorScheme: const ColorScheme.light(
        primary: ParakhColors.accent,
        onPrimary: ParakhColors.textOnPrimary,
        secondary: ParakhColors.accentLight,
        onSecondary: ParakhColors.textOnPrimary,
        surface: ParakhColors.surface,
        onSurface: ParakhColors.textPrimary,
        error: ParakhColors.error,
        onError: ParakhColors.textOnPrimary,
      ),

      scaffoldBackgroundColor: ParakhColors.background,

      // AppBar — always white, clean
      appBarTheme: AppBarTheme(
        backgroundColor: ParakhColors.surface,
        foregroundColor: ParakhColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: ParakhColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(
          color: ParakhColors.textPrimary,
          size: 22,
        ),
      ),

      // Card — white surface, thin border, no elevation
      cardTheme: CardThemeData(
        color: ParakhColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ParakhRadius.card),
          side: const BorderSide(color: ParakhColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated Button — primary action blue
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ParakhColors.accent,
          foregroundColor: ParakhColors.textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: ParakhSpacing.xxl,
            vertical: ParakhSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ParakhRadius.button),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          minimumSize: const Size(0, 52),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ParakhColors.accent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: ParakhSpacing.xxl,
            vertical: ParakhSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ParakhRadius.button),
          ),
          side: const BorderSide(color: ParakhColors.border),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          minimumSize: const Size(0, 52),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ParakhColors.accent,
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: ParakhSpacing.lg,
            vertical: ParakhSpacing.sm,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ParakhColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ParakhSpacing.lg,
          vertical: ParakhSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ParakhRadius.input),
          borderSide: const BorderSide(color: ParakhColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ParakhRadius.input),
          borderSide: const BorderSide(color: ParakhColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ParakhRadius.input),
          borderSide: const BorderSide(color: ParakhColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ParakhRadius.input),
          borderSide: const BorderSide(color: ParakhColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ParakhRadius.input),
          borderSide: const BorderSide(color: ParakhColors.error, width: 1.5),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: ParakhColors.textTertiary),
        labelStyle: textTheme.bodyMedium?.copyWith(color: ParakhColors.textSecondary),
        prefixIconColor: ParakhColors.textTertiary,
        suffixIconColor: ParakhColors.textTertiary,
      ),

      // Bottom Navigation Bar (conventional — overridden by floating pill nav)
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: ParakhColors.surface,
        selectedItemColor: ParakhColors.accent,
        unselectedItemColor: ParakhColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: ParakhColors.accent,
        ),
        unselectedLabelStyle: textTheme.labelSmall,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: ParakhColors.divider,
        thickness: 1,
        space: 1,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: ParakhColors.surfaceLight,
        selectedColor: ParakhColors.accent,
        labelStyle: textTheme.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ParakhRadius.sm),
          side: const BorderSide(color: ParakhColors.border),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: ParakhSpacing.md,
          vertical: ParakhSpacing.xs,
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: ParakhColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ParakhRadius.xl),
        ),
        titleTextStyle: textTheme.headlineSmall,
        elevation: 0,
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: ParakhColors.accent,
        foregroundColor: ParakhColors.textOnPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ParakhRadius.xl),
        ),
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ParakhColors.accent,
        linearTrackColor: ParakhColors.softBlue,
        circularTrackColor: ParakhColors.softBlue,
      ),

      // Snack Bar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ParakhColors.textPrimary,
        contentTextStyle: textTheme.bodySmall?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ParakhRadius.lg),
        ),
      ),
    );
  }
}
