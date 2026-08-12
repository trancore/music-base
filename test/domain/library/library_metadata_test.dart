import 'package:flutter_test/flutter_test.dart';

import 'package:music_base/domain/library/library_metadata.dart';

void main() {
  test('infers title, album, and artist from a local music path', () {
    final metadata = inferLibraryMetadata(
      '/Music/Artist/Album/01 - First Song.flac',
      libraryRoot: '/Music',
    );

    expect(metadata.title, 'First Song');
    expect(metadata.album, 'Album');
    expect(metadata.artist, 'Artist');
  });

  test('infers metadata from an SMB path and supports numbered separators', () {
    final metadata = inferLibraryMetadata(
      'smb://server/share/Artist/Album/02. Second Song.mp3',
    );

    expect(metadata.title, 'Second Song');
    expect(metadata.album, 'Album');
    expect(metadata.artist, 'Artist');
  });

  test('keeps the filename when no track number is present', () {
    final metadata = inferLibraryMetadata('/Music/Album/Song.flac');

    expect(metadata.title, 'Song');
    expect(metadata.album, 'Album');
    expect(metadata.artist, 'Music');
  });
}
