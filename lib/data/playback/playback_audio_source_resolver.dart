import 'package:just_audio/just_audio.dart';

import '../../domain/library/library_track.dart';
import '../../domain/library/smb_service.dart';
import 'smb_audio_source.dart';

/// Resolves library tracks into just_audio sources and owns the active SMB
/// stream lifecycle.
class PlaybackAudioSourceResolver {
  PlaybackAudioSourceResolver(this.remoteSourceFactory);

  final SmbPlaybackSourceFactory? remoteSourceFactory;
  SmbStreamAudioSource? _activeRemoteSource;

  Future<AudioSource> resolveTrack(LibraryTrack track, {Object? tag}) async {
    await closeActiveRemoteSource();
    if (!track.isRemote) {
      return AudioSource.file(track.sourcePath, tag: tag);
    }

    final factory = remoteSourceFactory;
    if (factory == null) {
      throw const SmbConnectionException('SMB playback is not configured.');
    }
    final source = await factory.create(track, tag: tag);
    if (source is SmbStreamAudioSource) {
      _activeRemoteSource = source;
    }
    return source;
  }

  Future<void> closeActiveRemoteSource() async {
    await _activeRemoteSource?.close();
    _activeRemoteSource = null;
  }

  void dispose() {
    _activeRemoteSource?.close();
    remoteSourceFactory?.dispose();
  }
}
