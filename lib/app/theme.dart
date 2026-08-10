import 'package:flutter/material.dart';

const defaultAccentColor = Color(0xFF6750A4);

ThemeData buildTheme(Brightness brightness, Color accentColor) {
  return ThemeData(
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accentColor,
      brightness: brightness,
    ),
    useMaterial3: true,
  );
}
