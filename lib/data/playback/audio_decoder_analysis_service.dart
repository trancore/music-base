import 'package:audio_decoder/audio_decoder.dart';

import '../../domain/library/library_track.dart';
import '../../domain/playback/audio_analysis_service.dart';

class AudioDecoderAnalysisService implements AudioAnalysisService {
  const AudioDecoderAnalysisService();

  @override
  Future<List<double>> waveformFor(LibraryTrack track) async {
    if (track.isRemote) {
      throw UnsupportedError('Waveform analysis is not available for SMB.');
    }

    return AudioDecoder.getWaveform(
      track.sourcePath,
      numberOfSamples: 32,
      normalization: WaveformNormalization.absolute,
    );
  }
}
