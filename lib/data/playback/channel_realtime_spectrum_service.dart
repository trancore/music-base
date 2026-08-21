import 'package:flutter/foundation.dart';
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
  @protected
  final List<double> pendingSamples = [];

  /// Converts one native event payload into zero or more spectrum frames.
  @protected
  Iterable<List<double>> expandEvent(List<double> values) {
    if (values.isEmpty) return const [];
    pendingSamples.addAll(values);
    if (pendingSamples.length < maxSpectrumSamples) return const [];
    final frame = pendingSamples.sublist(0, maxSpectrumSamples);
    pendingSamples.removeRange(0, maxSpectrumSamples);
    return [calculateLogSpectrum(frame)];
  }

  @override
  Stream<List<double>> get spectrumStream =>
      _events.receiveBroadcastStream().expand((event) {
        final values = (event as List<dynamic>)
            .map((value) => (value as num).toDouble())
            .toList();
        return expandEvent(values);
      });

  @override
  Future<void> start({int? audioSessionId}) {
    if (audioSessionId != null) {
      return _methods.invokeMethod<void>('start', {
        'audioSessionId': audioSessionId,
      });
    }
    return _methods.invokeMethod<void>('start');
  }

  @override
  Future<void> stop() async {
    pendingSamples.clear();
    await _methods.invokeMethod<void>('stop');
  }
}
