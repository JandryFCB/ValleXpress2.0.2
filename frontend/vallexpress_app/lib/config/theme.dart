import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colores basados en tu diseño
  static const Color primaryColor = Color(0xFFFDB827); // Amarillo del botón
  static const Color backgroundColor = Color(
    0xFF0A2A3A,
  ); // Azul oscuro del fondo
  static const Color cardColor = Color(0xFF133B4F); // Azul del card
  static const Color borderColor = Color(0xFFFDB827); // Amarillo del borde
  static const Color textPrimaryColor = Colors.white;
  static const Color textSecondaryColor = Color(0xFFB0BEC5);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,

      // Colores
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryColor,
        surface: cardColor,
      ),

      // Tipografía
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        headlineLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        bodyLarge: GoogleFonts.poppins(fontSize: 16, color: textPrimaryColor),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          color: textSecondaryColor,
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: borderColor.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        hintStyle: GoogleFonts.poppins(color: textSecondaryColor, fontSize: 14),
        labelStyle: GoogleFonts.poppins(
          color: textSecondaryColor,
          fontSize: 14,
        ),
      ),

      // Botones
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
