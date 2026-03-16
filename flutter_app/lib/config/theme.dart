import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// «Зачарованная ночь» — dark fairy-tale design system.
class AppTheme {
  // ── Brand Colors ──────────────────────────────────────────────────────
  static const Color primaryColor = Color(0xFF6366F1); // Indigo 500
  static const Color primaryLight = Color(0xFFA5B4FC); // Indigo 300
  static const Color primaryDark = Color(0xFF4338CA); // Indigo 700

  static const Color secondaryColor = Color(0xFFFB7185); // Rose 400
  static const Color secondaryLight = Color(0xFFFECDD3);

  static const Color accentColor = Color(0xFFFBBF24); // Amber 400
  static const Color accentLight = Color(0xFFFDE68A);

  // ── Enchanted Night — new accent colors ─────────────────────────────
  static const Color accentGold = Color(0xFFFFD700);
  static const Color accentPurple = Color(0xFFA78BFA);

  // ── Background & Surface ──────────────────────────────────────────────
  static const Color backgroundColor = Color(0xFF0C0A1D); // Deep midnight
  static const Color surfaceColor = Color(0xFF12102B); // Slightly lighter
  static const Color cardColor = Color(0xFF161430); // Card background

  // ── Glass-morphism ────────────────────────────────────────────────────
  static const Color glassColor = Color(0x0FFFFFFF); // rgba(255,255,255,0.06)
  static const Color glassBorder = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const Color glassLight = Color(0x1AFFFFFF); // rgba(255,255,255,0.10)

  // ── Text Colors ───────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFE8E5F0); // Soft lavender white
  static const Color textSecondary = Color(0xFF9B95B0); // Muted lavender
  static const Color textLight = Color(0xFF6B6580); // Dim lavender

  // ── Status Colors ─────────────────────────────────────────────────────
  static const Color successColor = Color(0xFF34D399);
  static const Color errorColor = Color(0xFFF87171);
  static const Color warningColor = Color(0xFFFBBF24);
  static const Color infoColor = Color(0xFF38BDF8);

  // ── Neutral borders / fills ───────────────────────────────────────────
  static const Color borderColor = Color(0x14FFFFFF); // Same as glassBorder
  static const Color fillColor = Color(0x0FFFFFFF); // Same as glassColor

  // ── Spacing ───────────────────────────────────────────────────────────
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // ── Border Radius ─────────────────────────────────────────────────────
  static const double radiusSm = 10.0;
  static const double radiusMd = 14.0;
  static const double radiusLg = 20.0;
  static const double radiusXl = 28.0;
  static const double radiusFull = 999.0;

  // ── Gradients ─────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFFFB7185), Color(0xFFF472B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Background gradient — deep midnight blue with subtle variation.
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0C0A1D), Color(0xFF12102B), Color(0xFF0C0A1D)],
  );

  /// Glass card gradient — subtle shimmer on glass surfaces.
  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x0AFFFFFF), Color(0x05FFFFFF)],
  );

  // ── Shadows ───────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: primaryColor.withValues(alpha: 0.05),
          blurRadius: 40,
        ),
      ];

  static List<BoxShadow> get cardShadowHover => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 28,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: primaryColor.withValues(alpha: 0.1),
          blurRadius: 40,
        ),
      ];

  /// Glow effect for primary-colored interactive elements.
  static List<BoxShadow> get primaryGlow => [
        BoxShadow(
          color: primaryColor.withValues(alpha: 0.4),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ];

  /// Glow effect for gold accent elements.
  static List<BoxShadow> get accentGlow => [
        BoxShadow(
          color: accentGold.withValues(alpha: 0.3),
          blurRadius: 16,
          spreadRadius: 1,
        ),
      ];

  // ── Typography helpers ────────────────────────────────────────────────
  static TextStyle heading({
    double size = 28,
    FontWeight weight = FontWeight.w700,
    Color color = textPrimary,
  }) =>
      GoogleFonts.comfortaa(
        fontSize: size,
        fontWeight: weight,
        color: color,
      );

  static TextStyle body({
    double size = 15,
    FontWeight weight = FontWeight.w400,
    Color color = textPrimary,
  }) =>
      GoogleFonts.nunitoSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
      );

  // ── Theme Data ────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.nunitoSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),

      // Scaffold
      scaffoldBackgroundColor: backgroundColor,

      // AppBar
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        titleTextStyle: GoogleFonts.comfortaa(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),

      // Text
      textTheme: baseTextTheme.copyWith(
        headlineLarge: GoogleFonts.comfortaa(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.comfortaa(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineSmall: GoogleFonts.comfortaa(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.comfortaa(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.nunitoSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleSmall: GoogleFonts.nunitoSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.nunitoSans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.nunitoSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        bodySmall: GoogleFonts.nunitoSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textLight,
        ),
        labelLarge: GoogleFonts.nunitoSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.nunitoSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          side: const BorderSide(color: glassBorder, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.nunitoSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLight,
          textStyle: GoogleFonts.nunitoSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glassColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        hintStyle: GoogleFonts.nunitoSans(
          fontSize: 14,
          color: textLight,
        ),
        labelStyle: GoogleFonts.nunitoSans(
          fontSize: 14,
          color: textSecondary,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: glassBorder),
        ),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundColor,
        selectedItemColor: primaryLight,
        unselectedItemColor: textLight,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: const Color(0xFF2A2545),
        thumbColor: primaryColor,
        overlayColor: primaryColor.withValues(alpha: 0.15),
        valueIndicatorColor: primaryColor,
        trackHeight: 8,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
        valueIndicatorTextStyle: GoogleFonts.nunitoSans(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: glassColor,
        selectedColor: primaryColor.withValues(alpha: 0.25),
        checkmarkColor: primaryLight,
        labelStyle: GoogleFonts.nunitoSans(fontSize: 13, color: textPrimary),
        side: const BorderSide(color: glassBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),

      // FAB
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1A1735),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: glassBorder),
        ),
      ),

      // Snack Bar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1A1735),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: glassBorder,
        thickness: 1,
        space: 1,
      ),

      // PopupMenu
      popupMenuTheme: PopupMenuThemeData(
        color: const Color(0xFF1A1735),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: glassBorder),
        ),
      ),

      // BottomSheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1A1735),
        modalBackgroundColor: Color(0xFF1A1735),
      ),
    );
  }
}
