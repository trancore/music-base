import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../../domain/library/library_track.dart';
import '../../domain/playback/playback_service.dart';
import '../../domain/library/smb_service.dart';
import 'smb_audio_source.dart';

class JustAudioPlaybackService extends ChangeNotifier
    implements PlaybackService {
  JustAudioPlaybackService(this._player, {this.remoteSourceFactory}) {
    _subscriptions = [
      _player.playerStateStream.listen((state) {
        _update(isPlaying: state.playing, duration: _player.duration);
      }),
      _player.positionStream.listen((position) {
        _update(position: position, duration: _player.duration);
      }),
    ];
  }

  final AudioPlayer _player;
  final SmbPlaybackSourceFactory? remoteSourceFactory;
  late final List<StreamSubscription<dynamic>> _subscriptions;
  SmbStreamAudioSource? _activeRemoteSource;
  PlaybackSnapshot _snapshot = const PlaybackSnapshot();

  @override
  PlaybackSnapshot get snapshot => _snapshot;

  @override
  Future<void> playTrack(LibraryTrack track) async {
    try {
      await _activeRemoteSource?.close();
      _activeRemoteSource = null;
      _snapshot = PlaybackSnapshot(
        currentTrack: track,
        volume: _snapshot.volume,
      );
      notifyListeners();
      if (track.isRemote) {
        final factory = remoteSourceFactory;
        if (factory == null) {
          throw const SmbConnectionException('SMB playback is not configured.');
        }
        _activeRemoteSource = await factory.create(track);
        await _player.setAudioSource(_activeRemoteSource!);
      } else {
        await _player.setFilePath(track.sourcePath);
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

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> resume() => _player.play();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setVolume(double volume) async {
    final clampedVolume = volume.clamp(0, 1).toDouble();
    await _player.setVolume(clampedVolume);
    _update(volume: clampedVolume);
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _activeRemoteSource?.close();
    remoteSourceFactory?.dispose();
    _player.dispose();
    super.dispose();
  }

  void _update({
    Duration? position,
    Duration? duration,
    bool? isPlaying,
    double? volume,
  }) {
    _snapshot = PlaybackSnapshot(
      currentTrack: _snapshot.currentTrack,
      position: position ?? _snapshot.position,
      duration: duration ?? _snapshot.duration,
      isPlaying: isPlaying ?? _snapshot.isPlaying,
      volume: volume ?? _snapshot.volume,
      errorMessage: _snapshot.errorMessage,
    );
    notifyListeners();
  }

  void _setError(String message) {
    _snapshot = PlaybackSnapshot(
      currentTrack: _snapshot.currentTrack,
      position: _snapshot.position,
      duration: _snapshot.duration,
      volume: _snapshot.volume,
      errorMessage: message,
    );
    notifyListeners();
  }
}
