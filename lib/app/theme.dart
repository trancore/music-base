import 'package:flutter/material.dart';

const defaultAccentColor = Color(0xFF8C7BFF);

ThemeData buildTheme(Brightness brightness, Color accentColor) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: accentColor,
    brightness: brightness,
  );
  return ThemeData(
    brightness: brightness,
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: isDark
        ? const Color(0xFF0D0E12)
        : const Color(0xFFF5F5F7),
    canvasColor: isDark ? const Color(0xFF111217) : Colors.white,
    cardTheme: CardThemeData(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: isDark ? const Color(0xFF17181E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? const Color(0xFF292B34) : const Color(0xFFE4E5EA),
        ),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: isDark
          ? const Color(0xFF0D0E12)
          : const Color(0xFFF5F5F7),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF17181E),
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF17181E) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF292B34) : const Color(0xFFE4E5EA),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF292B34) : const Color(0xFFE4E5EA),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: isDark ? const Color(0xFF111217) : Colors.white,
      indicatorColor: scheme.primary.withValues(alpha: 0.18),
      selectedIconTheme: IconThemeData(color: scheme.primary),
      selectedLabelTextStyle: TextStyle(
        color: scheme.primary,
        fontWeight: FontWeight.w700,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: isDark ? const Color(0xFF111217) : Colors.white,
      indicatorColor: scheme.primary.withValues(alpha: 0.18),
      labelTextStyle: WidgetStatePropertyAll(
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: isDark ? const Color(0xFF292B34) : const Color(0xFFE4E5EA),
      space: 1,
      thickness: 1,
    ),
  );
}
