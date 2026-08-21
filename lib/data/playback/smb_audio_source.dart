// ignore_for_file: experimental_member_use

import 'package:dart_smb2/dart_smb2.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;

import '../../domain/library/library_track.dart';
import '../../domain/library/smb_service.dart';
import '../library/smb_settings_repository.dart';
import 'smb_playback_cache.dart';

class SmbRemoteLocation {
  const SmbRemoteLocation({
    required this.host,
    required this.share,
    required this.path,
  });

  final String host;
  final String share;
  final String path;

  static SmbRemoteLocation? parse(String sourcePath) {
    final uri = Uri.tryParse(sourcePath);
    if (uri == null || uri.scheme != 'smb' || uri.host.isEmpty) return null;
    final segments = uri.pathSegments;
    // The first segment is the share and the remaining segment(s) form the
    // file path. A file may live directly in the share root.
    if (segments.length < 2) return null;
    final filePath = segments.skip(1).join('/');
    if (filePath.isEmpty) return null;
    return SmbRemoteLocation(
      host: uri.host,
      share: segments.first,
      path: filePath,
    );
  }
}

class SmbPlaybackSourceFactory {
  SmbPlaybackSourceFactory(
    this._settingsRepository, {
    SmbPlaybackCache? playbackCache,
    bool Function()? usePlaybackCache,
  }) : _playbackCache = playbackCache ?? const SmbPlaybackCache(),
       _usePlaybackCache = usePlaybackCache ?? _defaultUsePlaybackCache;

  final SmbSettingsRepository _settingsRepository;
  final SmbPlaybackCache _playbackCache;
  final bool Function() _usePlaybackCache;
  final Set<SmbStreamAudioSource> _activeSources = {};

  static bool _defaultUsePlaybackCache() =>
      defaultTargetPlatform == TargetPlatform.android;

  Future<AudioSource> create(LibraryTrack track, {dynamic tag}) async {
    final location = SmbRemoteLocation.parse(track.sourcePath);
    final configuredSource = await _settingsRepository.loadSource();
    final password = await _settingsRepository.loadPassword();
    if (location == null ||
        configuredSource == null ||
        password == null ||
        password.isEmpty) {
      throw const SmbConnectionException(
        'The SMB source is not configured for this track.',
      );
    }
    if (location.host != configuredSource.host ||
        location.share != configuredSource.share) {
      throw const SmbConnectionException(
        'The saved SMB settings do not match this track.',
      );
    }

    Smb2Pool? pool;
    try {
      pool = await Smb2Pool.connect(
        host: configuredSource.host,
        share: configuredSource.share,
        user: configuredSource.username,
        password: password,
        workers: 1,
        timeoutSeconds: 30,
      );
      final length = await pool.fileSize(location.path);
      if (_usePlaybackCache()) {
        final file = await _playbackCache.materialize(
          pool: pool,
          remotePath: location.path,
          length: length,
          track: track,
        );
        await pool.disconnect();
        return AudioSource.file(file.path, tag: tag);
      }

      final source = SmbStreamAudioSource(
        pool: pool,
        path: location.path,
        length: length,
        contentType: _contentType(location.path),
        tag: tag,
        onClose: _remove,
      );
      _activeSources.add(source);
      return source;
    } on Smb2Exception catch (error) {
      await pool?.disconnect();
      throw SmbConnectionException(
        'Unable to open SMB audio: ${error.message}',
      );
    } on Exception {
      await pool?.disconnect();
      rethrow;
    }
  }

  Future<void> dispose() async {
    for (final source in List<SmbStreamAudioSource>.from(_activeSources)) {
      await source.close();
    }
  }

  void _remove(SmbStreamAudioSource source) => _activeSources.remove(source);

  String _contentType(String path) => switch (p.extension(path).toLowerCase()) {
    '.flac' => 'audio/flac',
    '.mp3' => 'audio/mpeg',
    '.ogg' => 'audio/ogg',
    '.3gp' => 'audio/3gpp',
    '.mp4' => 'audio/mp4',
    _ => 'application/octet-stream',
  };
}

class SmbStreamAudioSource extends StreamAudioSource {
  SmbStreamAudioSource({
    required this.pool,
    required this.path,
    required this.length,
    required this.contentType,
    super.tag,
    required this.onClose,
  });

  static const readChunkBytes = 128 * 1024;

  final Smb2Pool pool;
  final String path;
  final int length;
  final String contentType;
  final void Function(SmbStreamAudioSource source) onClose;
  bool _closed = false;
  Future<void> _readChain = Future<void>.value();

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    if (_closed) throw StateError('SMB audio source is closed.');
    final offset = (start ?? 0).clamp(0, length);
    final requestedEnd = (end ?? length).clamp(offset, length);
    final contentLength = requestedEnd - offset;
    if (contentLength <= 0) {
      throw StateError(
        'Invalid SMB range request at offset $offset for $path.',
      );
    }
    return StreamAudioResponse(
      sourceLength: length,
      contentLength: contentLength,
      offset: offset,
      stream: _streamRange(offset, requestedEnd),
      contentType: contentType,
    );
  }

  Stream<List<int>> _streamRange(int start, int end) async* {
    var offset = start;
    while (offset < end) {
      final readLength = (end - offset).clamp(1, readChunkBytes);
      final bytes = await _readLocked(
        () => pool.readFileRange(path, offset: offset, length: readLength),
      );
      if (bytes.isEmpty) {
        throw StateError('SMB returned no data at offset $offset for $path.');
      }
      yield bytes;
      offset += bytes.length;
    }
  }

  Future<T> _readLocked<T>(Future<T> Function() action) {
    final result = _readChain.then((_) => action());
    _readChain = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    onClose(this);
    await pool.disconnect();
  }
}
