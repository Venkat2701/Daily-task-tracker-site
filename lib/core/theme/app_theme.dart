import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand Colors ──────────────────────────────────────────
  static const Color navy = Color(0xFF09131E);
  static const Color navyLight = Color(0xFF0E2238);
  static const Color sidebarHover = Color(0xFF152538);
  static const Color sidebarActive = Color(0xFF1D334D);
  static const Color primary = Color(0xFF2D6CD8);
  static const Color primaryLight = Color(0xFF4F8CF6);
  static const Color primaryBg = Color(0xFFEEF3FC);

  // ── Quadrant Colors ───────────────────────────────────────
  static const Color doFirst = Color(0xFFD43F3F);
  static const Color schedule = Color(0xFF2563EB);
  static const Color delegate = Color(0xFFD97706);
  static const Color drop = Color(0xFF64748B);

  static const Color doFirstBg = Color(0xFFFEF2F2);
  static const Color scheduleBg = Color(0xFFEFF6FF);
  static const Color delegateBg = Color(0xFFFFFBEB);
  static const Color dropBg = Color(0xFFF8FAFC);

  // ── Neutrals ──────────────────────────────────────────────
  static const Color paper = Color(0xFFF4F6FA);
  static const Color card = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF1B2838);
  static const Color inkSoft = Color(0xFF637381);
  static const Color line = Color(0xFFE6EBF1);

  // ── Semantic ───────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // ── Radii ─────────────────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        surface: paper,
        onSurface: ink,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: paper,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: navy,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: navy,
        ),
        displaySmall: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: navy,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: navy,
        ),
        headlineSmall: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: navy,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: ink,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: ink,
        ),
        bodySmall: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: inkSoft,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: line),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: const BorderSide(color: line),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(color: inkSoft, fontSize: 14),
      ),
      dividerColor: line,
      dividerTheme: const DividerThemeData(color: line, thickness: 1),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
