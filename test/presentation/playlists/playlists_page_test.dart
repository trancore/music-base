import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_base/app/library_providers.dart';
import 'package:music_base/app/playlist_providers.dart';
import 'package:music_base/domain/library/library_query.dart';
import 'package:music_base/domain/library/library_repository.dart';
import 'package:music_base/domain/library/library_track.dart';
import 'package:music_base/domain/library/smb_source.dart';
import 'package:music_base/domain/playlist/playlist.dart';
import 'package:music_base/domain/playlist/playlist_repository.dart';
import 'package:music_base/presentation/playlists/playlists_page.dart';

void main() {
  testWidgets('renders nested folders and draggable playlists', (tester) async {
    final playlistRepository = _TreePlaylistRepository(
      folders: const [
        PlaylistFolder(id: 'parent', name: 'Parent'),
        PlaylistFolder(id: 'child', name: 'Child', parentFolderId: 'parent'),
      ],
      playlists: const [
        Playlist(
          id: 'playlist',
          name: 'Nested playlist',
          parentFolderId: 'child',
          trackPaths: ['/music/one.flac'],
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playlistRepositoryProvider.overrideWithValue(playlistRepository),
          libraryRepositoryProvider.overrideWithValue(
            const _EmptyLibraryRepository(),
          ),
        ],
        child: const MaterialApp(home: PlaylistsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Import playlist file'), findsOneWidget);
    expect(find.text('Parent'), findsOneWidget);
    expect(find.text('Child'), findsOneWidget);
    expect(find.text('Nested playlist'), findsOneWidget);
    expect(find.byType(Draggable<Playlist>), findsOneWidget);
    expect(find.byType(DragTarget<Playlist>), findsWidgets);
  });

  testWidgets('creates a folder without disposing its field too early', (
    tester,
  ) async {
    final playlistRepository = _TreePlaylistRepository(
      folders: [],
      playlists: [],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playlistRepositoryProvider.overrideWithValue(playlistRepository),
          libraryRepositoryProvider.overrideWithValue(
            const _EmptyLibraryRepository(),
          ),
        ],
        child: const MaterialApp(home: PlaylistsPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Create folder'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Sample folder');
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Sample folder'), findsOneWidget);
  });
}

class _TreePlaylistRepository implements PlaylistRepository {
  _TreePlaylistRepository({required this.playlists, required this.folders});

  final List<Playlist> playlists;
  final List<PlaylistFolder> folders;

  @override
  Future<List<Playlist>> loadAll() async => List.unmodifiable(playlists);
  @override
  Future<List<PlaylistFolder>> loadFolders() async =>
      List.unmodifiable(folders);
  @override
  Future<void> save(Playlist playlist) async {}
  @override
  Future<void> saveAll(List<Playlist> playlists) async {}
  @override
  Future<void> saveFolder(PlaylistFolder folder) async {
    folders.removeWhere((entry) => entry.id == folder.id);
    folders.add(folder);
  }

  @override
  Future<void> delete(String id) async {}
  @override
  Future<void> deleteFolder(String id) async {}
}

class _EmptyLibraryRepository implements LibraryRepository {
  const _EmptyLibraryRepository();

  @override
  Future<String?> loadSourcePath() async => null;
  @override
  Future<String?> loadLastLocalSourcePath() async => null;
  @override
  Future<void> saveSourcePath(String path) async {}
  @override
  Future<List<LibraryTrack>> loadTracks() async => const [];
  @override
  Future<LibraryPage> queryTracks(LibraryQuery query) async =>
      const LibraryPage(items: [], totalCount: 0);
  @override
  Future<LibraryGroupPage> queryGroups(LibraryGroupQuery query) async =>
      const LibraryGroupPage(items: [], totalCount: 0);
  @override
  Future<List<LibraryTrack>> resolveTrackPaths(Iterable<String> paths) async =>
      const [];
  @override
  Future<LibraryPlaybackQueueDescriptor> createPlaybackQueue(
    LibraryQuery query,
  ) async => const LibraryPlaybackQueueDescriptor(id: 'empty', length: 0);
  @override
  Future<LibraryTrack?> loadPlaybackQueueTrack(
    String queueId,
    int index,
  ) async => null;
  @override
  Future<void> deletePlaybackQueue(String queueId) async {}
  @override
  Future<LibraryTrack?> loadTrackById(int id) async => null;
  @override
  Future<List<int>?> loadArtwork(int trackId) async => null;
  @override
  Future<List<LibraryTrack>> scanAndCache(String path) async => const [];
  @override
  Future<List<LibraryTrack>> scanFallbackLocal(String path) async => const [];
  @override
  Future<List<LibraryTrack>> scanSmbAndCache(
    SmbSource source,
    String password,
  ) async => const [];
}
