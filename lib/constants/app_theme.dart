import 'package:flutter/material.dart';

/// Dark Industrial Theme for Vibration Analyzer
/// Optimized for factory/plant environments with high contrast visibility
class AppTheme {
  // Primary Colors - Industrial Blue
  static const Color primaryDark = Color(0xFF0D1B2A);
  static const Color primaryMid = Color(0xFF1B263B);
  static const Color primaryLight = Color(0xFF415A77);
  
  // Accent Colors
  static const Color accentBlue = Color(0xFF00B4D8);
  static const Color accentGreen = Color(0xFF00F5D4);
  static const Color accentCyan = Color(0xFF00E5FF);
  
  // Status Colors (ISO 10816 inspired)
  static const Color statusGood = Color(0xFF00E676);      // Good/Zone A
  static const Color statusSatisfactory = Color(0xFF8BC34A); // Satisfactory/Zone B
  static const Color statusUnsatisfactory = Color(0xFFFFEB3B); // Unsatisfactory/Zone C
  static const Color statusUnacceptable = Color(0xFFFF5252);   // Unacceptable/Zone D
  
  // Chart Colors
  static const Color chartLine = Color(0xFF00E5FF);
  static const Color chartFill = Color(0x3300E5FF);
  static const Color chartGrid = Color(0xFF2A3F5F);
  static const Color chartAxis = Color(0xFF778DA9);
  
  // Surface Colors
  static const Color surface = Color(0xFF1B263B);
  static const Color surfaceLight = Color(0xFF263850);
  static const Color cardBackground = Color(0xFF0D1B2A);
  
  // Text Colors
  static const Color textPrimary = Color(0xFFE0E1DD);
  static const Color textSecondary = Color(0xFF778DA9);
  static const Color textMuted = Color(0xFF415A77);
  
  // Measurement Display
  static const Color valueHighlight = Color(0xFF00F5D4);
  static const Color unitLabel = Color(0xFF778DA9);
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryDark,
      primaryColor: accentBlue,
      colorScheme: const ColorScheme.dark(
        primary: accentBlue,
        secondary: accentGreen,
        surface: surface,
        error: statusUnacceptable,
        onPrimary: primaryDark,
        onSecondary: primaryDark,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryDark,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: primaryLight, width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentBlue,
          foregroundColor: primaryDark,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentGreen,
        foregroundColor: primaryDark,
        elevation: 8,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: primaryDark,
        selectedItemColor: accentBlue,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      iconTheme: const IconThemeData(
        color: accentBlue,
        size: 28,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: valueHighlight,
          fontSize: 56,
          fontWeight: FontWeight.bold,
          letterSpacing: -1,
        ),
        displayMedium: TextStyle(
          color: textPrimary,
          fontSize: 40,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
        titleMedium: TextStyle(
          color: textSecondary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontSize: 14,
        ),
        labelLarge: TextStyle(
          color: unitLabel,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: primaryLight,
        thickness: 0.5,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentBlue, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textMuted),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceLight,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  // Gradient for cards and headers
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surfaceLight, primaryMid],
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentBlue, accentGreen],
  );
  
  // Box shadows for depth
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get glowShadow => [
    BoxShadow(
      color: accentBlue.withValues(alpha: 0.3),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];
}
