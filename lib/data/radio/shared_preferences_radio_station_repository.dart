import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/radio/internet_radio_station.dart';
import '../../domain/radio/radio_station_repository.dart';

class SharedPreferencesRadioStationRepository
    implements RadioStationRepository {
  const SharedPreferencesRadioStationRepository({required this.preferences});

  static const _key = 'internet_radio_stations';
  final SharedPreferences preferences;

  @override
  Future<List<InternetRadioStation>> loadAll() async {
    final encoded = preferences.getString(_key);
    if (encoded == null) return const [];
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return const [];
      return decoded
          .map(InternetRadioStation.fromJson)
          .whereType<InternetRadioStation>()
          .toList(growable: false);
    } on Object {
      return const [];
    }
  }

  @override
  Future<void> save(InternetRadioStation station) async {
    final existing = await loadAll();
    final found = existing.any((entry) => entry.id == station.id);
    final stations = [
      for (final entry in existing)
        if (entry.id == station.id) station else entry,
      if (!found) station,
    ];
    await saveAll(stations);
  }

  @override
  Future<void> saveAll(List<InternetRadioStation> stations) async {
    await preferences.setString(
      _key,
      jsonEncode(stations.map((entry) => entry.toJson()).toList()),
    );
  }

  @override
  Future<void> delete(String id) async {
    final stations = (await loadAll())
        .where((entry) => entry.id != id)
        .toList(growable: false);
    await saveAll(stations);
  }
}
