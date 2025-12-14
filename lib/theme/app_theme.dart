import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData themeData(Locale locale) {
    final isArabic = locale.languageCode == 'ar';
    
    // 1. Determine the Font Family based on language
    // We get the actual font name string from GoogleFonts
    final String? fontFamily = isArabic 
        ? GoogleFonts.cairo().fontFamily 
        : GoogleFonts.poppins().fontFamily;

    // 2. Create the TextTheme
    final TextTheme baseTextTheme = isArabic 
        ? GoogleFonts.cairoTextTheme() 
        : GoogleFonts.poppinsTextTheme();

    return ThemeData(
      useMaterial3: true,
      
      // THIS IS THE FIX: Set the global font family for the entire app
      fontFamily: fontFamily,
      
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: Brightness.light,
        surface: const Color(0xFFF8F9FC),
      ),
      
      textTheme: baseTextTheme,
      
      // Explicitly styling buttons to ensure they pick up the font
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          // Force font usage here just in case
          textStyle: TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.bold,
            fontFamily: fontFamily, 
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: Colors.indigo),
          textStyle: TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.bold,
            fontFamily: fontFamily,
          ),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.bold,
            fontFamily: fontFamily,
          ),
        ),
      ),
      
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleTextStyle: baseTextTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          fontFamily: fontFamily,
        ),
      ),
      
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.indigo, width: 2),
        ),
        // Ensure typed text uses the correct font
        labelStyle: TextStyle(fontFamily: fontFamily),
        hintStyle: TextStyle(fontFamily: fontFamily),
      ),
    );
  }
}