import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_base/data/playlist/musicbee_auto_playlist_parser.dart';
import 'package:music_base/domain/playlist/playlist.dart';

void main() {
  const parser = MusicBeeAutoPlaylistParser();

  test('parses an ArtistPeople StartsWith smart playlist', () {
    final result = parser.parseBytes(
      utf8.encode('''
<?xml version="1.0" encoding="UTF-8"?>
<SmartPlaylist LiveUpdating="True">
  <Source Type="1">
    <Conditions CombineMethod="All">
      <Condition Field="ArtistPeople" Comparison="StartsWith" Value="Matthias H&#246;fs &amp; Friends" />
    </Conditions>
  </Source>
</SmartPlaylist>
'''),
      sourcePath: '/playlists/Trumpet - Matthias Höfs -.xautopf',
    );

    expect(result.name, 'Trumpet - Matthias Höfs -');
    expect(result.rule.field, AutoPlaylistField.artist);
    expect(result.rule.comparison, AutoPlaylistComparison.startsWith);
    expect(result.rule.value, 'Matthias Höfs & Friends');
    expect(
      result.rule.matches(artist: 'MATTHIAS HÖFS & FRIENDS Brass'),
      isTrue,
    );
    expect(result.rule.matches(artist: 'Guest, Matthias Höfs'), isFalse);
  });

  test('rejects unsupported fields and multiple conditions', () {
    List<int> playlist(String conditions) => utf8.encode('''
<SmartPlaylist><Source><Conditions CombineMethod="All">
$conditions
</Conditions></Source></SmartPlaylist>
''');

    expect(
      () => parser.parseBytes(
        playlist(
          '<Condition Field="Album" Comparison="StartsWith" Value="Brass" />',
        ),
        sourcePath: 'sample.xautopf',
      ),
      throwsFormatException,
    );
    expect(
      () => parser.parseBytes(
        playlist('''
<Condition Field="ArtistPeople" Comparison="StartsWith" Value="One" />
<Condition Field="ArtistPeople" Comparison="StartsWith" Value="Two" />
'''),
        sourcePath: 'sample.xautopf',
      ),
      throwsFormatException,
    );
  });
}
