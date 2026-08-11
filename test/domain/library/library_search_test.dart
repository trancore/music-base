import 'package:flutter_test/flutter_test.dart';

import 'package:music_base/domain/library/library_search.dart';
import 'package:music_base/domain/library/library_track.dart';

void main() {
  final tracks = [
    const LibraryTrack(
      sourcePath: '/Music/Artist/Album/01.flac',
      title: 'First Song',
      artist: 'Artist',
      album: 'Album',
    ),
    const LibraryTrack(
      sourcePath: '/Music/Other/Collection/02.mp3',
      title: 'Second Song',
      artist: 'Other Artist',
      album: 'Collection',
    ),
  ];

  test('returns all tracks for an empty query', () {
    expect(filterLibraryTracks(tracks, '  '), tracks);
  });

  test('matches title, artist, album, and source path case-insensitively', () {
    expect(filterLibraryTracks(tracks, 'FIRST').single.title, 'First Song');
    expect(
      filterLibraryTracks(tracks, 'other artist').single.title,
      'Second Song',
    );
    expect(
      filterLibraryTracks(tracks, 'collection').single.title,
      'Second Song',
    );
    expect(filterLibraryTracks(tracks, '01.FLAC').single.title, 'First Song');
  });

  test('returns no tracks when there is no match', () {
    expect(filterLibraryTracks(tracks, 'missing'), isEmpty);
  });
}
