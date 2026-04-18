import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryDarkBlue = Color(0xFF0A1F44); // Deep Navy
  static const Color primaryLightBlue = Color(0xFFEDF2F7); // Soft light blue for inputs
  static const Color white = Colors.white;
  static const Color baseWhite = Color(0xFFF8FAFC);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkBackground = Color(0xFF0F172A);
  
  static const Color textLightMode = Color(0xFF0A1F44);
  static const Color textDarkMode = Color(0xFFF8FAFC);

  // ---------------- LIGHT THEME ----------------
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryDarkBlue,
      scaffoldBackgroundColor: white,
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme).apply(
        bodyColor: textLightMode,
        displayColor: textLightMode,
      ),
      colorScheme: const ColorScheme.light(
        primary: primaryDarkBlue,
        secondary: primaryDarkBlue,
        surface: white,
        onPrimary: white,
        onSurface: textLightMode,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryDarkBlue,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDarkBlue,
          foregroundColor: white,
          minimumSize: const Size(double.infinity, 55),
          elevation: 0,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: primaryLightBlue,
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: primaryDarkBlue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      ),
    );
  }

  // ---------------- DARK THEME ----------------
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryDarkBlue, // Updated to Dark Blue as requested
      scaffoldBackgroundColor: darkBackground,
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: textDarkMode,
        displayColor: textDarkMode,
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryDarkBlue, // Primary is now Dark Blue
        secondary: primaryDarkBlue,
        surface: darkSurface,
        onPrimary: baseWhite, // Use white text/icons over primary dark blue
        onSurface: textDarkMode,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryDarkBlue, // Header in Dark Blue
        foregroundColor: baseWhite,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: baseWhite,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDarkBlue, // Buttons in Dark Blue
          foregroundColor: baseWhite, // Text in White
          minimumSize: const Size(double.infinity, 55),
          elevation: 0,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: baseWhite, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      ),
    );
  }
}
