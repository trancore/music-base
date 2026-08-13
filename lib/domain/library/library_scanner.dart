import 'library_track.dart';

abstract interface class LibraryScanner {
  Future<List<LibraryTrack>> scan(
    String rootPath, {
    Map<String, LibraryTrack> cachedTracks = const {},
  });
}
