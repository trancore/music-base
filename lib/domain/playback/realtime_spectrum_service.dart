abstract interface class RealtimeSpectrumService {
  Stream<List<double>> get spectrumStream;

  Future<void> start({required int audioSessionId});

  Future<void> stop();
}
