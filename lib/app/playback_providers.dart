import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../data/playback/just_audio_playback_service.dart';
import '../data/playback/smb_audio_source.dart';
import '../data/playback/audio_decoder_analysis_service.dart';
import '../data/playback/android_realtime_spectrum_service.dart';
import '../data/playback/noop_realtime_spectrum_service.dart';
import '../data/playback/windows_realtime_spectrum_service.dart';
import '../data/playback/macos_realtime_spectrum_service.dart';
import '../domain/playback/audio_analysis_service.dart';
import '../domain/playback/realtime_spectrum_service.dart';
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

final realtimeSpectrumServiceProvider = Provider<RealtimeSpectrumService>((
  ref,
) {
  if (defaultTargetPlatform == TargetPlatform.android) {
    final service = AndroidRealtimeSpectrumService();
    ref.onDispose(service.stop);
    return service;
  }
  if (defaultTargetPlatform == TargetPlatform.windows) {
    final service = WindowsRealtimeSpectrumService();
    ref.onDispose(service.stop);
    return service;
  }
  if (defaultTargetPlatform == TargetPlatform.macOS) {
    final service = MacosRealtimeSpectrumService();
    ref.onDispose(service.stop);
    return service;
  }
  return const NoopRealtimeSpectrumService();
});
