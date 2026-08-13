import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../domain/radio/internet_radio_station.dart';
import '../../domain/radio/radio_stream_tester.dart';

class JustAudioRadioStreamTester implements RadioStreamTester {
  const JustAudioRadioStreamTester();

  @override
  Future<void> test(InternetRadioStation station) async {
    final player = AudioPlayer();
    try {
      final mediaItem = MediaItem(
        id: station.id,
        title: station.name,
        artist: station.genre,
        album: station.description,
        isLive: true,
      );
      await player
          .setAudioSource(
            AudioSource.uri(Uri.parse(station.streamUrl), tag: mediaItem),
          )
          .timeout(const Duration(seconds: 10));
    } finally {
      await player.dispose();
    }
  }
}
