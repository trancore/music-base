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

    await notifier.create(' Favorites ', [firstTrack]);
    expect(repository.playlists.single.name, 'Favorites');
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
