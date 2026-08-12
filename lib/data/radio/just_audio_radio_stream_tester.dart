import 'package:just_audio/just_audio.dart';

import '../../domain/radio/internet_radio_station.dart';
import '../../domain/radio/radio_stream_tester.dart';

class JustAudioRadioStreamTester implements RadioStreamTester {
  const JustAudioRadioStreamTester();

  @override
  Future<void> test(InternetRadioStation station) async {
    final player = AudioPlayer();
    try {
      await player
          .setAudioSource(AudioSource.uri(Uri.parse(station.streamUrl)))
          .timeout(const Duration(seconds: 10));
    } finally {
      await player.dispose();
    }
  }
}
