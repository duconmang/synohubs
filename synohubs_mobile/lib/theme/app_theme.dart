import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.surface,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryContainer,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryContainer,
        tertiary: AppColors.tertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.onPrimary,
        onSecondary: AppColors.onSecondary,
        onSurface: AppColors.onSurface,
        onError: AppColors.onError,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: AppColors.onSurface,
        displayColor: AppColors.onSurface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  static TextStyle get headline => GoogleFonts.manrope(
    color: AppColors.onSurface,
    fontWeight: FontWeight.w800,
  );

  static TextStyle get headlineBold => GoogleFonts.manrope(
    color: AppColors.onSurface,
    fontWeight: FontWeight.w700,
  );

  static TextStyle get body => GoogleFonts.inter(color: AppColors.onSurface);

  static TextStyle get label => GoogleFonts.inter(
    color: AppColors.onSurfaceVariant,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 2.0,
  );
}
