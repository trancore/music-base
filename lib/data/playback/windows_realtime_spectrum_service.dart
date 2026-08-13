import 'channel_realtime_spectrum_service.dart';

class WindowsRealtimeSpectrumService extends ChannelRealtimeSpectrumService {
  WindowsRealtimeSpectrumService()
    : super(channelName: 'music_base/windows_spectrum');
}
