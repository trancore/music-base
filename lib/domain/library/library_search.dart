import 'library_track.dart';

List<LibraryTrack> filterLibraryTracks(
  Iterable<LibraryTrack> tracks,
  String query,
) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) return tracks.toList(growable: false);

  return tracks
      .where((track) {
        final searchableText = [
          track.title,
          track.artist,
          track.album,
          track.sourcePath,
        ].whereType<String>().join(' ').toLowerCase();
        return searchableText.contains(normalizedQuery);
      })
      .toList(growable: false);
}
