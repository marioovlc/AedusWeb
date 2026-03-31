import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Aedus Original (Dark) - Static Constants for compatibility
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
  
  // Theme Helper
  static ThemeData getTheme(String themeName) {
    bool isLight = themeName == 'Blanco';
    bool isDaltonic = themeName == 'Daltónico';

    Color bg = background;
    Color surf = surface;
    Color crd = cards;
    Color brd = borders;
    Color prim = primaryBlue;
    Color txtHigh = const Color(0xFFF1F5F9);
    Color txtLow = const Color(0xFF64748B);
    Brightness brightness = Brightness.dark;

    if (isLight) {
      bg = const Color(0xFFF8FAFC);
      surf = Colors.white;
      crd = Colors.white;
      brd = const Color(0xFFE2E8F0);
      prim = const Color(0xFF2563EB);
      txtHigh = const Color(0xFF0F172A);
      txtLow = const Color(0xFF475569);
      brightness = Brightness.light;
    } else if (isDaltonic) {
      bg = Colors.black;
      surf = const Color(0xFF1A1A1A);
      crd = const Color(0xFF262626);
      brd = const Color(0xFF404040);
      prim = const Color(0xFF2E86AB); // Cobalt Blue (Accessible)
      txtHigh = Colors.white;
      txtLow = const Color(0xFFA3A3A3);
    }

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      primaryColor: prim,
      
      colorScheme: ColorScheme.fromSeed(
        seedColor: prim,
        brightness: brightness,
        primary: prim,
        surface: surf,
        onSurface: txtHigh,
        error: const Color(0xFFDC2626),
        outline: brd,
      ),

      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: txtHigh,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: txtHigh,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: txtHigh,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: txtHigh,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: txtLow,
        ),
      ),

      cardTheme: CardThemeData(
        color: crd,
        elevation: isLight ? 1 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: brd, width: 1),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: brd,
        thickness: 1,
        space: 1,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: prim,
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
        fillColor: surf,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: brd),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: brd),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: prim, width: 2),
        ),
        labelStyle: TextStyle(color: txtLow),
      ),
    );
  }
}
