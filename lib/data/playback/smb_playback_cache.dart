import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dart_smb2/dart_smb2.dart';
import 'package:path/path.dart' as p;

import '../../domain/library/library_track.dart';

/// Downloads SMB audio files to a local cache for reliable platform playback.
class SmbPlaybackCache {
  const SmbPlaybackCache();

  static const readChunkBytes = 128 * 1024;

  String cacheKeyFor(LibraryTrack track) {
    final digest = sha256.convert(
      utf8.encode(
        [
          track.sourcePath,
          track.fileSize,
          track.modifiedAt?.millisecondsSinceEpoch,
        ].join('|'),
      ),
    );
    return digest.toString();
  }

  Future<File> materialize({
    required Smb2Pool pool,
    required String remotePath,
    required int length,
    required LibraryTrack track,
  }) async {
    final cacheDir = await _cacheDirectory();
    final extension = p.extension(remotePath);
    final file = File('${cacheDir.path}/${cacheKeyFor(track)}$extension');
    if (await file.exists() && await file.length() == length) {
      return file;
    }

    if (await file.exists()) {
      await file.delete();
    }

    final handle = await file.open(mode: FileMode.write);
    try {
      var offset = 0;
      while (offset < length) {
        final chunkSize = min(readChunkBytes, length - offset);
        final bytes = await pool.readFileRange(
          remotePath,
          offset: offset,
          length: chunkSize,
        );
        if (bytes.isEmpty) {
          throw StateError(
            'SMB returned no data at offset $offset for $remotePath.',
          );
        }
        await handle.writeFrom(bytes);
        offset += bytes.length;
      }
    } finally {
      await handle.close();
    }

    final cachedLength = await file.length();
    if (cachedLength != length) {
      await file.delete();
      throw StateError(
        'SMB cache download incomplete for $remotePath '
        '(expected $length bytes, wrote $cachedLength).',
      );
    }
    return file;
  }

  Future<Directory> _cacheDirectory() async {
    final dir = Directory('${Directory.systemTemp.path}/music_base_playback');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
