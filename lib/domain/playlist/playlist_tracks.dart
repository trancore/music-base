import '../library/library_search.dart';
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
    for (final track in libraryTracks) _comparisonPath(track.sourcePath): track,
  };
  return playlist.trackPaths
      .map((path) => tracksByPath[_comparisonPath(path)])
      .whereType<LibraryTrack>()
      .toList(growable: false);
}

String _comparisonPath(String value) {
  final normalized = value.trim().replaceAll('\\', '/');
  final isWindowsPath = RegExp(r'^[a-zA-Z]:/').hasMatch(normalized);
  return isWindowsPath ? normalized.toLowerCase() : normalized;
}
