import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

import 'package:music_base/app/playback_providers.dart';
import 'package:music_base/app/radio_providers.dart';
import 'package:music_base/data/playback/just_audio_playback_service.dart';
import 'package:music_base/domain/radio/internet_radio_station.dart';
import 'package:music_base/domain/radio/radio_browser_service.dart';
import 'package:music_base/domain/radio/radio_browser_station.dart';
import 'package:music_base/domain/radio/radio_station_repository.dart';
import 'package:music_base/domain/radio/radio_stream_tester.dart';
import 'package:music_base/presentation/radio/radio_page.dart';

void main() {
  testWidgets('groups genre sorting by the first tag with Other last', (
    tester,
  ) async {
    final playback = JustAudioPlaybackService(AudioPlayer());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          radioStationRepositoryProvider.overrideWithValue(
            const _FakeRadioStationRepository([
              InternetRadioStation(
                id: 'rock-2',
                name: 'Rock Two',
                streamUrl: 'https://example.com/rock-2',
                genre: 'rock; alternative',
              ),
              InternetRadioStation(
                id: 'other',
                name: 'No Genre',
                streamUrl: 'https://example.com/other',
              ),
              InternetRadioStation(
                id: 'jazz',
                name: 'Jazz One',
                streamUrl: 'https://example.com/jazz',
                genre: 'Jazz',
              ),
              InternetRadioStation(
                id: 'rock-1',
                name: 'Rock One',
                streamUrl: 'https://example.com/rock-1',
                genre: 'Rock, classic',
              ),
            ]),
          ),
          playbackServiceProvider.overrideWith((ref) => playback),
        ],
        child: const MaterialApp(home: RadioPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Manual order'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Genre').last);
    await tester.pumpAndSettle();

    expect(find.text('Jazz'), findsOneWidget);
    expect(find.text('Rock'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
    expect(find.text('alternative'), findsNothing);
    expect(
      tester.getTopLeft(find.text('Jazz')).dy,
      lessThan(tester.getTopLeft(find.text('Rock')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Rock')).dy,
      lessThan(tester.getTopLeft(find.text('Other')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Rock One')).dy,
      lessThan(tester.getTopLeft(find.text('Rock Two')).dy),
    );
  });

  testWidgets('keeps a Radio Browser station when playback fails', (
    tester,
  ) async {
    final repository = _RecordingRadioStationRepository();
    final streamTester = _FailingRadioStreamTester();
    final playback = _FailingRadioPlaybackService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          radioStationRepositoryProvider.overrideWithValue(repository),
          radioBrowserServiceProvider.overrideWithValue(
            const _SingleRadioBrowserService(),
          ),
          radioStreamTesterProvider.overrideWithValue(streamTester),
          playbackServiceProvider.overrideWith((ref) => playback),
        ],
        child: const MaterialApp(home: RadioPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Search Radio Browser'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'J-Idols');
    await tester.tap(find.widgetWithText(FilledButton, 'Search'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('J-Idols Project Radio'));
    await tester.pumpAndSettle();

    expect(repository.stations.single.name, 'J-Idols Project Radio');
    expect(streamTester.calls, 0);
    expect(
      find.textContaining(
        'Added J-Idols Project Radio, but playback could not start',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('reports playback failure from a saved station', (tester) async {
    const station = InternetRadioStation(
      id: 'offline',
      name: 'Offline Radio',
      streamUrl: 'https://example.com/offline',
    );
    final playback = _FailingRadioPlaybackService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          radioStationRepositoryProvider.overrideWithValue(
            const _FakeRadioStationRepository([station]),
          ),
          playbackServiceProvider.overrideWith((ref) => playback),
        ],
        child: const MaterialApp(home: RadioPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Play'));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not play Offline Radio. Try again later.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

class _SingleRadioBrowserService implements RadioBrowserService {
  const _SingleRadioBrowserService();

  @override
  Future<List<RadioBrowserStation>> search(String query) async => const [
    RadioBrowserStation(
      stationUuid: 'j-idols',
      name: 'J-Idols Project Radio',
      streamUrl: 'http://bluford.torontocast.com:8081/stream/;',
      homepage: null,
      tags: 'idol,j-pop',
      countryCode: null,
      codec: 'MP3',
      bitrate: 128,
      lastCheckOk: true,
      hls: false,
    ),
  ];
}

class _FailingRadioStreamTester implements RadioStreamTester {
  int calls = 0;

  @override
  Future<void> test(InternetRadioStation station) async {
    calls++;
    throw StateError('unreachable');
  }
}

class _FailingRadioPlaybackService extends JustAudioPlaybackService {
  _FailingRadioPlaybackService() : super(AudioPlayer());

  @override
  Future<void> playRadioStation(InternetRadioStation station) async {
    throw StateError('unreachable');
  }
}

class _RecordingRadioStationRepository implements RadioStationRepository {
  final List<InternetRadioStation> stations = [];

  @override
  Future<List<InternetRadioStation>> loadAll() async =>
      List.unmodifiable(stations);

  @override
  Future<void> save(InternetRadioStation station) async {
    stations.removeWhere((entry) => entry.id == station.id);
    stations.add(station);
  }

  @override
  Future<void> delete(String id) async {
    stations.removeWhere((entry) => entry.id == id);
  }

  @override
  Future<void> saveAll(List<InternetRadioStation> stations) async {
    this.stations
      ..clear()
      ..addAll(stations);
  }
}

class _FakeRadioStationRepository implements RadioStationRepository {
  const _FakeRadioStationRepository(this.stations);

  final List<InternetRadioStation> stations;

  @override
  Future<List<InternetRadioStation>> loadAll() async => stations;

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> save(InternetRadioStation station) async {}

  @override
  Future<void> saveAll(List<InternetRadioStation> stations) async {}
}
