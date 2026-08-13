import 'package:flutter_test/flutter_test.dart';
import 'package:music_base/domain/library/library_track.dart';
import 'package:music_base/domain/playlist/playlist.dart';
import 'package:music_base/domain/playlist/playlist_tracks.dart';

void main() {
  const tracks = [
    LibraryTrack(
      sourcePath: 'Z:/Music/category/one.flac',
      title: 'track one',
      artist: 'sample artist',
      album: 'sample album',
    ),
    LibraryTrack(
      sourcePath: 'Z:/Music/other/two.mp3',
      title: 'track two',
      artist: 'other artist',
    ),
  ];

  test('automatic playlists resolve against current library metadata', () {
    const playlist = Playlist(
      id: 'auto',
      name: 'matching tracks',
      type: PlaylistType.automatic,
      query: 'SAMPLE ARTIST',
    );

    expect(resolvePlaylistTracks(playlist, tracks), [tracks.first]);
  });

  test('manual playlist preserves order and matches Windows path case', () {
    const playlist = Playlist(
      id: 'manual',
      name: 'sample playlist',
      trackPaths: [
        r'z:\music\other\two.mp3',
        'Z:/Music/category/one.flac',
        'Z:/Music/missing.flac',
      ],
    );

    expect(resolvePlaylistTracks(playlist, tracks), [tracks[1], tracks[0]]);
  });
}
