import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/playlist/shared_preferences_playlist_repository.dart';
import '../domain/library/library_track.dart';
import '../domain/playlist/playlist.dart';
import '../domain/playlist/playlist_repository.dart';
import 'providers.dart';

final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  return SharedPreferencesPlaylistRepository(
    preferences: ref.watch(sharedPreferencesProvider),
  );
});

final playlistProvider =
    AsyncNotifierProvider<PlaylistNotifier, List<Playlist>>(
      PlaylistNotifier.new,
    );

class PlaylistNotifier extends AsyncNotifier<List<Playlist>> {
  late final PlaylistRepository _repository;

  @override
  Future<List<Playlist>> build() {
    _repository = ref.watch(playlistRepositoryProvider);
    return _repository.loadAll();
  }

  Future<void> create(String name, List<LibraryTrack> tracks) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || tracks.isEmpty) return;
    final playlist = Playlist(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: trimmedName,
      trackPaths: tracks
          .map((track) => track.sourcePath)
          .toList(growable: false),
    );
    await _repository.save(playlist);
    state = AsyncData(await _repository.loadAll());
  }

  Future<void> updatePlaylist(
    String id,
    String name,
    List<LibraryTrack> tracks,
  ) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || tracks.isEmpty) return;
    final playlist = Playlist(
      id: id,
      name: trimmedName,
      trackPaths: tracks
          .map((track) => track.sourcePath)
          .toList(growable: false),
    );
    await _repository.save(playlist);
    state = AsyncData(await _repository.loadAll());
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    state = AsyncData(await _repository.loadAll());
  }
}
