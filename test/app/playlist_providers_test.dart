import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:music_base/app/playlist_providers.dart';
import 'package:music_base/domain/library/library_track.dart';
import 'package:music_base/domain/playlist/playlist.dart';
import 'package:music_base/domain/playlist/playlist_repository.dart';

void main() {
  test('creates and updates a playlist with the selected tracks', () async {
    final repository = _FakePlaylistRepository();
    final container = ProviderContainer(
      overrides: [playlistRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(playlistProvider.future);
    final notifier = container.read(playlistProvider.notifier);
    const firstTrack = LibraryTrack(sourcePath: '/Music/first.flac');
    const secondTrack = LibraryTrack(sourcePath: '/Music/second.mp3');

    await notifier.create(' Sample playlist ', [firstTrack]);
    expect(repository.playlists.single.name, 'Sample playlist');
    expect(repository.playlists.single.trackPaths, ['/Music/first.flac']);

    await notifier.updatePlaylist(
      repository.playlists.single.id,
      'Updated favorites',
      [firstTrack, secondTrack],
    );
    expect(repository.playlists.single.name, 'Updated favorites');
    expect(repository.playlists.single.trackPaths, [
      '/Music/first.flac',
      '/Music/second.mp3',
    ]);
  });

  test('creates automatic and imported playlists', () async {
    final repository = _FakePlaylistRepository();
    final container = ProviderContainer(
      overrides: [playlistRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(playlistProvider.future);
    final notifier = container.read(playlistProvider.notifier);
    await notifier.createAutomatic(' Matching tracks ', ' sample artist ');
    expect(repository.playlists.single.type, PlaylistType.automatic);
    expect(repository.playlists.single.query, 'sample artist');

    await notifier.updateAutomatic(
      repository.playlists.single.id,
      'Updated matches',
      'sample album',
    );
    expect(repository.playlists.single.name, 'Updated matches');
    expect(repository.playlists.single.query, 'sample album');

    await notifier.importPlaylist('Imported playlist', [
      'X:/SampleLibrary/one.flac',
    ]);
    expect(repository.playlists.last.type, PlaylistType.manual);
    expect(repository.playlists.last.trackPaths, ['X:/SampleLibrary/one.flac']);
  });

  test(
    'creates nested folders, moves playlists, and rejects non-empty deletion',
    () async {
      final repository = _FakePlaylistRepository();
      final container = ProviderContainer(
        overrides: [playlistRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      await container.read(playlistProvider.future);
      final notifier = container.read(playlistProvider.notifier);

      await notifier.createFolder('Parent');
      final parent = repository.folders.single;
      await notifier.createFolder('Child', parentFolderId: parent.id);
      final child = repository.folders.singleWhere(
        (entry) => entry.id != parent.id,
      );
      await notifier.importPlaylist('Nested playlist', [
        '/Music/one.flac',
      ], parentFolderId: child.id);

      expect(repository.playlists.single.parentFolderId, child.id);
      expect(await notifier.deleteFolder(child.id), isFalse);
      await notifier.movePlaylist(repository.playlists.single.id, null);
      expect(repository.playlists.single.parentFolderId, isNull);
      expect(await notifier.deleteFolder(child.id), isTrue);
    },
  );

  test('reorders a playlist downward within the same level', () async {
    final repository = _FakePlaylistRepository()
      ..playlists.addAll(const [
        Playlist(id: 'first', name: 'First', sortOrder: 0),
        Playlist(id: 'second', name: 'Second', sortOrder: 1),
        Playlist(id: 'third', name: 'Third', sortOrder: 2),
      ]);
    final container = ProviderContainer(
      overrides: [playlistRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(playlistProvider.future);

    await container
        .read(playlistProvider.notifier)
        .movePlaylist('first', null, targetIndex: 2);

    final ordered = repository.playlists.toList()
      ..sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
    expect(ordered.map((entry) => entry.id), ['second', 'first', 'third']);
  });

  test('normalizes the source level after moving a playlist', () async {
    final repository = _FakePlaylistRepository()
      ..folders.addAll(const [
        PlaylistFolder(id: 'source', name: 'Source'),
        PlaylistFolder(id: 'target', name: 'Target'),
      ])
      ..playlists.addAll(const [
        Playlist(
          id: 'first',
          name: 'First',
          parentFolderId: 'source',
          sortOrder: 0,
        ),
        Playlist(
          id: 'second',
          name: 'Second',
          parentFolderId: 'source',
          sortOrder: 1,
        ),
      ]);
    final container = ProviderContainer(
      overrides: [playlistRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(playlistProvider.future);
    final notifier = container.read(playlistProvider.notifier);

    await notifier.movePlaylist('first', 'target');
    await notifier.importPlaylist('Third', [
      '/sample-library/third.flac',
    ], parentFolderId: 'source');

    final source =
        repository.playlists
            .where((entry) => entry.parentFolderId == 'source')
            .toList()
          ..sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
    expect(source.map((entry) => entry.name), ['Second', 'Third']);
    expect(source.map((entry) => entry.sortOrder), [0, 1]);
  });

  test('normalizes folder order after moving and deleting siblings', () async {
    final repository = _FakePlaylistRepository()
      ..folders.addAll(const [
        PlaylistFolder(id: 'first', name: 'First', sortOrder: 0),
        PlaylistFolder(id: 'second', name: 'Second', sortOrder: 1),
        PlaylistFolder(id: 'target', name: 'Target', sortOrder: 2),
      ]);
    final container = ProviderContainer(
      overrides: [playlistRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(playlistProvider.future);
    final notifier = container.read(playlistProvider.notifier);

    await notifier.updateFolder('first', 'First', parentFolderId: 'target');
    expect(
      repository.folders.singleWhere((entry) => entry.id == 'second').sortOrder,
      0,
    );
    expect(await notifier.deleteFolder('second'), isTrue);
    await notifier.createFolder('Replacement');

    final root =
        repository.folders
            .where((entry) => entry.parentFolderId == null)
            .toList()
          ..sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
    expect(root.map((entry) => entry.sortOrder), [0, 1]);
  });
}

class _FakePlaylistRepository implements PlaylistRepository {
  final List<Playlist> playlists = [];
  final List<PlaylistFolder> folders = [];

  @override
  Future<List<Playlist>> loadAll() async => List.unmodifiable(playlists);

  @override
  Future<List<PlaylistFolder>> loadFolders() async =>
      List.unmodifiable(folders);

  @override
  Future<void> save(Playlist playlist) async {
    playlists.removeWhere((entry) => entry.id == playlist.id);
    playlists.add(playlist);
  }

  @override
  Future<void> saveAll(List<Playlist> values) async {
    playlists
      ..clear()
      ..addAll(values);
  }

  @override
  Future<void> saveFolder(PlaylistFolder folder) async {
    folders.removeWhere((entry) => entry.id == folder.id);
    folders.add(folder);
  }

  @override
  Future<void> delete(String id) async {
    playlists.removeWhere((entry) => entry.id == id);
  }

  @override
  Future<void> deleteFolder(String id) async {
    folders.removeWhere((entry) => entry.id == id);
  }
}
