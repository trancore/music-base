import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/radio/shared_preferences_radio_station_repository.dart';
import '../data/radio/just_audio_radio_stream_tester.dart';
import '../data/radio/http_radio_browser_service.dart';
import '../domain/radio/internet_radio_station.dart';
import '../domain/radio/radio_station_repository.dart';
import '../domain/radio/radio_stream_tester.dart';
import '../domain/radio/radio_browser_service.dart';
import 'providers.dart';

final radioStationRepositoryProvider = Provider<RadioStationRepository>((ref) {
  return SharedPreferencesRadioStationRepository(
    preferences: ref.watch(sharedPreferencesProvider),
  );
});

final radioStreamTesterProvider = Provider<RadioStreamTester>((ref) {
  return const JustAudioRadioStreamTester();
});

final radioBrowserServiceProvider = Provider<RadioBrowserService>((ref) {
  return const HttpRadioBrowserService();
});

final radioStationProvider =
    AsyncNotifierProvider<RadioStationNotifier, List<InternetRadioStation>>(
      RadioStationNotifier.new,
    );

class RadioStationNotifier extends AsyncNotifier<List<InternetRadioStation>> {
  late final RadioStationRepository _repository;

  @override
  Future<List<InternetRadioStation>> build() {
    _repository = ref.watch(radioStationRepositoryProvider);
    return _repository.loadAll();
  }

  Future<void> save(InternetRadioStation station) async {
    await _repository.save(station);
    state = AsyncData(await _repository.loadAll());
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    state = AsyncData(await _repository.loadAll());
  }

  Future<void> reorder(List<InternetRadioStation> stations) async {
    await _repository.saveAll(stations);
    state = AsyncData(await _repository.loadAll());
  }

  Future<int> importStations(List<InternetRadioStation> imported) async {
    final existing = await _repository.loadAll();
    final ids = existing.map((station) => station.id).toSet();
    final urls = existing.map((station) => station.streamUrl).toSet();
    final additions = <InternetRadioStation>[];
    for (final station in imported) {
      if (ids.contains(station.id) || urls.contains(station.streamUrl)) {
        continue;
      }
      ids.add(station.id);
      urls.add(station.streamUrl);
      additions.add(station);
    }
    if (additions.isEmpty) return 0;
    await _repository.saveAll([...existing, ...additions]);
    state = AsyncData(await _repository.loadAll());
    return additions.length;
  }
}

String? validateRadioStationUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null || !{'http', 'https'}.contains(uri.scheme)) {
    return 'Enter an http:// or https:// stream URL.';
  }
  if (uri.host.isEmpty) return 'Enter a complete stream URL.';
  if (uri.path.toLowerCase().endsWith('.html') ||
      uri.path.toLowerCase().endsWith('.asp')) {
    return 'Enter the audio stream URL, not a web page URL.';
  }
  return null;
}
