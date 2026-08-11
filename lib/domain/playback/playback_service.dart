import '../library/library_track.dart';

class PlaybackSnapshot {
  const PlaybackSnapshot({
    this.currentTrack,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isPlaying = false,
    this.volume = 1,
    this.isMuted = false,
    this.queue = const [],
    this.currentIndex = 0,
    this.audioSessionId,
    this.shuffleEnabled = false,
    this.repeatEnabled = false,
    this.errorMessage,
  });

  final LibraryTrack? currentTrack;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final double volume;
  final bool isMuted;
  final List<LibraryTrack> queue;
  final int currentIndex;
  final int? audioSessionId;
  final bool shuffleEnabled;
  final bool repeatEnabled;
  final String? errorMessage;
}

abstract interface class PlaybackService {
  PlaybackSnapshot get snapshot;

  Future<void> playTrack(LibraryTrack track);

  Future<void> playQueue(List<LibraryTrack> tracks, {int initialIndex = 0});

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
