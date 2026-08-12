import 'dart:math' as math;

const maxSpectrumSamples = 2048;
const maxSpectrumBands = 128;
const defaultSpectrumBands = 128;

/// Converts a PCM window into logarithmically spaced, dB-normalized bands.
///
/// This is the format used by the desktop realtime spectrum adapters. The
/// input is mono PCM normalized to -1..1. A Hann window reduces leakage, the
/// FFT provides frequency bins, and each output band averages the bins between
/// 20 Hz and Nyquist on a logarithmic scale.
List<double> calculateLogSpectrum(
  List<double> samples, {
  int sampleRate = 44100,
  int bandCount = defaultSpectrumBands,
}) {
  if (samples.isEmpty) return const [];
  if (bandCount < 1 || bandCount > maxSpectrumBands) {
    throw RangeError.range(bandCount, 1, maxSpectrumBands, 'bandCount');
  }

  final inputCount = math.min(samples.length, maxSpectrumSamples);
  var fftSize = 1;
  while (fftSize < inputCount) {
    fftSize <<= 1;
  }
  final real = List<double>.filled(fftSize, 0);
  final imaginary = List<double>.filled(fftSize, 0);
  for (var index = 0; index < inputCount; index++) {
    final window = inputCount == 1
        ? 1.0
        : 0.5 * (1 - math.cos(2 * math.pi * index / (inputCount - 1)));
    real[index] = samples[index].clamp(-1.0, 1.0) * window;
  }
  _fft(real, imaginary);

  final nyquist = sampleRate / 2;
  final lowFrequency = 20.0;
  final highFrequency = math.min(nyquist, 20000.0);
  final bandEdges = [
    for (var index = 0; index <= bandCount; index++)
      lowFrequency * math.pow(highFrequency / lowFrequency, index / bandCount),
  ];
  final output = List<double>.filled(bandCount, 0);
  for (var band = 0; band < bandCount; band++) {
    final firstBin = math.max(
      1,
      (bandEdges[band] * fftSize / sampleRate).floor(),
    );
    final lastBin = math.min(
      fftSize ~/ 2,
      (bandEdges[band + 1] * fftSize / sampleRate).ceil(),
    );
    var energy = 0.0;
    var count = 0;
    for (var bin = firstBin; bin <= lastBin; bin++) {
      final magnitude = math.sqrt(
        real[bin] * real[bin] + imaginary[bin] * imaginary[bin],
      );
      energy += magnitude * magnitude;
      count++;
    }
    if (count == 0) continue;
    final amplitude = math.sqrt(energy / count) / (fftSize * 0.5);
    final decibels = 20 * (math.log(math.max(amplitude, 1e-7)) / math.ln10);
    output[band] = ((decibels + 72) / 72).clamp(0.0, 1.0);
  }
  return output;
}

/// Re-bands an already calculated linear FFT magnitude array into the same
/// logarithmic display shape used by the PCM analyzer.
List<double> mapLinearSpectrumToLogBands(
  List<double> magnitudes, {
  int bandCount = defaultSpectrumBands,
}) {
  if (magnitudes.isEmpty) return const [];
  if (bandCount < 1 || bandCount > maxSpectrumBands) {
    throw RangeError.range(bandCount, 1, maxSpectrumBands, 'bandCount');
  }
  final output = List<double>.filled(bandCount, 0);
  for (var band = 0; band < bandCount; band++) {
    final start = math.pow(magnitudes.length, band / bandCount).floor();
    final end = math.max(
      start + 1,
      math.pow(magnitudes.length, (band + 1) / bandCount).ceil(),
    );
    var total = 0.0;
    var count = 0;
    for (var index = start; index < end && index < magnitudes.length; index++) {
      total += magnitudes[index].clamp(0.0, 1.0);
      count++;
    }
    output[band] = count == 0 ? 0 : total / count;
  }
  return output;
}

void _fft(List<double> real, List<double> imaginary) {
  final size = real.length;
  for (var reversed = 0, index = 1; index < size; index++) {
    var bit = size >> 1;
    for (; reversed & bit != 0; bit >>= 1) {
      reversed ^= bit;
    }
    reversed ^= bit;
    if (index < reversed) {
      final realValue = real[index];
      real[index] = real[reversed];
      real[reversed] = realValue;
      final imaginaryValue = imaginary[index];
      imaginary[index] = imaginary[reversed];
      imaginary[reversed] = imaginaryValue;
    }
  }
  for (var length = 2; length <= size; length <<= 1) {
    final angle = -2 * math.pi / length;
    final phaseReal = math.cos(angle);
    final phaseImaginary = math.sin(angle);
    for (var start = 0; start < size; start += length) {
      var currentReal = 1.0;
      var currentImaginary = 0.0;
      final half = length ~/ 2;
      for (var offset = 0; offset < half; offset++) {
        final even = start + offset;
        final odd = even + half;
        final productReal =
            real[odd] * currentReal - imaginary[odd] * currentImaginary;
        final productImaginary =
            real[odd] * currentImaginary + imaginary[odd] * currentReal;
        final evenReal = real[even];
        final evenImaginary = imaginary[even];
        real[even] = evenReal + productReal;
        imaginary[even] = evenImaginary + productImaginary;
        real[odd] = evenReal - productReal;
        imaginary[odd] = evenImaginary - productImaginary;
        final nextReal =
            currentReal * phaseReal - currentImaginary * phaseImaginary;
        currentImaginary =
            currentReal * phaseImaginary + currentImaginary * phaseReal;
        currentReal = nextReal;
      }
    }
  }
}

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
