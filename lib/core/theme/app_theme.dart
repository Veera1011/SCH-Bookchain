import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Parsing Hex Color
  static Color _colorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  // Dynamic Theme Builder
  static ThemeData buildTheme(String hexPrimary, bool isDark) {
    const Color primaryColor = Color(0xFF233E80);

    final Color secondary = isDark ? primaryColor.withOpacity(0.8) : const Color(0xFF9DBCE2);
    final Color accent = const Color(0xFFE8A020);
    final Color error = const Color(0xFFC62828);

    final Color background = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final Color surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color onBackground = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);

    final Color onSurface = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    final Color onPrimary = Colors.white;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: (isDark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
        primary: primaryColor,
        onPrimary: onPrimary,
        secondary: secondary,
        onSecondary: Colors.white,
        tertiary: accent,
        onTertiary: Colors.black,
        error: error,
        onError: Colors.white,
        surface: surface,
        onSurface: onSurface,
        background: background,
        onBackground: onBackground,
      ),
      fontFamily: GoogleFonts.outfit().fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
      ),
      scaffoldBackgroundColor: background,
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        color: surface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B).withOpacity(0.5) : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        selectedColor: primaryColor.withOpacity(0.1),
        labelStyle: TextStyle(color: isDark ? Colors.white : primaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primaryColor.withOpacity(0.1),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return IconThemeData(color: primaryColor);
          }
          return IconThemeData(color: onSurface.withOpacity(0.6));
        }),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            );
          }
          return TextStyle(
            color: onSurface.withOpacity(0.6),
            fontSize: 12,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        selectedIconTheme: IconThemeData(color: primaryColor),
        unselectedIconTheme: IconThemeData(color: onSurface.withOpacity(0.6)),
        selectedLabelTextStyle: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: onSurface.withOpacity(0.6),
        ),
        indicatorColor: primaryColor.withOpacity(0.1),
      ),
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: onBackground),
        titleLarge: TextStyle(color: onBackground),
      ),
      // Fix for legacy 'lightTheme' references
    );
  }

  // Fallback static theme for places that might call AppTheme.lightTheme directly before observing changes
  static ThemeData get lightTheme => buildTheme('#233E80', false);
}

