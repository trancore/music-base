import 'package:flutter_test/flutter_test.dart';
import 'package:music_base/domain/library/library_audio_formats.dart';

void main() {
  test('recognizes supported library extensions', () {
    expect(isSupportedLibraryExtension('/music/track.flac'), isTrue);
    expect(isSupportedLibraryExtension('/music/track.MP3'), isTrue);
    expect(isSupportedLibraryExtension('/music/track.ogg'), isTrue);
    expect(isSupportedLibraryExtension('/music/track.3GP'), isTrue);
    expect(isSupportedLibraryExtension('/music/track.mp4'), isTrue);
    expect(isSupportedLibraryExtension('/music/track.wav'), isFalse);
  });
}
