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

    await notifier.importPlaylist('Imported playlist', ['Z:/Music/one.flac']);
    expect(repository.playlists.last.type, PlaylistType.manual);
    expect(repository.playlists.last.trackPaths, ['Z:/Music/one.flac']);
  });
}

class _FakePlaylistRepository implements PlaylistRepository {
  final List<Playlist> playlists = [];

  @override
  Future<List<Playlist>> loadAll() async => List.unmodifiable(playlists);

  @override
  Future<void> save(Playlist playlist) async {
    playlists.removeWhere((entry) => entry.id == playlist.id);
    playlists.add(playlist);
  }

  @override
  Future<void> delete(String id) async {
    playlists.removeWhere((entry) => entry.id == id);
  }
}
