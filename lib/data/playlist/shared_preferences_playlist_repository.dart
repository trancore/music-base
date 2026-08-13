import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/playlist/playlist.dart';
import '../../domain/playlist/playlist_repository.dart';

class SharedPreferencesPlaylistRepository implements PlaylistRepository {
  const SharedPreferencesPlaylistRepository({required this.preferences});

  static const _key = 'playlists';
  static const _foldersKey = 'playlistFolders';
  final SharedPreferences preferences;

  @override
  Future<List<Playlist>> loadAll() async {
    final encoded = preferences.getString(_key);
    if (encoded == null) return const [];
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return const [];
      var legacyOrder = 0;
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
              autoRule: _autoRuleFromJson(entry['autoRule']),
              parentFolderId: entry['parentFolderId'] as String?,
              sortOrder: entry['sortOrder'] as int? ?? legacyOrder++,
            ),
          )
          .toList(growable: false);
    } on Object {
      return const [];
    }
  }

  @override
  Future<List<PlaylistFolder>> loadFolders() async {
    final encoded = preferences.getString(_foldersKey);
    if (encoded == null) return const [];
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map(
            (entry) => PlaylistFolder(
              id: entry['id'] as String,
              name: entry['name'] as String,
              parentFolderId: entry['parentFolderId'] as String?,
              sortOrder: entry['sortOrder'] as int? ?? 0,
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
        .toList();
    await saveAll(playlists);
  }

  @override
  Future<void> saveAll(List<Playlist> playlists) async {
    await preferences.setString(
      _key,
      jsonEncode(playlists.map(_playlistJson).toList()),
    );
  }

  @override
  Future<void> saveFolder(PlaylistFolder folder) async {
    final folders = (await loadFolders())
        .where((entry) => entry.id != folder.id)
        .followedBy([folder]);
    await preferences.setString(
      _foldersKey,
      jsonEncode(folders.map(_folderJson).toList()),
    );
  }

  @override
  Future<void> delete(String id) async {
    final playlists = (await loadAll()).where((entry) => entry.id != id);
    await preferences.setString(
      _key,
      jsonEncode(playlists.map(_playlistJson).toList()),
    );
  }

  @override
  Future<void> deleteFolder(String id) async {
    final folders = (await loadFolders()).where((entry) => entry.id != id);
    await preferences.setString(
      _foldersKey,
      jsonEncode(folders.map(_folderJson).toList()),
    );
  }

  Map<String, Object?> _playlistJson(Playlist entry) => {
    'id': entry.id,
    'name': entry.name,
    'trackPaths': entry.trackPaths,
    'type': entry.type.name,
    if (entry.query != null) 'query': entry.query,
    if (entry.autoRule != null)
      'autoRule': {
        'field': entry.autoRule!.field.name,
        'comparison': entry.autoRule!.comparison.name,
        'value': entry.autoRule!.value,
      },
    if (entry.parentFolderId != null) 'parentFolderId': entry.parentFolderId,
    'sortOrder': entry.sortOrder,
  };

  AutoPlaylistRule? _autoRuleFromJson(Object? value) {
    if (value is! Map) return null;
    final field = AutoPlaylistField.values
        .where((entry) => entry.name == value['field'])
        .firstOrNull;
    final comparison = AutoPlaylistComparison.values
        .where((entry) => entry.name == value['comparison'])
        .firstOrNull;
    final ruleValue = value['value'];
    if (field == null || comparison == null || ruleValue is! String) {
      return null;
    }
    return AutoPlaylistRule(
      field: field,
      comparison: comparison,
      value: ruleValue,
    );
  }

  Map<String, Object?> _folderJson(PlaylistFolder entry) => {
    'id': entry.id,
    'name': entry.name,
    if (entry.parentFolderId != null) 'parentFolderId': entry.parentFolderId,
    'sortOrder': entry.sortOrder,
  };
}
