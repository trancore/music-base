import 'package:flutter_test/flutter_test.dart';

import 'package:music_base/data/playback/audio_decoder_analysis_service.dart';
import 'package:music_base/domain/library/library_track.dart';

void main() {
  test('does not analyze SMB tracks', () async {
    const service = AudioDecoderAnalysisService();

    await expectLater(
      service.waveformFor(
        const LibraryTrack(sourcePath: 'smb://server/share/song.flac'),
      ),
      throwsUnsupportedError,
    );
  });
}
