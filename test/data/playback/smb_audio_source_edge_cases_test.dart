import 'package:flutter_test/flutter_test.dart';

import 'package:music_base/data/playback/smb_audio_source.dart';

void main() {
  test('preserves encoded path characters when parsing SMB locations', () {
    final location = SmbRemoteLocation.parse(
      'smb://server/share/Album%20Name/Track%231.flac',
    );

    expect(location?.path, 'Album Name/Track#1.flac');
  });

  test('rejects paths without a file component', () {
    expect(SmbRemoteLocation.parse('smb://server/share/'), isNull);
  });
}
