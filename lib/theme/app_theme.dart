import 'package:flutter/material.dart';

/// App-wide theme tokens and convenience styles. These tokens represent the
/// minimal, calm visual system used across Focuslog: subdued colors, generous
/// spacing, and unobtrusive surfaces that prioritize readability and reflection.
class AppTheme {
  // Palette — calm and neutral
  static const Color background = Color(0xFFF4F6F7); // slightly warm background
  static const Color surface = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF2C3E50); // used for headings / primary text
  static const Color muted = Color(0xFF7F8C8D); // secondary text / subtle UI
  static const Color accent = Color(0xFF6CA0FF); // accent for neutral highlights (soft blue)
  static const Color surfaceAlt = Color(0xFFECF0F1);

  // Layout & spacing tokens
  static const double spacingXs = 6.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 12.0;
  static const double spacingLg = 20.0;
  static const double spacingXl = 28.0;

  // Radius and elevation
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double cardElevation = 0.0;

  // Typography helpers
  static const TextStyle titleLarge = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: primary);
  static const TextStyle titleMedium = TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: primary);
  static const TextStyle body = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: primary, height: 1.5);
  static const TextStyle bodyMuted = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: muted, height: 1.5);

  // Expose a ThemeData configured for the app
  static ThemeData get theme {
    final colorScheme = ColorScheme.fromSeed(seedColor: primary);
    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      useMaterial3: true,
      fontFamily: 'SF Pro',
      textTheme: TextTheme(
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: primary),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: primary),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: primary, height: 1.6),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: muted, height: 1.5),
        labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: muted),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: cardElevation,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        margin: const EdgeInsets.symmetric(vertical: spacingSm),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: surface,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusSm), borderSide: BorderSide(color: accent.withAlpha(60))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusSm), borderSide: BorderSide(color: accent.withAlpha(60))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusSm), borderSide: BorderSide(color: primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: bodyMuted,
      ),
    );
  }
}
