import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_base/data/playlist/m3u_playlist_parser.dart';

void main() {
  const parser = M3uPlaylistParser();

  test('parses extended M3U with UTF-8 and Windows paths', () {
    final result = parser.parseBytes(
      utf8.encode('''\ufeff#EXTM3U
#EXTINF:256,artist - track one
X:/SampleLibrary/音源/01-track.flac
#EXTINF:460,artist - track two
X:\\SampleLibrary\\音源\\02-track.flac
'''),
      sourcePath: r'C:\Playlists\sample.m3u',
    );

    expect(result.name, 'sample');
    expect(result.trackPaths, [
      'X:/SampleLibrary/音源/01-track.flac',
      'X:/SampleLibrary/音源/02-track.flac',
    ]);
  });

  test('resolves relative entries against the playlist directory', () {
    final result = parser.parse(
      '#EXTM3U\n../Music/one.flac\n"two.mp3"\n',
      sourcePath: '/Users/music/playlists/sample.m3u8',
    );

    expect(result.name, 'sample');
    expect(result.trackPaths, [
      '/Users/music/Music/one.flac',
      '/Users/music/playlists/two.mp3',
    ]);
  });

  test('preserves a 23-track UTF-8 playlist', () {
    final entries = List.generate(
      23,
      (index) =>
          '#EXTINF:${index + 60},Sample Artist - Étude ${index + 1}\n'
          'Z:/Audio/音楽/Sample Artist/'
          '${(index + 1).toString().padLeft(2, '0')}-Étude.flac',
    );
    final result = parser.parseBytes(
      utf8.encode('#EXTM3U\n${entries.join('\n')}\n'),
      sourcePath: r'C:\Playlists\Sample collection.m3u',
    );

    expect(result.name, 'Sample collection');
    expect(result.trackPaths, hasLength(23));
    expect(result.trackPaths.first, contains('音楽'));
    expect(result.trackPaths.last, startsWith('Z:/Audio/'));
  });
}
