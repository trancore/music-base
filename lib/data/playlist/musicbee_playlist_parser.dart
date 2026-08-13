import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:path/path.dart' as p;

class MusicBeePlaylistImport {
  const MusicBeePlaylistImport({required this.name, required this.trackPaths});

  final String name;
  final List<String> trackPaths;
}

/// Reads the version 4 binary playlist format written by MusicBee (`.mbp`).
class MusicBeePlaylistParser {
  const MusicBeePlaylistParser();

  static const _supportedVersion = 4;
  static const _maximumHeaderLength = 64 * 1024;
  static const _maximumFileLength = 64 * 1024 * 1024;
  static const _maximumTrackCount = 100000;
  static const _maximumPathByteLength = 1024 * 1024;

  MusicBeePlaylistImport parseBytes(
    List<int> bytes, {
    required String sourcePath,
  }) {
    if (bytes.length < 12) {
      throw const FormatException('The MusicBee playlist is truncated.');
    }
    if (bytes.length > _maximumFileLength) {
      throw const FormatException('The MusicBee playlist is too large.');
    }
    final data = ByteData.sublistView(Uint8List.fromList(bytes));
    final version = data.getInt32(0, Endian.little);
    if (version != _supportedVersion) {
      throw FormatException('Unsupported MusicBee playlist version: $version.');
    }

    final scanEnd = math.min(data.lengthInBytes - 4, _maximumHeaderLength);
    for (var countOffset = 4; countOffset <= scanEnd; countOffset++) {
      final count = data.getInt32(countOffset, Endian.little);
      if (count <= 0 || count > _maximumTrackCount) continue;
      final parsed = _tryReadTracks(data, countOffset + 4, count);
      if (parsed != null) {
        return MusicBeePlaylistImport(
          name: _playlistName(sourcePath),
          trackPaths: List.unmodifiable(parsed),
        );
      }
    }

    throw const FormatException(
      'The file does not contain a supported MusicBee playlist.',
    );
  }

  List<String>? _tryReadTracks(ByteData data, int offset, int count) {
    final paths = <String>[];
    var cursor = offset;
    try {
      for (var index = 0; index < count; index++) {
        final length = _read7BitEncodedInt(data, cursor);
        cursor = length.nextOffset;
        if (length.value <= 0 || length.value > _maximumPathByteLength) {
          return null;
        }
        final pathEnd = cursor + length.value;
        if (pathEnd + 4 > data.lengthInBytes) return null;
        final path = utf8.decode(
          data.buffer.asUint8List(data.offsetInBytes + cursor, length.value),
          allowMalformed: false,
        );
        final normalized = _normalizePath(path);
        if (normalized == null) return null;
        paths.add(normalized);
        cursor = pathEnd;

        // MusicBee stores an additional signed 32-bit value after each path.
        // Its meaning is not required for resolving tracks during import.
        data.getInt32(cursor, Endian.little);
        cursor += 4;
      }
    } on Object {
      return null;
    }
    return cursor == data.lengthInBytes ? paths : null;
  }

  ({int value, int nextOffset}) _read7BitEncodedInt(ByteData data, int offset) {
    var value = 0;
    var shift = 0;
    var cursor = offset;
    for (var index = 0; index < 5; index++) {
      if (cursor >= data.lengthInBytes) {
        throw const FormatException('Truncated string length.');
      }
      final byte = data.getUint8(cursor++);
      value |= (byte & 0x7f) << shift;
      if ((byte & 0x80) == 0) {
        return (value: value, nextOffset: cursor);
      }
      shift += 7;
    }
    throw const FormatException('Invalid string length.');
  }

  String? _normalizePath(String value) {
    final path = value.trim();
    if (path.isEmpty || path.contains('\u0000')) return null;
    if (path.startsWith('smb://')) return path;
    if (p.windows.isAbsolute(path)) {
      return p.windows.normalize(path).replaceAll('\\', '/');
    }
    if (p.posix.isAbsolute(path)) return p.posix.normalize(path);
    return null;
  }

  String _playlistName(String sourcePath) {
    final basename = p.windows.isAbsolute(sourcePath)
        ? p.windows.basenameWithoutExtension(sourcePath)
        : p.basenameWithoutExtension(sourcePath);
    return basename.trim().isEmpty ? 'Imported playlist' : basename.trim();
  }
}
