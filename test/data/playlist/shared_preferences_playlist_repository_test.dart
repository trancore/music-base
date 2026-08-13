import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:music_base/data/playlist/shared_preferences_playlist_repository.dart';
import 'package:music_base/domain/playlist/playlist.dart';

void main() {
  test('persists, replaces, and deletes playlists', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = SharedPreferencesPlaylistRepository(
      preferences: preferences,
    );

    const first = Playlist(
      id: 'one',
      name: 'Sample playlist',
      trackPaths: ['D:/Music/one.flac'],
    );
    await repository.save(first);
    expect((await repository.loadAll()).single.name, 'Sample playlist');

    const replacement = Playlist(
      id: 'one',
      name: 'Updated',
      trackPaths: ['D:/Music/two.mp3'],
    );
    await repository.save(replacement);
    expect((await repository.loadAll()).single.trackPaths, [
      'D:/Music/two.mp3',
    ]);

    await repository.delete('one');
    expect(await repository.loadAll(), isEmpty);
  });

  test('persists automatic playlists and loads legacy manual data', () async {
    SharedPreferences.setMockInitialValues({
      'playlists':
          '[{"id":"legacy","name":"Legacy","trackPaths":["D:/one.flac"]}]',
    });
    final preferences = await SharedPreferences.getInstance();
    final repository = SharedPreferencesPlaylistRepository(
      preferences: preferences,
    );

    final legacy = (await repository.loadAll()).single;
    expect(legacy.type, PlaylistType.manual);

    await repository.save(
      const Playlist(
        id: 'auto',
        name: 'Matching tracks',
        type: PlaylistType.automatic,
        query: 'orchestra',
      ),
    );
    final automatic = (await repository.loadAll()).last;
    expect(automatic.type, PlaylistType.automatic);
    expect(automatic.query, 'orchestra');
    expect(automatic.trackPaths, isEmpty);
  });
}
