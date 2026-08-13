import 'playlist.dart';

abstract interface class PlaylistRepository {
  Future<List<Playlist>> loadAll();

  Future<List<PlaylistFolder>> loadFolders();

  Future<void> save(Playlist playlist);

  Future<void> saveAll(List<Playlist> playlists);

  Future<void> saveFolder(PlaylistFolder folder);

  Future<void> delete(String id);

  Future<void> deleteFolder(String id);
}
