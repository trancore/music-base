import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_base/data/playlist/musicbee_playlist_parser.dart';

void main() {
  const parser = MusicBeePlaylistParser();

  test('parses a version 4 MusicBee playlist in track order', () {
    final result = parser.parseBytes(
      _musicBeePlaylist([
        r'X:\SampleLibrary\Collection\01-Étude.flac',
        r'X:\SampleLibrary\サンプル\02-Rondo.flac',
      ]),
      sourcePath: r'C:\Playlists\Sample collection.mbp',
    );

    expect(result.name, 'Sample collection');
    expect(result.trackPaths, [
      'X:/SampleLibrary/Collection/01-Étude.flac',
      'X:/SampleLibrary/サンプル/02-Rondo.flac',
    ]);
  });

  test('reads multi-byte 7-bit string lengths', () {
    final longPath = 'X:/SampleLibrary/${'collection/' * 12}track.flac';
    final result = parser.parseBytes(
      _musicBeePlaylist([longPath]),
      sourcePath: '/tmp/Long sample.mbp',
    );

    expect(utf8.encode(longPath).length, greaterThan(127));
    expect(result.trackPaths, [longPath]);
  });

  test('rejects unsupported versions and truncated records', () {
    final unsupported = _musicBeePlaylist([
      r'X:\SampleLibrary\one.flac',
    ], version: 3);
    expect(
      () => parser.parseBytes(unsupported, sourcePath: 'sample.mbp'),
      throwsFormatException,
    );

    final truncated = _musicBeePlaylist([r'X:\SampleLibrary\one.flac']).toList()
      ..removeLast();
    expect(
      () => parser.parseBytes(truncated, sourcePath: 'sample.mbp'),
      throwsFormatException,
    );
  });
}

List<int> _musicBeePlaylist(List<String> paths, {int version = 4}) {
  final bytes = BytesBuilder(copy: false)
    ..add(_int32(version))
    // Synthetic header data. The parser locates the validated track table
    // without depending on user-specific MusicBee settings.
    ..add(utf8.encode('SAMPLE-HEADER'))
    ..add(_int32(paths.length));
  for (final path in paths) {
    final encoded = utf8.encode(path);
    bytes
      ..add(_sevenBitEncodedInt(encoded.length))
      ..add(encoded)
      ..add(_int32(-1));
  }
  return bytes.takeBytes();
}

List<int> _int32(int value) {
  final data = ByteData(4)..setInt32(0, value, Endian.little);
  return data.buffer.asUint8List();
}

List<int> _sevenBitEncodedInt(int value) {
  final result = <int>[];
  var remaining = value;
  do {
    var byte = remaining & 0x7f;
    remaining >>= 7;
    if (remaining != 0) byte |= 0x80;
    result.add(byte);
  } while (remaining != 0);
  return result;
}
