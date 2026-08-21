import 'package:flutter_test/flutter_test.dart';
import 'package:music_base/data/playback/android_realtime_spectrum_service.dart';
import 'package:music_base/domain/playback/spectrum_analyzer.dart';

void main() {
  test('maps native FFT fallback frames directly to log bands', () {
    final service = AndroidRealtimeSpectrumService();
    final frames = service.expandEvent(
      List<double>.generate(32, (index) {
        return index == 8 ? 1.0 : 0.1;
      }),
    );

    final spectrum = frames.single;
    expect(spectrum, hasLength(defaultSpectrumBands));
    expect(spectrum.reduce((a, b) => a > b ? a : b), greaterThan(0.2));
  });
}
