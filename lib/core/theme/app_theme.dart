import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Theme Helper
  static ThemeData getTheme(String themeName, {bool isAccessibilityMode = false}) {
    bool isLight = themeName == 'Blanco';
    bool isDaltonic = themeName == 'Daltónico';

    // Default: Original (Dark)
    Color bg = const Color(0xFF060D1C);
    Color surf = const Color(0xFF0D1629);
    Color crd = const Color(0xFF111F36);
    Color brd = const Color(0xFF1C2D47);
    Color prim = const Color(0xFF4F8EF7);
    Color sec = const Color(0xFF818CF8);
    Color txtHigh = const Color(0xFFF1F5F9);
    Color txtLow = const Color(0xFF64748B);
    Color succ = const Color(0xFF059669);
    Color dang = const Color(0xFFDC2626);
    Color gld = const Color(0xFFFCD34D);
    Brightness brightness = Brightness.dark;

    if (isLight) {
      bg = const Color(0xFFF1F5F9); // Light Gray BG
      surf = Colors.white;
      crd = Colors.white;
      brd = const Color(0xFFE2E8F0);
      prim = const Color(0xFF2563EB); // Vibrant Blue
      sec = const Color(0xFF4F46E5);
      txtHigh = const Color(0xFF0F172A);
      txtLow = const Color(0xFF64748B);
      succ = const Color(0xFF059669);
      dang = const Color(0xFFDC2626);
      gld = const Color(0xFFD97706);
      brightness = Brightness.light;
    } else if (isDaltonic) {
      bg = Colors.black;
      surf = const Color(0xFF171717);
      crd = const Color(0xFF262626);
      brd = const Color(0xFF404040);
      prim = const Color(0xFF2D6AAF); // Cobalt Blue
      sec = const Color(0xFF1D4E89);
      txtHigh = Colors.white;
      txtLow = const Color(0xFFA3A3A3);
      succ = const Color(0xFF2ECC71);
      dang = const Color(0xFFE74C3C);
      gld = const Color(0xFFF1C40F);
    }

    double scale = isAccessibilityMode ? 1.25 : 1.0;
    
    // High contrast overrides for accessibility mode
    if (isAccessibilityMode) {
      txtLow = txtHigh.withValues(alpha: 0.9);
      brd = txtHigh.withValues(alpha: 0.3);
    }

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      primaryColor: prim,
      
      extensions: [
        AppColors(
          success: succ,
          danger: dang,
          gold: gld,
          surface: surf,
          border: brd,
          textHigh: txtHigh,
          textLow: txtLow,
          card: crd,
        ),
      ],

      colorScheme: ColorScheme.fromSeed(
        seedColor: prim,
        brightness: brightness,
        primary: prim,
        secondary: sec,
        surface: surf,
        onSurface: txtHigh,
        error: dang,
        outline: brd,
      ),

      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32 * scale,
          fontWeight: FontWeight.bold,
          color: txtHigh,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 26 * scale,
          fontWeight: FontWeight.bold,
          color: txtHigh,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20 * scale,
          fontWeight: FontWeight.bold,
          color: txtHigh,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16 * scale,
          color: txtHigh,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14 * scale,
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

class AppColors extends ThemeExtension<AppColors> {
  final Color success;
  final Color danger;
  final Color gold;
  final Color surface;
  final Color border;
  final Color textHigh;
  final Color textLow;
  final Color card;

  AppColors({
    required this.success,
    required this.danger,
    required this.gold,
    required this.surface,
    required this.border,
    required this.textHigh,
    required this.textLow,
    required this.card,
  });

  @override
  ThemeExtension<AppColors> copyWith({
    Color? success,
    Color? danger,
    Color? gold,
    Color? surface,
    Color? border,
    Color? textHigh,
    Color? textLow,
    Color? card,
  }) {
    return AppColors(
      success: success ?? this.success,
      danger: danger ?? this.danger,
      gold: gold ?? this.gold,
      surface: surface ?? this.surface,
      border: border ?? this.border,
      textHigh: textHigh ?? this.textHigh,
      textLow: textLow ?? this.textLow,
      card: card ?? this.card,
    );
  }

  @override
  ThemeExtension<AppColors> lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      border: Color.lerp(border, other.border, t)!,
      textHigh: Color.lerp(textHigh, other.textHigh, t)!,
      textLow: Color.lerp(textLow, other.textLow, t)!,
      card: Color.lerp(card, other.card, t)!,
    );
  }
}
