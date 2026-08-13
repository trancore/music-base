import 'package:flutter_test/flutter_test.dart';

import 'package:music_base/data/playback/smb_audio_source.dart';

void main() {
  test('parses an SMB source path into connection and file components', () {
    final location = SmbRemoteLocation.parse(
      'smb://server/share/Albums/Artist/01%20Song.flac',
    );

    expect(location?.host, 'server');
    expect(location?.share, 'share');
    expect(location?.path, 'Albums/Artist/01 Song.flac');
  });

  test('parses a file stored directly in the share root', () {
    final location = SmbRemoteLocation.parse('smb://server/share/song.mp3');

    expect(location?.host, 'server');
    expect(location?.share, 'share');
    expect(location?.path, 'song.mp3');
  });

  test('rejects non-SMB and incomplete paths', () {
    expect(SmbRemoteLocation.parse('D:/Music/song.flac'), isNull);
    expect(SmbRemoteLocation.parse('smb://server/share'), isNull);
  });
}
