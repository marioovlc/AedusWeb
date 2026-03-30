import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Aedus Premium Dark Palette
  static const Color background = Color(0xFF060D1C);
  static const Color surface = Color(0xFF0D1629);
  static const Color cards = Color(0xFF111F36);
  static const Color borders = Color(0xFF1C2D47);
  
  static const Color primaryBlue = Color(0xFF4F8EF7);
  static const Color secondaryIndigo = Color(0xFF818CF8);
  static const Color textHighPriority = Color(0xFFF1F5F9);
  static const Color textLowPriority = Color(0xFF64748B);
  
  static const Color success = Color(0xFF059669);
  static const Color danger = Color(0xFFDC2626);
  static const Color gold = Color(0xFFFCD34D);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primaryBlue,
      
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: secondaryIndigo,
        surface: surface,
        onSurface: textHighPriority,
        error: danger,
        outline: borders,
      ),

      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: textHighPriority,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textHighPriority,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textHighPriority,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: textHighPriority,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: textLowPriority,
        ),
      ),

      cardTheme: CardThemeData(
        color: cards,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borders, width: 1),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: borders,
        thickness: 1,
        space: 1,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borders),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borders),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        labelStyle: const TextStyle(color: textLowPriority),
      ),
    );
  }
}
