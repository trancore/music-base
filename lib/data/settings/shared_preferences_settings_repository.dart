import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/settings/app_settings.dart';
import '../../domain/settings/app_locale.dart';
import '../../domain/radio/radio_station_sort.dart';
import '../../domain/settings/settings_repository.dart';

class SharedPreferencesSettingsRepository implements SettingsRepository {
  const SharedPreferencesSettingsRepository(this._preferences);

  static const _themeModeKey = 'settings.theme_mode';
  static const _accentColorKey = 'settings.accent_color';
  static const _radioStationSortKey = 'settings.radio_station_sort';
  static const _localeKey = 'settings.locale';

  final SharedPreferences _preferences;

  @override
  Future<AppSettings> load() async {
    final themeModeName = _preferences.getString(_themeModeKey);
    final themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == themeModeName,
      orElse: () => ThemeMode.system,
    );
    final radioStationSort = RadioStationSort.values.firstWhere(
      (sort) => sort.name == _preferences.getString(_radioStationSortKey),
      orElse: () => RadioStationSort.manual,
    );
    final locale = AppLocale.values.firstWhere(
      (value) => value.name == _preferences.getString(_localeKey),
      orElse: () => AppLocale.system,
    );

    return AppSettings(
      themeMode: themeMode,
      accentColorValue: _preferences.getInt(_accentColorKey) ?? 0xFF6750A4,
      radioStationSort: radioStationSort,
      locale: locale,
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _preferences.setString(_themeModeKey, settings.themeMode.name);
    await _preferences.setInt(_accentColorKey, settings.accentColorValue);
    await _preferences.setString(
      _radioStationSortKey,
      settings.radioStationSort.name,
    );
    await _preferences.setString(_localeKey, settings.locale.name);
  }
}
