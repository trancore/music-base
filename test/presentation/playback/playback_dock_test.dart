import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:music_base/data/playback/noop_realtime_spectrum_service.dart';
import 'package:music_base/domain/library/library_track.dart';
import 'package:music_base/domain/playback/audio_analysis_service.dart';
import 'package:music_base/domain/playback/playback_service.dart';
import 'package:music_base/presentation/playback/playback_dock.dart';

void main() {
  testWidgets('keeps album artwork visible across playback updates', (
    tester,
  ) async {
    final playback = _FakePlaybackService(
      LibraryTrack(
        sourcePath: '/music/song.flac',
        title: 'Song',
        artwork: base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlaybackDock(
            playback: playback,
            audioAnalysis: const _NoopAudioAnalysisService(),
            realtimeSpectrum: const NoopRealtimeSpectrumService(),
            compact: true,
          ),
        ),
      ),
    );
    await tester.pump();

    final imageElement = tester.element(find.byType(Image));
    expect(tester.widget<Image>(find.byType(Image)).gaplessPlayback, isTrue);
    expect(
      find.ancestor(
        of: find.byType(Image),
        matching: find.byType(RepaintBoundary),
      ),
      findsWidgets,
    );

    playback.updatePosition(const Duration(seconds: 1));
    await tester.pump();

    expect(tester.element(find.byType(Image)), same(imageElement));
  });
}

class _FakePlaybackService extends ChangeNotifier implements PlaybackService {
  _FakePlaybackService(this.track)
    : _snapshot = PlaybackSnapshot(currentTrack: track, isPlaying: true);

  final LibraryTrack track;
  PlaybackSnapshot _snapshot;

  @override
  PlaybackSnapshot get snapshot => _snapshot;

  void updatePosition(Duration position) {
    _snapshot = PlaybackSnapshot(
      currentTrack: track,
      position: position,
      isPlaying: true,
    );
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopAudioAnalysisService implements AudioAnalysisService {
  const _NoopAudioAnalysisService();

  @override
  Future<List<double>> waveformFor(LibraryTrack track) async => const [];
}
