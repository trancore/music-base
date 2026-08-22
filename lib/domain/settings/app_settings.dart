import 'package:flutter/material.dart';

import '../radio/radio_station_sort.dart';
import 'app_locale.dart';

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.accentColorValue = 0xFF6750A4,
    this.radioStationSort = RadioStationSort.manual,
    this.locale = AppLocale.system,
  });

  final ThemeMode themeMode;
  final int accentColorValue;
  final RadioStationSort radioStationSort;
  final AppLocale locale;

  Color get accentColor => Color(accentColorValue);

  AppSettings copyWith({
    ThemeMode? themeMode,
    int? accentColorValue,
    RadioStationSort? radioStationSort,
    AppLocale? locale,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      accentColorValue: accentColorValue ?? this.accentColorValue,
      radioStationSort: radioStationSort ?? this.radioStationSort,
      locale: locale ?? this.locale,
    );
  }
}
