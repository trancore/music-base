import 'package:flutter/services.dart';

import '../../domain/playback/realtime_spectrum_service.dart';
import '../../domain/playback/spectrum_analyzer.dart';

class WindowsRealtimeSpectrumService implements RealtimeSpectrumService {
  WindowsRealtimeSpectrumService()
    : _events = const EventChannel('music_base/windows_spectrum'),
      _methods = const MethodChannel('music_base/windows_spectrum/control');

  final EventChannel _events;
  final MethodChannel _methods;

  @override
  Stream<List<double>> get spectrumStream =>
      _events.receiveBroadcastStream().map(
        (event) => calculateSpectrum(
          (event as List<dynamic>)
              .map((value) => (value as num).toDouble())
              .toList(),
        ),
      );

  @override
  Future<void> start({required int audioSessionId}) =>
      _methods.invokeMethod<void>('start');

  @override
  Future<void> stop() => _methods.invokeMethod<void>('stop');
}
