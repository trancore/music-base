import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../domain/library/library_track.dart';
import '../../domain/playback/playback_service.dart';
import '../../domain/library/smb_service.dart';
import '../../domain/radio/internet_radio_station.dart';
import 'smb_audio_source.dart';

class JustAudioPlaybackService extends ChangeNotifier
    implements PlaybackService {
  JustAudioPlaybackService(this._player, {this.remoteSourceFactory}) {
    _subscriptions = [
      _player.playerStateStream.listen((state) {
        if (_currentRadioStation != null) {
          if (state.playing) {
            _startRadioClock();
          } else {
            _stopRadioClock();
          }
        }
        _update(
          isPlaying: state.playing,
          duration: _player.duration,
          isLoading: state.playing ? false : null,
        );
      }),
      _player.positionStream.listen((position) {
        _update(position: position, duration: _player.duration);
      }),
      _player.androidAudioSessionIdStream.listen(
        (audioSessionId) => _update(audioSessionId: audioSessionId),
      ),
      _player.processingStateStream.listen((state) {
        if (state == ProcessingState.completed) {
          unawaited(skipNext());
        }
      }),
    ];
  }

  final AudioPlayer _player;
  final SmbPlaybackSourceFactory? remoteSourceFactory;
  late final List<StreamSubscription<dynamic>> _subscriptions;
  SmbStreamAudioSource? _activeRemoteSource;
  List<LibraryTrack> _queue = const [];
  InternetRadioStation? _currentRadioStation;
  Timer? _radioClockTimer;
  Duration _radioElapsed = Duration.zero;
  int _currentIndex = 0;
  double _volumeBeforeMute = 1;
  PlaybackSnapshot _snapshot = const PlaybackSnapshot();

  @override
  PlaybackSnapshot get snapshot => _snapshot;

  @override
  Future<void> playTrack(LibraryTrack track) async {
    await playQueue([track]);
  }

  @override
  Future<void> playRadioStation(InternetRadioStation station) async {
    await _activeRemoteSource?.close();
    _activeRemoteSource = null;
    _queue = const [];
    _currentIndex = 0;
    _currentRadioStation = station;
    _stopRadioClock();
    _radioElapsed = Duration.zero;
    await _loadRadioStation(station);
  }

  @override
  Future<void> playQueue(
    List<LibraryTrack> tracks, {
    int initialIndex = 0,
  }) async {
    if (tracks.isEmpty) return;
    _queue = List.unmodifiable(tracks);
    _currentIndex = initialIndex.clamp(0, _queue.length - 1).toInt();
    await _loadCurrentTrack();
  }

  Future<void> _loadCurrentTrack() async {
    final track = _queue[_currentIndex];
    _currentRadioStation = null;
    final mediaItem = MediaItem(
      id: track.sourcePath,
      title: track.title ?? track.sourcePath,
      artist: track.artist,
      album: track.album,
    );
    try {
      await _activeRemoteSource?.close();
      _activeRemoteSource = null;
      _snapshot = PlaybackSnapshot(
        currentTrack: track,
        currentRadioStation: null,
        isLoading: true,
        volume: _snapshot.volume,
        isMuted: _snapshot.isMuted,
        queue: _queue,
        currentIndex: _currentIndex,
        shuffleEnabled: _snapshot.shuffleEnabled,
        repeatEnabled: _snapshot.repeatEnabled,
      );
      notifyListeners();
      if (track.isRemote) {
        final factory = remoteSourceFactory;
        if (factory == null) {
          throw const SmbConnectionException('SMB playback is not configured.');
        }
        _activeRemoteSource = await factory.create(track, tag: mediaItem);
        await _player.setAudioSource(_activeRemoteSource!);
      } else {
        await _player.setAudioSource(
          AudioSource.file(track.sourcePath, tag: mediaItem),
        );
      }
      await _player.play();
    } on PlayerException catch (error) {
      _setError('Unable to play this file: ${error.message ?? error.code}');
    } on PlayerInterruptedException catch (error) {
      _setError('Playback was interrupted: ${error.message}');
    } on Exception catch (error) {
      _setError('Unable to play this file: $error');
    }
  }

  Future<void> _loadRadioStation(InternetRadioStation station) async {
    final mediaItem = MediaItem(
      id: station.id,
      title: station.name,
      artist: station.genre,
      album: station.description,
    );
    try {
      _snapshot = PlaybackSnapshot(
        currentTrack: null,
        currentRadioStation: station,
        isLoading: true,
        volume: _snapshot.volume,
        isMuted: _snapshot.isMuted,
        queue: const [],
        currentIndex: 0,
        shuffleEnabled: false,
        repeatEnabled: false,
      );
      notifyListeners();
      await _player.setAudioSource(
        AudioSource.uri(Uri.parse(station.streamUrl), tag: mediaItem),
      );
      await _player.play();
    } on PlayerException catch (error) {
      _setError(
        'Unable to play this radio station: ${error.message ?? error.code}',
      );
    } on PlayerInterruptedException catch (error) {
      _setError('Radio playback was interrupted: ${error.message}');
    } on Exception catch (error) {
      _setError('Unable to play this radio station: $error');
    }
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    _stopRadioClock();
  }

  @override
  Future<void> resume() async {
    await _player.play();
    if (_currentRadioStation != null) _startRadioClock();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _stopRadioClock();
    if (_currentRadioStation != null) {
      _radioElapsed = Duration.zero;
      _update(position: Duration.zero, isPlaying: false, isLoading: false);
    }
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setVolume(double volume) async {
    final clampedVolume = volume.clamp(0, 1).toDouble();
    await _player.setVolume(clampedVolume);
    _update(volume: clampedVolume);
  }

  @override
  Future<void> toggleMute() async {
    if (_snapshot.isMuted) {
      await setVolume(_volumeBeforeMute);
      _update(isMuted: false);
    } else {
      _volumeBeforeMute = _snapshot.volume == 0 ? 1 : _snapshot.volume;
      await _player.setVolume(0);
      _update(volume: 0, isMuted: true);
    }
  }

  @override
  Future<void> skipNext() async {
    if (_currentRadioStation != null) return;
    if (_queue.isEmpty) return;
    if (_snapshot.repeatEnabled) {
      await _player.seek(Duration.zero);
      await _player.play();
      return;
    }
    if (_snapshot.shuffleEnabled && _queue.length > 1) {
      final candidates = List<int>.generate(_queue.length, (index) => index)
        ..remove(_currentIndex);
      _currentIndex = (candidates..shuffle()).first;
    } else if (_currentIndex + 1 < _queue.length) {
      _currentIndex++;
    } else {
      await stop();
      return;
    }
    await _loadCurrentTrack();
  }

  @override
  Future<void> skipPrevious() async {
    if (_currentRadioStation != null) return;
    if (_queue.isEmpty) return;
    if (_snapshot.position > const Duration(seconds: 3)) {
      await seek(Duration.zero);
      return;
    }
    if (_currentIndex > 0) {
      _currentIndex--;
      await _loadCurrentTrack();
    } else {
      await seek(Duration.zero);
    }
  }

  @override
  void toggleShuffle() => _update(shuffleEnabled: !_snapshot.shuffleEnabled);

  @override
  void toggleRepeat() => _update(repeatEnabled: !_snapshot.repeatEnabled);

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _activeRemoteSource?.close();
    _stopRadioClock();
    remoteSourceFactory?.dispose();
    _player.dispose();
    super.dispose();
  }

  void _update({
    Duration? position,
    Duration? duration,
    bool? isPlaying,
    bool? isLoading,
    double? volume,
    bool? isMuted,
    bool? shuffleEnabled,
    bool? repeatEnabled,
    int? audioSessionId,
  }) {
    final nextPosition =
        _snapshot.currentRadioStation != null && position != null
        ? _radioElapsed
        : position ?? _snapshot.position;
    _snapshot = PlaybackSnapshot(
      currentTrack: _snapshot.currentTrack,
      currentRadioStation: _snapshot.currentRadioStation,
      position: nextPosition,
      duration: duration ?? _snapshot.duration,
      isPlaying: isPlaying ?? _snapshot.isPlaying,
      isLoading: isLoading ?? _snapshot.isLoading,
      volume: volume ?? _snapshot.volume,
      isMuted: isMuted ?? _snapshot.isMuted,
      queue: _queue,
      currentIndex: _currentIndex,
      audioSessionId: audioSessionId ?? _snapshot.audioSessionId,
      shuffleEnabled: shuffleEnabled ?? _snapshot.shuffleEnabled,
      repeatEnabled: repeatEnabled ?? _snapshot.repeatEnabled,
      errorMessage: _snapshot.errorMessage,
    );
    notifyListeners();
  }

  void _startRadioClock() {
    if (_radioClockTimer != null || _currentRadioStation == null) return;
    _radioClockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_currentRadioStation == null) return;
      _radioElapsed += const Duration(seconds: 1);
      _update(position: _radioElapsed);
    });
  }

  void _stopRadioClock() {
    _radioClockTimer?.cancel();
    _radioClockTimer = null;
  }

  void _setError(String message) {
    _snapshot = PlaybackSnapshot(
      currentTrack: _snapshot.currentTrack,
      currentRadioStation: _snapshot.currentRadioStation,
      position: _snapshot.position,
      duration: _snapshot.duration,
      isLoading: false,
      volume: _snapshot.volume,
      isMuted: _snapshot.isMuted,
      queue: _queue,
      currentIndex: _currentIndex,
      audioSessionId: _snapshot.audioSessionId,
      shuffleEnabled: _snapshot.shuffleEnabled,
      repeatEnabled: _snapshot.repeatEnabled,
      errorMessage: message,
    );
    notifyListeners();
  }
}
