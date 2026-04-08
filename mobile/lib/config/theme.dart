import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Configuração de tema minimalista Apple-inspired
class AppTheme {
  // Cores Primárias - Minimalista
  static const Color primaryColor = Color(0xFF000000); // Preto puro
  static const Color primaryLight = Color(0xFF333333);
  static const Color primaryDark = Color(0xFF000000);
  static const Color accentBlue = Color(0xFF007AFF); // Azul Apple
  
  // Cores Secundárias
  static const Color secondaryColor = Color(0xFF34C759); // Verde Apple
  static const Color accentColor = Color(0xFF007AFF); // Azul Apple
  static const Color accentOrange = Color(0xFFFF9500); // Laranja Apple

  // Cores Neutras - Estilo Apple
  static const Color colorBackground = Color(0xFFFFFFFF); // Branco puro
  static const Color colorSurface = Color(0xFFFAFAFA); // Branco levemente off
  static const Color colorText = Color(0xFF000000); // Preto
  static const Color colorSubtext = Color(0xFF8E8E93); // Cinza Apple
  static const Color colorBorder = Color(0xFFE5E5EA); // Cinza claro Apple

  // Cores Escuras - Apple Dark Mode
  static const Color darkBackground = Color(0xFF000000); // Preto puro
  static const Color darkSurface = Color(0xFF1C1C1E); // Cinza escuro Apple
  static const Color darkSurfaceLight = Color(0xFF2C2C2E);
  static const Color darkText = Color(0xFFFFFFFF); // Branco puro
  static const Color darkSubtext = Color(0xFF8E8E93);

  // Status Colors - Apple Style
  static const Color successColor = Color(0xFF34C759); // Verde Apple
  static const Color warningColor = Color(0xFFFF9500); // Laranja Apple
  static const Color errorColor = Color(0xFFFF3B30); // Vermelho Apple
  static const Color infoColor = Color(0xFF007AFF); // Azul Apple

  // Light Theme - Apple Style
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: colorBackground,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: accentBlue,
      error: errorColor,
      background: colorBackground,
      surface: colorSurface,
    ),
    textTheme: GoogleFonts.interTextTheme(
      ThemeData.light().textTheme,
    ).copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: colorText,
        letterSpacing: -1.5,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: colorText,
        letterSpacing: -1.0,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: colorText,
        letterSpacing: -0.5,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colorText,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: colorText,
        letterSpacing: -0.4,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: colorSubtext,
        letterSpacing: -0.2,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: colorBackground,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: colorText,
        letterSpacing: -0.4,
      ),
      iconTheme: const IconThemeData(color: colorText),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: colorBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: colorBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accentBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 1),
      ),
      labelStyle: GoogleFonts.inter(
        color: colorSubtext,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.2,
      ),
      hintStyle: GoogleFonts.inter(
        color: colorSubtext,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.2,
      ),
      prefixIconColor: colorSubtext,
      suffixIconColor: colorSubtext,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: const BorderSide(color: colorBorder, width: 1),
        textStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentBlue,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.4,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: colorBorder, width: 1),
      ),
      color: colorSurface,
      shadowColor: Colors.transparent,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colorSurface,
      selectedColor: primaryColor,
      labelStyle: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.2,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: colorBorder, width: 1),
      ),
    ),
  );

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryLight,
    scaffoldBackgroundColor: darkBackground,
    colorScheme: ColorScheme.dark(
      primary: primaryLight,
      secondary: secondaryColor,
      error: errorColor,
      background: darkBackground,
      surface: darkSurface,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(
      ThemeData.dark().textTheme,
    ).copyWith(
      displayLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: darkText,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: darkText,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: darkText,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: darkText,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: darkText,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: darkSubtext,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryLight, width: 2),
      ),
      labelStyle: GoogleFonts.poppins(
        color: darkSubtext,
        fontSize: 14,
      ),
      hintStyle: GoogleFonts.poppins(
        color: Colors.grey[600],
        fontSize: 14,
      ),
    ),
  );
}
