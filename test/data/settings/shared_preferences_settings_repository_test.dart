import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:music_base/data/settings/shared_preferences_settings_repository.dart';
import 'package:music_base/domain/settings/app_settings.dart';

void main() {
  test('loads defaults when no settings have been saved', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = SharedPreferencesSettingsRepository(preferences);

    final settings = await repository.load();

    expect(settings.themeMode, ThemeMode.system);
    expect(settings.accentColorValue, 0xFF6750A4);
  });

  test('persists and restores appearance settings', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = SharedPreferencesSettingsRepository(preferences);

    await repository.save(
      const AppSettings(
        themeMode: ThemeMode.dark,
        accentColorValue: 0xFF006A6A,
      ),
    );
    final restored = await repository.load();

    expect(restored.themeMode, ThemeMode.dark);
    expect(restored.accentColorValue, 0xFF006A6A);
  });
}
