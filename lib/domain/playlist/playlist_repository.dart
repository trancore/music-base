import 'playlist.dart';

abstract interface class PlaylistRepository {
  Future<List<Playlist>> loadAll();

  Future<void> save(Playlist playlist);

  Future<void> delete(String id);
}
