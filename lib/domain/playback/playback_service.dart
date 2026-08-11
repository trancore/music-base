import '../library/library_track.dart';

class PlaybackSnapshot {
  const PlaybackSnapshot({
    this.currentTrack,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isPlaying = false,
    this.volume = 1,
    this.errorMessage,
  });

  final LibraryTrack? currentTrack;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final double volume;
  final String? errorMessage;
}

abstract interface class PlaybackService {
  PlaybackSnapshot get snapshot;

  Future<void> playTrack(LibraryTrack track);

  Future<void> pause();

  Future<void> resume();

  Future<void> stop();

  Future<void> seek(Duration position);

  Future<void> setVolume(double volume);
}
