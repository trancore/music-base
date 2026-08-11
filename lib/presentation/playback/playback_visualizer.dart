import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/playback/playback_service.dart';
import '../../domain/playback/audio_analysis_service.dart';

class PlaybackVisualizer extends StatefulWidget {
  const PlaybackVisualizer({
    required this.snapshot,
    required this.audioAnalysis,
    super.key,
  });

  final PlaybackSnapshot snapshot;
  final AudioAnalysisService audioAnalysis;

  @override
  State<PlaybackVisualizer> createState() => _PlaybackVisualizerState();
}

class _PlaybackVisualizerState extends State<PlaybackVisualizer>
    with SingleTickerProviderStateMixin {
  List<double>? _waveform;
  String? _sourcePath;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _loadWaveformIfNeeded();
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => SizedBox(
        height: 72,
        width: double.infinity,
        child: CustomPaint(
          painter: _VisualizerPainter(
            progress: _progress,
            phase: widget.snapshot.isPlaying ? _controller.value : 0,
            waveform: _waveform,
            activeColor: colorScheme.primary,
            inactiveColor: colorScheme.surfaceContainerHighest,
          ),
        ),
      ),
    );
  }

  void _loadWaveformIfNeeded() {
    final track = widget.snapshot.currentTrack;
    if (track == null || track.sourcePath == _sourcePath) return;
    _sourcePath = track.sourcePath;
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
  const _VisualizerPainter({
    required this.progress,
    required this.phase,
    required this.waveform,
    required this.activeColor,
    required this.inactiveColor,
  });

  final double progress;
  final double phase;
  final List<double>? waveform;
  final Color activeColor;
  final Color inactiveColor;

  @override
  void paint(Canvas canvas, Size size) {
    const barCount = 32;
    const gap = 3.0;
    final barWidth = (size.width - gap * (barCount - 1)) / barCount;
    final center = size.height / 2;
    final activeBars = (progress * barCount).floor();
    final paint = Paint()..style = PaintingStyle.fill;

    for (var index = 0; index < barCount; index++) {
      final fallback = 0.3 + (math.sin(index * 0.31).abs() * 0.7);
      final amplitude = waveform == null
          ? (0.18 + math.sin(index * 0.85 + phase * math.pi * 2).abs() * 0.2) *
                fallback
          : waveform![index % waveform!.length].clamp(0.08, 1.0);
      final height = size.height * amplitude;
      final left = index * (barWidth + gap);
      paint.color = index <= activeBars ? activeColor : inactiveColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, center - height / 2, barWidth, height),
          const Radius.circular(3),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_VisualizerPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      phase != oldDelegate.phase ||
      waveform != oldDelegate.waveform ||
      activeColor != oldDelegate.activeColor ||
      inactiveColor != oldDelegate.inactiveColor;
}
