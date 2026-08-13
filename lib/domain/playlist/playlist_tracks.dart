import '../library/library_search.dart';
import '../library/library_path_normalizer.dart';
import '../library/library_track.dart';
import 'playlist.dart';

List<LibraryTrack> resolvePlaylistTracks(
  Playlist playlist,
  Iterable<LibraryTrack> libraryTracks,
) {
  if (playlist.isAutomatic) {
    return filterLibraryTracks(libraryTracks, playlist.query ?? '');
  }

  final tracksByPath = <String, LibraryTrack>{
    for (final track in libraryTracks)
      normalizeLibraryComparisonPath(track.sourcePath): track,
  };
  return playlist.trackPaths
      .map((path) => tracksByPath[normalizeLibraryComparisonPath(path)])
      .whereType<LibraryTrack>()
      .toList(growable: false);
}
