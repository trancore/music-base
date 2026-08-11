import 'package:flutter/services.dart';

import '../../domain/playback/realtime_spectrum_service.dart';

class AndroidRealtimeSpectrumService implements RealtimeSpectrumService {
  AndroidRealtimeSpectrumService()
    : _events = const EventChannel('music_base/audio_spectrum');

  final EventChannel _events;
  final MethodChannel _methods = const MethodChannel(
    'music_base/audio_spectrum/control',
  );

  @override
  Stream<List<double>> get spectrumStream =>
      _events.receiveBroadcastStream().map(
        (event) => (event as List<dynamic>)
            .map((value) => (value as num).toDouble().clamp(0.0, 1.0))
            .toList(),
      );

  @override
  Future<void> start({required int audioSessionId}) async {
    await _methods.invokeMethod<void>('start', {
      'audioSessionId': audioSessionId,
    });
  }

  @override
  Future<void> stop() => _methods.invokeMethod<void>('stop');
}
