import '../../domain/playback/spectrum_analyzer.dart';
import 'channel_realtime_spectrum_service.dart';

/// Receives PCM or FFT frames from the Android Visualizer and converts them
/// into the same normalized spectrum shape used by the desktop implementations.
class AndroidRealtimeSpectrumService extends ChannelRealtimeSpectrumService {
  AndroidRealtimeSpectrumService()
    : super(channelName: 'music_base/audio_spectrum');

  @override
  Iterable<List<double>> expandEvent(List<double> values) {
    if (values.isEmpty) return const [];
    // Native FFT fallback emits a small fixed number of magnitude bands.
    if (values.length <= 64) {
      return [mapLinearSpectrumToLogBands(values)];
    }
    return super.expandEvent(values);
  }
}
