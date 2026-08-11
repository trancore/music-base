import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:music_base/app/app.dart';
import 'package:music_base/app/library_providers.dart';
import 'package:music_base/app/providers.dart';
import 'package:music_base/domain/library/library_repository.dart';
import 'package:music_base/domain/library/library_track.dart';
import 'package:music_base/domain/library/smb_source.dart';

void main() {
  testWidgets('renders the Music Base library shell', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          libraryRepositoryProvider.overrideWithValue(
            const _FakeLibraryRepository(),
          ),
        ],
        child: const MusicBaseApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Music Base'), findsOneWidget);
    expect(find.text('Music library'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
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
            const _FakeLibraryRepository(
              tracks: [
                LibraryTrack(
                  sourcePath: '/Music/Artist/Album/01 - Song.flac',
                  title: 'Song',
                  artist: 'Artist',
                  album: 'Album',
                ),
              ],
            ),
          ),
        ],
        child: const MusicBaseApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Artist · Album'), findsOneWidget);
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
            const _FakeLibraryRepository(
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
            const _FakeLibraryRepository(
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

    expect(find.text('Playback visualizer'), findsOneWidget);
  });
}

class _FakeLibraryRepository implements LibraryRepository {
  const _FakeLibraryRepository({
    this.tracks = const [],
    this.failInitialLoad = false,
  });

  final List<LibraryTrack> tracks;
  final bool failInitialLoad;

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
}
