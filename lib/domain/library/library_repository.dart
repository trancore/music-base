import 'library_track.dart';
import 'library_query.dart';
import 'smb_source.dart';

abstract interface class LibraryRepository {
  Future<String?> loadSourcePath();

  Future<String?> loadLastLocalSourcePath();

  Future<void> saveSourcePath(String path);

  Future<List<LibraryTrack>> loadTracks();

  Future<LibraryPage> queryTracks(LibraryQuery query);

  Future<LibraryGroupPage> queryGroups(LibraryGroupQuery query);

  Future<List<LibraryTrack>> resolveTrackPaths(Iterable<String> paths);

  Future<LibraryPlaybackQueueDescriptor> createPlaybackQueue(
    LibraryQuery query,
  );

  Future<LibraryTrack?> loadPlaybackQueueTrack(String queueId, int index);

  Future<void> deletePlaybackQueue(String queueId);

  Future<LibraryTrack?> loadTrackById(int id);

  Future<List<int>?> loadArtwork(int trackId);

  Future<List<LibraryTrack>> scanAndCache(String path);

  Future<List<LibraryTrack>> scanFallbackLocal(String path);

  Future<List<LibraryTrack>> scanSmbAndCache(SmbSource source, String password);
}
