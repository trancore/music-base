import 'dart:math' as math;

const maxSpectrumSamples = 2048;
const maxSpectrumBands = 128;

/// Calculates normalized magnitude bands from one PCM sample window.
///
/// The caller supplies mono samples normalized to -1..1. A bounded, pure-Dart
/// implementation keeps the calculation reusable by future platform PCM
/// adapters without coupling the domain layer to an audio engine.
List<double> calculateSpectrum(List<double> samples, {int bandCount = 32}) {
  if (samples.isEmpty) return const [];
  if (bandCount < 1 || bandCount > maxSpectrumBands) {
    throw RangeError.range(bandCount, 1, maxSpectrumBands, 'bandCount');
  }

  final sampleCount = math.min(samples.length, maxSpectrumSamples);
  final availableBands = sampleCount ~/ 2;
  final outputCount = math.min(bandCount, availableBands);
  if (outputCount == 0) return const [];

  final magnitudes = List<double>.filled(outputCount, 0);
  for (var band = 0; band < outputCount; band++) {
    var real = 0.0;
    var imaginary = 0.0;
    for (var sampleIndex = 0; sampleIndex < sampleCount; sampleIndex++) {
      final window =
          0.5 * (1 - math.cos(2 * math.pi * sampleIndex / (sampleCount - 1)));
      final angle = 2 * math.pi * band * sampleIndex / sampleCount;
      final sample = samples[sampleIndex].clamp(-1.0, 1.0) * window;
      real += sample * math.cos(angle);
      imaginary -= sample * math.sin(angle);
    }
    magnitudes[band] = math.sqrt(real * real + imaginary * imaginary);
  }

  final peak = magnitudes.reduce(math.max);
  if (peak == 0) return List<double>.filled(outputCount, 0);
  return magnitudes.map((value) => (value / peak).clamp(0.0, 1.0)).toList();
}
