import 'package:flutter_test/flutter_test.dart';

import 'package:music_base/domain/library/library_search.dart';
import 'package:music_base/domain/library/library_track.dart';

void main() {
  const tracks = [
    LibraryTrack(
      sourcePath: 'D:/Music/Blue Album/01 - Sunrise.flac',
      title: 'Sunrise',
      artist: 'The Band',
      album: 'Blue Album',
    ),
    LibraryTrack(
      sourcePath: 'D:/Music/Red Album/01 - Night.mp3',
      title: 'Night',
      artist: 'Another Artist',
      album: 'Red Album',
    ),
  ];

  test('matches title, artist, album, and source path case-insensitively', () {
    expect(filterLibraryTracks(tracks, 'BAND'), hasLength(1));
    expect(filterLibraryTracks(tracks, 'red album'), hasLength(1));
    expect(filterLibraryTracks(tracks, 'sunrise'), hasLength(1));
  });

  test('returns all tracks for an empty query', () {
    expect(filterLibraryTracks(tracks, '  '), tracks);
  });
}
