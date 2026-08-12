abstract interface class RealtimeSpectrumService {
  Stream<List<double>> get spectrumStream;

  Future<void> start({int? audioSessionId});

  Future<void> stop();
}
