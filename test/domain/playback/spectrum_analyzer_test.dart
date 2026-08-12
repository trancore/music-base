import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:music_base/domain/playback/spectrum_analyzer.dart';

void main() {
  test('finds the dominant frequency bin in a PCM window', () {
    const sampleCount = 256;
    const dominantBin = 12;
    final samples = [
      for (var index = 0; index < sampleCount; index++)
        math.sin(2 * math.pi * dominantBin * index / sampleCount),
    ];

    final spectrum = calculateSpectrum(samples, bandCount: 32);
    final peakBand = spectrum.indexOf(spectrum.reduce(math.max));

    expect(peakBand, dominantBin);
    expect(spectrum[peakBand], closeTo(1, 0.001));
  });

  test('returns silence for a zero-valued window', () {
    expect(
      calculateSpectrum(List<double>.filled(256, 0)),
      everyElement(equals(0)),
    );
  });

  test('bounds the work for oversized input', () {
    final spectrum = calculateSpectrum(
      List<double>.filled(maxSpectrumSamples + 1, 0.5),
      bandCount: maxSpectrumBands,
    );

    expect(spectrum, hasLength(maxSpectrumBands));
  });

  test('rejects an invalid band count', () {
    expect(() => calculateSpectrum([0, 1], bandCount: 0), throwsRangeError);
    expect(
      () => calculateSpectrum([0, 1], bandCount: maxSpectrumBands + 1),
      throwsRangeError,
    );
  });
}
