import '../../domain/playback/realtime_spectrum_service.dart';

class NoopRealtimeSpectrumService implements RealtimeSpectrumService {
  const NoopRealtimeSpectrumService();

  @override
  Stream<List<double>> get spectrumStream => const Stream.empty();

  @override
  Future<void> start({int? audioSessionId}) async {}

  @override
  Future<void> stop() async {}
}
