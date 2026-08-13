import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/playlist/playlist.dart';
import '../../domain/playlist/playlist_repository.dart';

class SharedPreferencesPlaylistRepository implements PlaylistRepository {
  const SharedPreferencesPlaylistRepository({required this.preferences});

  static const _key = 'playlists';
  final SharedPreferences preferences;

  @override
  Future<List<Playlist>> loadAll() async {
    final encoded = preferences.getString(_key);
    if (encoded == null) return const [];
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map(
            (entry) => Playlist(
              id: entry['id'] as String,
              name: entry['name'] as String,
              trackPaths: (entry['trackPaths'] as List? ?? const [])
                  .whereType<String>()
                  .toList(),
              type: entry['type'] == PlaylistType.automatic.name
                  ? PlaylistType.automatic
                  : PlaylistType.manual,
              query: entry['query'] as String?,
            ),
          )
          .toList(growable: false);
    } on Object {
      return const [];
    }
  }

  @override
  Future<void> save(Playlist playlist) async {
    final playlists = (await loadAll())
        .where((entry) => entry.id != playlist.id)
        .followedBy([playlist])
        .map(
          (entry) => {
            'id': entry.id,
            'name': entry.name,
            'trackPaths': entry.trackPaths,
            'type': entry.type.name,
            if (entry.query != null) 'query': entry.query,
          },
        )
        .toList();
    await preferences.setString(_key, jsonEncode(playlists));
  }

  @override
  Future<void> delete(String id) async {
    final playlists = (await loadAll()).where((entry) => entry.id != id);
    await preferences.setString(
      _key,
      jsonEncode(
        playlists
            .map(
              (entry) => {
                'id': entry.id,
                'name': entry.name,
                'trackPaths': entry.trackPaths,
                'type': entry.type.name,
                if (entry.query != null) 'query': entry.query,
              },
            )
            .toList(),
      ),
    );
  }
}
