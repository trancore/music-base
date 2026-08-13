import 'package:flutter/services.dart';

import '../../domain/playback/realtime_spectrum_service.dart';
import '../../domain/playback/spectrum_analyzer.dart';

/// Shared EventChannel adapter for desktop process-loopback implementations.
abstract class ChannelRealtimeSpectrumService
    implements RealtimeSpectrumService {
  ChannelRealtimeSpectrumService({required String channelName})
    : _events = EventChannel(channelName),
      _methods = MethodChannel('$channelName/control');

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
  Future<void> start({int? audioSessionId}) =>
      _methods.invokeMethod<void>('start');

  @override
  Future<void> stop() async {
    _pendingSamples.clear();
    await _methods.invokeMethod<void>('stop');
  }
}
