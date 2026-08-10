import 'library_track.dart';
import 'smb_source.dart';

abstract interface class LibraryRepository {
  Future<String?> loadSourcePath();

  Future<void> saveSourcePath(String path);

  Future<List<LibraryTrack>> loadTracks();

  Future<List<LibraryTrack>> scanAndCache(String path);

  Future<List<LibraryTrack>> scanSmbAndCache(SmbSource source, String password);
}
