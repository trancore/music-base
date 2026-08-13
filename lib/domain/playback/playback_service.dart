import 'package:flutter/foundation.dart';

import '../library/library_track.dart';
import '../radio/internet_radio_station.dart';

class PlaybackSnapshot {
  const PlaybackSnapshot({
    this.currentTrack,
    this.currentRadioStation,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isPlaying = false,
    this.isLoading = false,
    this.volume = 1,
    this.isMuted = false,
    this.queue = const [],
    this.queueTotal,
    this.currentIndex = 0,
    this.audioSessionId,
    this.shuffleEnabled = false,
    this.repeatEnabled = false,
    this.errorMessage,
  });

  final LibraryTrack? currentTrack;
  final InternetRadioStation? currentRadioStation;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final bool isLoading;
  final double volume;
  final bool isMuted;
  final List<LibraryTrack> queue;
  final int? queueTotal;
  final int currentIndex;
  final int? audioSessionId;
  final bool shuffleEnabled;
  final bool repeatEnabled;
  final String? errorMessage;
}

abstract interface class PlaybackQueueSource {
  int get length;

  Future<LibraryTrack?> trackAt(int index);

  Future<void> dispose();
}

abstract interface class PlaybackService extends Listenable {
  PlaybackSnapshot get snapshot;

  Future<void> playTrack(LibraryTrack track);

  Future<void> playRadioStation(InternetRadioStation station);

  Future<void> playQueue(List<LibraryTrack> tracks, {int initialIndex = 0});

  Future<void> playLazyQueue(PlaybackQueueSource queue, {int initialIndex = 0});

  Future<void> pause();

  Future<void> resume();

  Future<void> stop();

  Future<void> seek(Duration position);

  Future<void> setVolume(double volume);

  Future<void> toggleMute();

  Future<void> skipNext();

  Future<void> skipPrevious();

  void toggleShuffle();

  void toggleRepeat();
}
