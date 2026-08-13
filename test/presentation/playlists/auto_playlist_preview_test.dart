import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_base/domain/library/library_track.dart';
import 'package:music_base/presentation/playlists/auto_playlist_preview.dart';

void main() {
  const tracks = [
    LibraryTrack(
      sourcePath: '/music/one.flac',
      title: 'first track',
      artist: 'sample artist',
      album: 'sample album',
    ),
    LibraryTrack(
      sourcePath: '/music/two.flac',
      title: 'second track',
      artist: 'other artist',
      album: 'other album',
    ),
  ];

  testWidgets('previews tracks matching the current query', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AutoPlaylistPreview(tracks: tracks, query: 'sample'),
        ),
      ),
    );

    expect(find.text('Preview (1 matches)'), findsOneWidget);
    expect(find.text('first track'), findsOneWidget);
    expect(find.text('sample artist · sample album'), findsOneWidget);
    expect(find.text('second track'), findsNothing);
  });

  testWidgets('shows an empty preview when the query has no matches', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AutoPlaylistPreview(tracks: tracks, query: 'missing'),
        ),
      ),
    );

    expect(find.text('Preview (0 matches)'), findsOneWidget);
    expect(find.text('No tracks match this condition.'), findsOneWidget);
  });
}
