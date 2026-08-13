import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_base/data/playlist/m3u_playlist_parser.dart';

void main() {
  const parser = M3uPlaylistParser();

  test('parses extended M3U with UTF-8 and Windows paths', () {
    final result = parser.parseBytes(
      utf8.encode('''\ufeff#EXTM3U
#EXTINF:256,artist - track one
Z:/Music/音源/01-track.flac
#EXTINF:460,artist - track two
Z:\\Music\\音源\\02-track.flac
'''),
      sourcePath: r'C:\Playlists\sample.m3u',
    );

    expect(result.name, 'sample');
    expect(result.trackPaths, [
      'Z:/Music/音源/01-track.flac',
      'Z:/Music/音源/02-track.flac',
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
}
