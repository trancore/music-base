import 'package:flutter/material.dart';

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.accentColorValue = 0xFF6750A4,
  });

  final ThemeMode themeMode;
  final int accentColorValue;

  Color get accentColor => Color(accentColorValue);

  AppSettings copyWith({ThemeMode? themeMode, int? accentColorValue}) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      accentColorValue: accentColorValue ?? this.accentColorValue,
    );
  }
}
