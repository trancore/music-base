import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:music_base/app/app.dart';
import 'package:music_base/app/library_providers.dart';
import 'package:music_base/app/providers.dart';
import 'package:music_base/domain/library/library_repository.dart';
import 'package:music_base/domain/library/library_query.dart';
import 'package:music_base/domain/library/library_track.dart';
import 'package:music_base/domain/library/smb_source.dart';
import 'package:music_base/presentation/playback/playback_visualizer.dart';

void main() {
  testWidgets('renders the Music Base library shell', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          libraryRepositoryProvider.overrideWithValue(_FakeLibraryRepository()),
        ],
        child: const MusicBaseApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Music Base'), findsOneWidget);
    expect(find.text('Music library'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.byType(CheckedModeBanner), findsNothing);
  });

  testWidgets('shows inferred artist and album in a library track row', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          libraryRepositoryProvider.overrideWithValue(
            _FakeLibraryRepository(
              tracks: [
                LibraryTrack(
                  sourcePath: '/Music/Artist/Album/01 - Song.flac',
                  title: 'Song',
                  artist: 'Artist',
                  album: 'Album',
                  discNumber: 2,
                  trackNumber: 7,
                ),
              ],
            ),
          ),
        ],
        child: const MusicBaseApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Artist'), findsNWidgets(2));
    expect(find.text('Album'), findsNWidgets(2));
    expect(find.text('2-7'), findsOneWidget);
  });

  testWidgets('switches between album and artist browsing', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          libraryRepositoryProvider.overrideWithValue(
            _FakeLibraryRepository(
              tracks: const [
                LibraryTrack(
                  sourcePath: '/music/one.flac',
                  title: 'first track',
                  artist: 'sample performer',
                  album: 'sample collection',
                ),
                LibraryTrack(
                  sourcePath: '/music/two.flac',
                  title: 'second track',
                  artist: 'sample performer',
                  album: 'sample collection',
                ),
              ],
            ),
          ),
        ],
        child: const MusicBaseApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Albums'));
    await tester.pumpAndSettle();
    expect(find.text('1 albums'), findsOneWidget);
    expect(find.text('sample collection'), findsWidgets);

    await tester.tap(find.text('sample collection'));
    await tester.pumpAndSettle();
    expect(find.text('sample collection'), findsWidgets);
    expect(find.text('first track'), findsOneWidget);

    await tester.tap(find.text('Artists'));
    await tester.pumpAndSettle();
    expect(find.text('1 artists'), findsOneWidget);
    expect(find.text('sample performer'), findsOneWidget);
  });

  testWidgets('retries a failed library scan from the error card', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          libraryRepositoryProvider.overrideWithValue(
            _FakeLibraryRepository(
              failInitialLoad: true,
              tracks: [
                LibraryTrack(
                  sourcePath: '/Music/Song.flac',
                  title: 'Recovered song',
                ),
              ],
            ),
          ),
        ],
        child: const MusicBaseApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Library scan failed'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Recovered song'), findsOneWidget);
    expect(find.text('Library scan failed'), findsNothing);
  });

  testWidgets('shows the playback visualizer when a track is playing', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          libraryRepositoryProvider.overrideWithValue(
            _FakeLibraryRepository(
              tracks: [
                LibraryTrack(
                  sourcePath: '/Music/Artist/Album/Song.flac',
                  title: 'Song',
                ),
              ],
            ),
          ),
        ],
        child: const MusicBaseApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.play_arrow).last);
    await tester.pump();

    expect(find.text('Waveform / spectrum visualizer'), findsOneWidget);
    expect(find.byType(PlaybackVisualizer), findsOneWidget);
    expect(
      tester.widget<PlaybackVisualizer>(find.byType(PlaybackVisualizer)).height,
      112,
    );
  });
}

class _FakeLibraryRepository implements LibraryRepository {
  _FakeLibraryRepository({
    this.tracks = const [],
    this.failInitialLoad = false,
  });

  final List<LibraryTrack> tracks;
  final bool failInitialLoad;
  bool _failedInitialQuery = false;

  @override
  Future<String?> loadSourcePath() async => failInitialLoad ? '/Music' : null;

  @override
  Future<void> saveSourcePath(String path) async {}

  @override
  Future<List<LibraryTrack>> loadTracks() async {
    if (failInitialLoad) throw StateError('temporary scan failure');
    return tracks;
  }

  @override
  Future<List<LibraryTrack>> scanAndCache(String path) async => tracks;

  @override
  Future<List<LibraryTrack>> scanSmbAndCache(
    SmbSource source,
    String password,
  ) async => const [];

  @override
  Future<String?> loadLastLocalSourcePath() async => null;

  @override
  Future<LibraryPage> queryTracks(LibraryQuery query) async {
    if (failInitialLoad && !_failedInitialQuery) {
      _failedInitialQuery = true;
      throw StateError('temporary scan failure');
    }
    final filtered = tracks.where((track) {
      if (query.album != null && (track.album ?? '') != query.album) {
        return false;
      }
      if (query.artist != null && (track.artist ?? '') != query.artist) {
        return false;
      }
      return true;
    }).toList();
    return LibraryPage(items: filtered, totalCount: filtered.length);
  }

  @override
  Future<LibraryGroupPage> queryGroups(LibraryGroupQuery query) async {
    final counts = <String, int>{};
    for (final track in tracks) {
      final value = switch (query.kind) {
        LibraryGroupKind.album => track.album ?? '',
        LibraryGroupKind.artist => track.artist ?? '',
      };
      if (!value.toLowerCase().contains(query.search.toLowerCase())) continue;
      counts.update(value, (count) => count + 1, ifAbsent: () => 1);
    }
    final groups = counts.entries
        .map(
          (entry) => LibraryGroup(
            kind: query.kind,
            value: entry.key,
            trackCount: entry.value,
          ),
        )
        .toList();
    return LibraryGroupPage(items: groups, totalCount: groups.length);
  }

  @override
  Future<List<LibraryTrack>> resolveTrackPaths(Iterable<String> paths) async =>
      tracks.where((track) => paths.contains(track.sourcePath)).toList();

  @override
  Future<LibraryPlaybackQueueDescriptor> createPlaybackQueue(
    LibraryQuery query,
  ) async => LibraryPlaybackQueueDescriptor(id: 'test', length: tracks.length);

  @override
  Future<LibraryTrack?> loadPlaybackQueueTrack(
    String queueId,
    int index,
  ) async => index >= 0 && index < tracks.length ? tracks[index] : null;

  @override
  Future<void> deletePlaybackQueue(String queueId) async {}

  @override
  Future<LibraryTrack?> loadTrackById(int id) async =>
      id >= 0 && id < tracks.length ? tracks[id] : null;

  @override
  Future<List<int>?> loadArtwork(int trackId) async => null;

  @override
  Future<List<LibraryTrack>> scanFallbackLocal(String path) =>
      scanAndCache(path);
}
