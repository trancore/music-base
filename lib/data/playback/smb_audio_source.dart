// ignore_for_file: experimental_member_use

import 'package:dart_smb2/dart_smb2.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;

import '../../domain/library/library_track.dart';
import '../../domain/library/smb_service.dart';
import '../library/smb_settings_repository.dart';

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
    if (segments.length < 2) return null;
    return SmbRemoteLocation(
      host: uri.host,
      share: segments.first,
      path: segments.skip(1).join('/'),
    );
  }
}

class SmbPlaybackSourceFactory {
  SmbPlaybackSourceFactory(this._settingsRepository);

  final SmbSettingsRepository _settingsRepository;
  final Set<SmbStreamAudioSource> _activeSources = {};

  Future<SmbStreamAudioSource> create(LibraryTrack track) async {
    final location = SmbRemoteLocation.parse(track.sourcePath);
    final configuredSource = await _settingsRepository.loadSource();
    final password = await _settingsRepository.loadPassword();
    if (location == null || configuredSource == null || password == null) {
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
      final source = SmbStreamAudioSource(
        pool: pool,
        path: location.path,
        length: length,
        contentType: _contentType(location.path),
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
    _ => 'application/octet-stream',
  };
}

class SmbStreamAudioSource extends StreamAudioSource {
  SmbStreamAudioSource({
    required this.pool,
    required this.path,
    required this.length,
    required this.contentType,
    required this.onClose,
  });

  final Smb2Pool pool;
  final String path;
  final int length;
  final String contentType;
  final void Function(SmbStreamAudioSource source) onClose;
  bool _closed = false;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    if (_closed) throw StateError('SMB audio source is closed.');
    final offset = start ?? 0;
    final requestedEnd = end ?? length;
    final bytes = await pool.readFileRange(
      path,
      offset: offset,
      length: requestedEnd - offset,
    );
    return StreamAudioResponse(
      sourceLength: length,
      contentLength: bytes.length,
      offset: offset,
      stream: Stream.value(bytes),
      contentType: contentType,
    );
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    onClose(this);
    await pool.disconnect();
  }
}
