import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(AppConstants.backgroundPrimary),
      colorScheme: const ColorScheme.dark(
        surface: Color(AppConstants.backgroundSecondary),
        primary: Color(AppConstants.primaryAccent),
        secondary: Color(AppConstants.successColor),
        error: Color(AppConstants.errorColor),
        onSurface: Colors.white,
        onPrimary: Color(AppConstants.backgroundPrimary),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.orbitron(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: const Color(AppConstants.primaryAccent),
          letterSpacing: 2,
        ),
        displayMedium: GoogleFonts.orbitron(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.5,
        ),
        displaySmall: GoogleFonts.orbitron(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        headlineLarge: GoogleFonts.orbitron(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        headlineMedium: GoogleFonts.orbitron(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        headlineSmall: GoogleFonts.orbitron(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: Colors.white),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
        bodySmall: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(AppConstants.primaryAccent),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(AppConstants.backgroundSecondary).withOpacity(0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(AppConstants.primaryAccent), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: const Color(AppConstants.primaryAccent).withOpacity(0.3), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(AppConstants.primaryAccent), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(AppConstants.errorColor), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(AppConstants.errorColor), width: 2),
        ),
        labelStyle: GoogleFonts.inter(color: Colors.white54),
        hintStyle: GoogleFonts.inter(color: Colors.white38),
        prefixIconColor: const Color(AppConstants.primaryAccent),
        suffixIconColor: Colors.white54,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(AppConstants.backgroundPrimary),
        elevation: 0,
        titleTextStyle: GoogleFonts.orbitron(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: const Color(AppConstants.primaryAccent),
        ),
        iconTheme: const IconThemeData(color: Color(AppConstants.primaryAccent)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(AppConstants.backgroundSecondary),
        selectedItemColor: Color(AppConstants.primaryAccent),
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(AppConstants.backgroundSecondary),
        selectedColor: const Color(AppConstants.primaryAccent).withOpacity(0.2),
        labelStyle: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
        side: BorderSide(color: const Color(AppConstants.primaryAccent).withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      cardTheme: CardThemeData(
        color: const Color(AppConstants.cardColor),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: const Color(AppConstants.primaryAccent).withOpacity(0.1)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(AppConstants.backgroundSecondary),
        contentTextStyle: GoogleFonts.inter(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
