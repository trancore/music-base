import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_base/data/playback/playback_audio_source_resolver.dart';
import 'package:music_base/domain/library/library_track.dart';
import 'package:music_base/domain/library/smb_service.dart';

void main() {
  test('resolves a local track without requiring an SMB factory', () async {
    final resolver = PlaybackAudioSourceResolver(null);

    final source = await resolver.resolveTrack(
      const LibraryTrack(sourcePath: '/music/song.flac'),
    );

    expect(source, isA<UriAudioSource>());
    expect((source as UriAudioSource).uri, Uri.file('/music/song.flac'));
  });

  test('reports an unconfigured SMB source as a connection error', () async {
    final resolver = PlaybackAudioSourceResolver(null);

    expect(
      () => resolver.resolveTrack(
        const LibraryTrack(sourcePath: 'smb://server/share/song.flac'),
      ),
      throwsA(isA<SmbConnectionException>()),
    );
  });
}
