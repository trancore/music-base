import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/playback/playback_service.dart';
import '../../domain/playback/audio_analysis_service.dart';
import '../../domain/playback/realtime_spectrum_service.dart';

class PlaybackVisualizer extends StatefulWidget {
  const PlaybackVisualizer({
    required this.snapshot,
    required this.audioAnalysis,
    required this.realtimeSpectrum,
    this.height = 200,
    super.key,
  });

  final PlaybackSnapshot snapshot;
  final AudioAnalysisService audioAnalysis;
  final RealtimeSpectrumService realtimeSpectrum;
  final double height;

  @override
  State<PlaybackVisualizer> createState() => _PlaybackVisualizerState();
}

class _PlaybackVisualizerState extends State<PlaybackVisualizer>
    with SingleTickerProviderStateMixin {
  List<double>? _waveform;
  List<double>? _smoothedSpectrum;
  String? _sourcePath;
  int? _sessionId;
  StreamSubscription<List<double>>? _spectrumSubscription;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _spectrumSubscription = widget.realtimeSpectrum.spectrumStream.listen((
      spectrum,
    ) {
      if (!mounted) return;
      final previous = _smoothedSpectrum;
      final smoothed = [
        for (var index = 0; index < spectrum.length; index++)
          previous == null || previous.length != spectrum.length
              ? spectrum[index]
              : spectrum[index] >= previous[index]
              ? previous[index] * 0.35 + spectrum[index] * 0.65
              : previous[index] * 0.88 + spectrum[index] * 0.12,
      ];
      setState(() {
        _smoothedSpectrum = smoothed;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _spectrumSubscription?.cancel();
    unawaited(widget.realtimeSpectrum.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _loadWaveformIfNeeded();
    _syncRealtimeSpectrum();
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => SizedBox(
        height: widget.height,
        width: double.infinity,
        child: CustomPaint(
          painter: _VisualizerPainter(
            progress: _progress,
            phase: widget.snapshot.isPlaying ? _controller.value : 0,
            waveform: _waveform,
            spectrum: _smoothedSpectrum,
            activeColor: colorScheme.primary,
            accentColor: colorScheme.secondary,
            inactiveColor: colorScheme.surfaceContainerHighest,
          ),
        ),
      ),
    );
  }

  void _syncRealtimeSpectrum() {
    if (!widget.snapshot.isPlaying || widget.snapshot.currentTrack == null) {
      return;
    }
    final sessionId = widget.snapshot.audioSessionId;
    if (sessionId == null || sessionId <= 0) return;
    if (_sessionId == sessionId) return;
    _sessionId = sessionId;
    unawaited(_restartSpectrum(sessionId));
  }

  Future<void> _restartSpectrum(int sessionId) async {
    await widget.realtimeSpectrum.stop();
    await widget.realtimeSpectrum.start(audioSessionId: sessionId);
  }

  void _loadWaveformIfNeeded() {
    final track = widget.snapshot.currentTrack;
    if (track == null || track.sourcePath == _sourcePath) return;
    _sourcePath = track.sourcePath;
    _sessionId = null;
    _waveform = null;
    widget.audioAnalysis
        .waveformFor(track)
        .then((waveform) {
          if (!mounted || _sourcePath != track.sourcePath) return;
          setState(() => _waveform = waveform);
        })
        .onError((error, stackTrace) {
          // SMB and unavailable files keep the playback-position fallback.
        });
  }

  double get _progress {
    final duration = widget.snapshot.duration.inMilliseconds;
    if (duration <= 0) return 0;
    return (widget.snapshot.position.inMilliseconds / duration).clamp(0, 1);
  }
}

class _VisualizerPainter extends CustomPainter {
  static const displayBarCount = 320;

  const _VisualizerPainter({
    required this.progress,
    required this.phase,
    required this.waveform,
    required this.spectrum,
    required this.activeColor,
    required this.accentColor,
    required this.inactiveColor,
  });

  final double progress;
  final double phase;
  final List<double>? waveform;
  final List<double>? spectrum;
  final Color activeColor;
  final Color accentColor;
  final Color inactiveColor;

  @override
  void paint(Canvas canvas, Size size) {
    const barCount = displayBarCount;
    const gap = 0.8;
    final barWidth = (size.width - gap * (barCount - 1)) / barCount;
    final baseline = size.height - 10;
    const chartTop = 6.0;
    final activeBars = (progress * barCount).floor();

    final gridPaint = Paint()
      ..color = inactiveColor.withValues(alpha: 0.28)
      ..strokeWidth = 1;
    for (var line = 1; line <= 3; line++) {
      final y = chartTop + (baseline - chartTop) * line / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (var index = 8; index < barCount; index += 8) {
      final x = index * (barWidth + gap) - gap / 2;
      canvas.drawLine(Offset(x, chartTop), Offset(x, baseline), gridPaint);
    }

    for (var index = 0; index < barCount; index++) {
      final fallback = 0.12 + (math.sin(index * 0.31).abs() * 0.48);
      final rawAmplitude = spectrum != null && spectrum!.isNotEmpty
          ? _spectrumValue(index)
          : waveform == null
          ? (0.12 + math.sin(index * 0.85 + phase * math.pi * 2).abs() * 0.18) *
                fallback
          : waveform![index % waveform!.length];
      final normalizedAmplitude = rawAmplitude.clamp(0, 10).toDouble();
      final amplitude = spectrum != null
          ? normalizedAmplitude
          : math.pow(normalizedAmplitude, 0.3).toDouble().clamp(0, 1);
      final height = (baseline - chartTop) * amplitude;
      final left = index * (barWidth + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, baseline - height, barWidth, height),
        Radius.zero,
      );
      final isPlayed = index <= activeBars;
      final topColor = isPlayed
          ? Color.lerp(accentColor, Colors.white, 0.18)!
          : const Color(0xFF7892AD).withValues(alpha: 0.72);
      final bottomColor = isPlayed
          ? Color.lerp(activeColor, const Color(0xFF75B7E8), 0.45)!
          : const Color(0xFF344A60).withValues(alpha: 0.6);
      final glowPaint = Paint()
        ..color = const Color(
          0xFF72B8EA,
        ).withValues(alpha: isPlayed ? 0.13 : 0.015)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      canvas.drawRRect(rect, glowPaint);
      final barPaint = Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [topColor, bottomColor],
            ).createShader(
              Rect.fromLTWH(left, baseline - height, barWidth, height),
            );
      canvas.drawRRect(rect, barPaint);
      if (height > 10) {
        final capPaint = Paint()..color = topColor.withValues(alpha: 0.82);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, baseline - height, barWidth, 1.5),
            Radius.zero,
          ),
          capPaint,
        );
      }
    }
    final baselinePaint = Paint()
      ..color = const Color(0xFF7FA6C7).withValues(alpha: 0.7)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset.zero.translate(0, baseline),
      Offset(size.width, baseline),
      baselinePaint,
    );
  }

  double _spectrumValue(int index) {
    final values = spectrum!;
    if (values.length == 1) return values.first;
    final position = index * (values.length - 1) / (displayBarCount - 1);
    final lower = position.floor().clamp(0, values.length - 1);
    final upper = position.ceil().clamp(0, values.length - 1);
    final fraction = position - lower;
    return values[lower] + (values[upper] - values[lower]) * fraction;
  }

  @override
  bool shouldRepaint(_VisualizerPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      phase != oldDelegate.phase ||
      waveform != oldDelegate.waveform ||
      spectrum != oldDelegate.spectrum ||
      activeColor != oldDelegate.activeColor ||
      accentColor != oldDelegate.accentColor ||
      inactiveColor != oldDelegate.inactiveColor;
}
