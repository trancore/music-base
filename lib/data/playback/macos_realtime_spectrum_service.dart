import 'channel_realtime_spectrum_service.dart';

/// Receives PCM frames from the macOS Runner and converts them into the same
/// normalized spectrum shape used by the Android and Windows implementations.
class MacosRealtimeSpectrumService extends ChannelRealtimeSpectrumService {
  MacosRealtimeSpectrumService()
    : super(channelName: 'music_base/macos_spectrum');
}
