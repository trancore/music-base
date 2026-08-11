import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../data/playback/just_audio_playback_service.dart';
import '../data/playback/smb_audio_source.dart';
import '../data/playback/audio_decoder_analysis_service.dart';
import '../domain/playback/audio_analysis_service.dart';
import 'smb_providers.dart';

final playbackServiceProvider =
    ChangeNotifierProvider<JustAudioPlaybackService>((ref) {
      return JustAudioPlaybackService(
        AudioPlayer(),
        remoteSourceFactory: SmbPlaybackSourceFactory(
          ref.watch(smbSettingsRepositoryProvider),
        ),
      );
    });

final audioAnalysisServiceProvider = Provider<AudioAnalysisService>((ref) {
  return const AudioDecoderAnalysisService();
});
