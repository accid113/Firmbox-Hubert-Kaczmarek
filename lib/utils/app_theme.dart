import 'package:flutter/material.dart';

class AppTheme {
  // color
  static const Color primaryColor = Color(0xFF1A1A2E);
  static const Color secondaryColor = Color(0xFF16213E);
  static const Color accentColor = Color(0xFF0F3460);
  static const Color surfaceColor = Color(0xFF0E1621);
  static const Color cardColor = Color(0xFF1F1F3A);
  static const Color backgroundColor = Color(0xFF1A1A2E);
  
  // slides
  static const Color businessIdeaColor = Color(0xFF6C63FF);
  static const Color businessCardColor = Color(0xFF4ECDC4);
  static const Color logoColor = Color(0xFFFF6B6B);
  static const Color websiteColor = Color(0xFF45B7D1);
  static const Color invoiceColor = Color(0xFFFFD93D);
  
  // txt
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B3C7);
  static const Color textHint = Color(0xFF6B7280);
  
  // gradient
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A1A2E),
      Color(0xFF16213E),
      Color(0xFF0F3460),
    ],
  );

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: primaryColor,
    cardColor: cardColor,
    
    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: textPrimary),
    ),
    
    // Text Theme
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: textPrimary,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: textPrimary,
        fontSize: 28,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: TextStyle(
        color: textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w500,
      ),
      titleLarge: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: textPrimary,
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
      bodySmall: TextStyle(
        color: textHint,
        fontSize: 12,
      ),
    ),
    
    // Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: businessIdeaColor,
        foregroundColor: textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        elevation: 4,
      ),
    ),
    
    // OutlinedButton Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textPrimary,
        side: const BorderSide(color: businessIdeaColor, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // TextButton Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: businessIdeaColor,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accentColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: businessIdeaColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      labelStyle: const TextStyle(color: textSecondary),
      hintStyle: const TextStyle(color: textHint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    
    // Card Theme
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    
    // FloatingActionButton Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: businessIdeaColor,
      foregroundColor: textPrimary,
    ),
    
    // BottomNavigationBar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: cardColor,
      selectedItemColor: businessIdeaColor,
      unselectedItemColor: textSecondary,
      type: BottomNavigationBarType.fixed,
    ),
    
    // Progress Indicator Theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: businessIdeaColor,
    ),
    
    // Divider Theme
    dividerTheme: DividerThemeData(
      color: accentColor.withOpacity(0.3),
      thickness: 1,
    ),
  );

  static BoxDecoration getCardDecoration({Color? color}) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color?.withOpacity(0.8) ?? cardColor,
          color?.withOpacity(0.6) ?? cardColor.withOpacity(0.8),
          cardColor,
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
  
  // animation
  static BoxDecoration getPulsingBorder({required Color color}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: color.withOpacity(0.5),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.3),
          blurRadius: 8,
          spreadRadius: 2,
        ),
      ],
    );
  }
} 