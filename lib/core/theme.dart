import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors - Glassmorphism Nature Palette
  static const Color primaryGreen = Color(0xFF10B981); // Emerald 500
  static const Color primaryDark = Color(0xFF047857); // Emerald 700
  static const Color primaryLight = Color(0xFFD1FAE5); // Emerald 100
  static const Color accentYellow = Color(0xFFFDE047); // Sunny Yellow
  
  static const Color textDark = Color(0xFF1F2937); // Gray 800
  static const Color textLight = Color(0xFF6B7280); // Gray 500
  static const Color surfaceWhite = Colors.white;
  static const Color background = Color(0xFFF9FAFB); // Gray 50

  // Alias / Extended Colors for Brand Portal
  static const Color backgroundLight = background;
  static const Color backgroundDark = Color(0xFF111827); // Gray 900
  static const Color textMain = textDark;
  static const Color textSub = textLight;
  static const Color surfaceDark = Color(0xFF1F2937); // Gray 800

  static ThemeData getTheme(Color seedColor) {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: seedColor,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        primary: seedColor,
        secondary: seedColor.withOpacity(0.8), // Derived
        surface: surfaceWhite,
        background: background,
        surfaceTint: Colors.white,
      ),
      
      // Typography
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Outfit', fontSize: 32, fontWeight: FontWeight.bold, color: textDark),
        displayMedium: TextStyle(fontFamily: 'Outfit', fontSize: 28, fontWeight: FontWeight.bold, color: textDark),
        titleLarge: TextStyle(fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.w600, color: textDark),
        titleMedium: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w600, color: textDark),
        bodyLarge: TextStyle(fontSize: 16, color: textDark),
        bodyMedium: TextStyle(fontSize: 14, color: textLight),
      ),

      // Component Themes
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, // Glassmorphism ready
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.w600, color: textDark),
        iconTheme: IconThemeData(color: textDark),
      ),
      
      cardTheme: CardThemeData(
        color: surfaceWhite.withOpacity(0.8), // Semi-transparent for glass effect
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Softer corners
          side: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
          elevation: 4, // Tactics
          shadowColor: seedColor.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: seedColor,
          side: BorderSide(color: seedColor, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.7),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: seedColor, width: 2),
        ),
        labelStyle: GoogleFonts.inter(color: textLight),
        hintStyle: GoogleFonts.inter(color: textLight.withOpacity(0.7)),
      ),
      
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withOpacity(0.9),
        indicatorColor: seedColor.withOpacity(0.2), // Lighter indicator
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: seedColor.withOpacity(0.8)); // Darker icon
          }
          return const IconThemeData(color: textLight);
        }),
      ),
    );
  }
  
  // Backward compatibility
  static ThemeData get lightTheme => getTheme(primaryGreen);
}

class ThemeNotifier extends ChangeNotifier {
  Color _primaryColor = AppTheme.primaryGreen;

  Color get primaryColor => _primaryColor;

  ThemeData get currentTheme => AppTheme.getTheme(_primaryColor);

  void setPrimaryColor(Color color) {
    _primaryColor = color;
    notifyListeners();
  }
}
