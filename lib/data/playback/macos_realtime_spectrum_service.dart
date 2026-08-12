import 'package:flutter/services.dart';

import '../../domain/playback/realtime_spectrum_service.dart';
import '../../domain/playback/spectrum_analyzer.dart';

/// Receives PCM frames from the macOS Runner and converts them into the same
/// normalized spectrum shape used by the Android and Windows implementations.
class MacosRealtimeSpectrumService implements RealtimeSpectrumService {
  MacosRealtimeSpectrumService()
    : _events = const EventChannel('music_base/macos_spectrum'),
      _methods = const MethodChannel('music_base/macos_spectrum/control');

  final EventChannel _events;
  final MethodChannel _methods;
  final List<double> _pendingSamples = [];
  @override
  Stream<List<double>> get spectrumStream =>
      _events.receiveBroadcastStream().expand((event) {
        _pendingSamples.addAll(
          (event as List<dynamic>).map((value) => (value as num).toDouble()),
        );
        if (_pendingSamples.length < maxSpectrumSamples) return const [];
        final frame = _pendingSamples.sublist(0, maxSpectrumSamples);
        _pendingSamples.removeRange(0, maxSpectrumSamples);
        return [calculateLogSpectrum(frame)];
      });

  @override
  Future<void> start({int? audioSessionId}) async {
    await _methods.invokeMethod<void>('start');
  }

  @override
  Future<void> stop() async {
    _pendingSamples.clear();
    await _methods.invokeMethod<void>('stop');
  }
}
