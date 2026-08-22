import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database/app_database.dart';
import '../data/settings/shared_preferences_settings_repository.dart';
import '../domain/settings/app_settings.dart';
import '../domain/settings/app_locale.dart';
import '../domain/settings/settings_repository.dart';
import '../domain/radio/radio_station_sort.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be provided at startup.');
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SharedPreferencesSettingsRepository(
    ref.watch(sharedPreferencesProvider),
  );
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final appSettingsProvider =
    AsyncNotifierProvider<AppSettingsNotifier, AppSettings>(
      AppSettingsNotifier.new,
    );

class AppSettingsNotifier extends AsyncNotifier<AppSettings> {
  late final SettingsRepository _repository;

  @override
  Future<AppSettings> build() async {
    _repository = ref.watch(settingsRepositoryProvider);
    return _repository.load();
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    await _update(state.valueOrNull?.copyWith(themeMode: themeMode));
  }

  Future<void> setAccentColor(int colorValue) async {
    await _update(state.valueOrNull?.copyWith(accentColorValue: colorValue));
  }

  Future<void> setRadioStationSort(RadioStationSort sort) async {
    await _update(state.valueOrNull?.copyWith(radioStationSort: sort));
  }

  Future<void> setLocale(AppLocale locale) async {
    await _update(state.valueOrNull?.copyWith(locale: locale));
  }

  Future<void> _update(AppSettings? next) async {
    if (next == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.save(next);
      return next;
    });
  }
}
