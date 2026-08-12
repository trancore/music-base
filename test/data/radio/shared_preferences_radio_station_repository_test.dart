import 'package:flutter_test/flutter_test.dart';
import 'package:music_base/data/radio/shared_preferences_radio_station_repository.dart';
import 'package:music_base/domain/radio/internet_radio_station.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('persists, updates, and deletes radio stations', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = SharedPreferencesRadioStationRepository(
      preferences: preferences,
    );
    const station = InternetRadioStation(
      id: 'happy-hardcore',
      name: 'HappyHardcore.com Radio',
      streamUrl: 'https://u1.happyhardcore.com/',
      genre: 'Hardcore',
    );

    await repository.save(station);
    expect((await repository.loadAll()).single.name, station.name);

    await repository.save(station.copyWith(name: 'Updated radio'));
    expect((await repository.loadAll()).single.name, 'Updated radio');

    await repository.delete(station.id);
    expect(await repository.loadAll(), isEmpty);
  });

  test('ignores malformed persisted station entries', () async {
    SharedPreferences.setMockInitialValues({
      'internet_radio_stations': '[{"id":"ok","name":"Station"}]',
    });
    final preferences = await SharedPreferences.getInstance();
    final repository = SharedPreferencesRadioStationRepository(
      preferences: preferences,
    );

    expect(await repository.loadAll(), isEmpty);
  });
}
