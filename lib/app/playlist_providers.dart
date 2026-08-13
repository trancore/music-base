import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/playlist/shared_preferences_playlist_repository.dart';
import '../domain/library/library_track.dart';
import '../domain/library/library_query.dart';
import '../domain/playlist/playlist.dart';
import '../domain/playlist/playlist_repository.dart';
import 'library_providers.dart';
import 'playlist_import_resolver.dart';
import 'providers.dart';

final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  return SharedPreferencesPlaylistRepository(
    preferences: ref.watch(sharedPreferencesProvider),
  );
});

final playlistProvider =
    AsyncNotifierProvider<PlaylistNotifier, List<Playlist>>(
      PlaylistNotifier.new,
    );

final playlistFoldersProvider = FutureProvider<List<PlaylistFolder>>((ref) {
  ref.watch(playlistProvider);
  return ref.watch(playlistRepositoryProvider).loadFolders();
});

final playlistImportResolverProvider = Provider<PlaylistImportResolver>((ref) {
  return PlaylistImportResolver(ref.watch(libraryRepositoryProvider));
});

final resolvedPlaylistTracksProvider = FutureProvider.autoDispose
    .family<List<LibraryTrack>, Playlist>((ref, playlist) async {
      ref.watch(libraryProvider);
      final repository = ref.watch(libraryRepositoryProvider);
      if (!playlist.isAutomatic) {
        return repository.resolveTrackPaths(playlist.trackPaths);
      }

      final sourceKey = await repository.loadSourcePath();
      final tracks = <LibraryTrack>[];
      LibraryCursor? cursor;
      do {
        final page = await repository.queryTracks(
          LibraryQuery(
            sourceKey: sourceKey,
            search: playlist.query ?? '',
            pageSize: 500,
            cursor: cursor,
          ),
        );
        tracks.addAll(page.items);
        cursor = page.nextCursor;
      } while (cursor != null);
      return List.unmodifiable(tracks);
    });

class PlaylistNotifier extends AsyncNotifier<List<Playlist>> {
  late final PlaylistRepository _repository;

  @override
  Future<List<Playlist>> build() {
    _repository = ref.watch(playlistRepositoryProvider);
    return _repository.loadAll();
  }

  Future<void> create(
    String name,
    List<LibraryTrack> tracks, {
    String? parentFolderId,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || tracks.isEmpty) return;
    final playlist = Playlist(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: trimmedName,
      trackPaths: tracks
          .map((track) => track.sourcePath)
          .toList(growable: false),
      parentFolderId: parentFolderId,
      sortOrder: await _nextSortOrder(parentFolderId),
    );
    await _repository.save(playlist);
    state = AsyncData(await _repository.loadAll());
  }

  Future<void> createFromPaths(
    String name,
    List<String> trackPaths, {
    String? parentFolderId,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || trackPaths.isEmpty) return;
    await _repository.save(
      Playlist(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: trimmedName,
        trackPaths: List.unmodifiable(trackPaths),
        parentFolderId: parentFolderId,
        sortOrder: await _nextSortOrder(parentFolderId),
      ),
    );
    state = AsyncData(await _repository.loadAll());
  }

  Future<void> createAutomatic(
    String name,
    String query, {
    String? parentFolderId,
  }) async {
    final trimmedName = name.trim();
    final trimmedQuery = query.trim();
    if (trimmedName.isEmpty || trimmedQuery.isEmpty) return;
    await _repository.save(
      Playlist(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: trimmedName,
        type: PlaylistType.automatic,
        query: trimmedQuery,
        parentFolderId: parentFolderId,
        sortOrder: await _nextSortOrder(parentFolderId),
      ),
    );
    state = AsyncData(await _repository.loadAll());
  }

  Future<void> importPlaylist(
    String name,
    List<String> trackPaths, {
    String? parentFolderId,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || trackPaths.isEmpty) return;
    await _repository.save(
      Playlist(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: trimmedName,
        trackPaths: List.unmodifiable(trackPaths),
        parentFolderId: parentFolderId,
        sortOrder: await _nextSortOrder(parentFolderId),
      ),
    );
    state = AsyncData(await _repository.loadAll());
  }

  Future<void> updatePlaylist(
    String id,
    String name,
    List<LibraryTrack> tracks,
  ) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || tracks.isEmpty) return;
    final playlist = Playlist(
      id: id,
      name: trimmedName,
      trackPaths: tracks
          .map((track) => track.sourcePath)
          .toList(growable: false),
      parentFolderId: _playlist(id)?.parentFolderId,
      sortOrder: _playlist(id)?.sortOrder ?? 0,
    );
    await _repository.save(playlist);
    state = AsyncData(await _repository.loadAll());
  }

  Future<void> updatePlaylistPaths(
    String id,
    String name,
    List<String> trackPaths,
  ) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || trackPaths.isEmpty) return;
    await _repository.save(
      Playlist(
        id: id,
        name: trimmedName,
        trackPaths: List.unmodifiable(trackPaths),
        parentFolderId: _playlist(id)?.parentFolderId,
        sortOrder: _playlist(id)?.sortOrder ?? 0,
      ),
    );
    state = AsyncData(await _repository.loadAll());
  }

  Future<void> updateAutomatic(String id, String name, String query) async {
    final trimmedName = name.trim();
    final trimmedQuery = query.trim();
    if (trimmedName.isEmpty || trimmedQuery.isEmpty) return;
    await _repository.save(
      Playlist(
        id: id,
        name: trimmedName,
        type: PlaylistType.automatic,
        query: trimmedQuery,
        parentFolderId: _playlist(id)?.parentFolderId,
        sortOrder: _playlist(id)?.sortOrder ?? 0,
      ),
    );
    state = AsyncData(await _repository.loadAll());
  }

  Future<void> delete(String id) async {
    final playlists = await _repository.loadAll();
    final deleting = playlists.where((entry) => entry.id == id).firstOrNull;
    if (deleting == null) return;
    final remaining = playlists.where((entry) => entry.id != id).toList();
    _normalizePlaylistOrders(remaining, {deleting.parentFolderId});
    await _repository.saveAll(remaining);
    state = AsyncData(List.unmodifiable(remaining));
  }

  Future<void> createFolder(String name, {String? parentFolderId}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final folders = await _repository.loadFolders();
    await _repository.saveFolder(
      PlaylistFolder(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: trimmed,
        parentFolderId: parentFolderId,
        sortOrder: _nextFolderSortOrder(folders, parentFolderId),
      ),
    );
    await _refresh();
  }

  Future<void> updateFolder(
    String id,
    String name, {
    String? parentFolderId,
    bool moveToRoot = false,
  }) async {
    final folders = await _repository.loadFolders();
    final folder = folders.where((entry) => entry.id == id).firstOrNull;
    final trimmed = name.trim();
    if (folder == null || trimmed.isEmpty) return;
    if (parentFolderId == id ||
        _descendantIds(id, folders).contains(parentFolderId)) {
      return;
    }
    final destinationParent = moveToRoot
        ? null
        : parentFolderId ?? folder.parentFolderId;
    final changesParent = destinationParent != folder.parentFolderId;
    if (destinationParent != null &&
        !folders.any((entry) => entry.id == destinationParent)) {
      return;
    }
    await _repository.saveFolder(
      folder.copyWith(
        name: trimmed,
        parentFolderId: parentFolderId,
        moveToRoot: moveToRoot,
        sortOrder: changesParent
            ? _nextFolderSortOrder(folders, destinationParent)
            : folder.sortOrder,
      ),
    );
    if (changesParent) {
      await _normalizeFolderOrders({folder.parentFolderId, destinationParent});
    }
    await _refresh();
  }

  Future<bool> deleteFolder(String id) async {
    final folders = await _repository.loadFolders();
    final playlists = await _repository.loadAll();
    final hasChildren =
        folders.any((folder) => folder.parentFolderId == id) ||
        playlists.any((playlist) => playlist.parentFolderId == id);
    if (hasChildren) return false;
    final deleting = folders.where((folder) => folder.id == id).firstOrNull;
    if (deleting == null) return false;
    await _repository.deleteFolder(id);
    await _normalizeFolderOrders({deleting.parentFolderId});
    await _refresh();
    return true;
  }

  Future<void> movePlaylist(
    String id,
    String? targetFolderId, {
    int? targetIndex,
  }) async {
    final playlists = await _repository.loadAll();
    final moving = playlists.where((entry) => entry.id == id).firstOrNull;
    if (moving == null) return;
    if (targetFolderId != null &&
        !(await _repository.loadFolders()).any(
          (folder) => folder.id == targetFolderId,
        )) {
      return;
    }
    final originalSiblings =
        playlists
            .where((entry) => entry.parentFolderId == targetFolderId)
            .toList()
          ..sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
    final sourceIndex = moving.parentFolderId == targetFolderId
        ? originalSiblings.indexWhere((entry) => entry.id == id)
        : -1;
    final siblings = originalSiblings.where((entry) => entry.id != id).toList();
    var requestedIndex = targetIndex ?? siblings.length;
    if (sourceIndex >= 0 && sourceIndex < requestedIndex) requestedIndex--;
    final index = requestedIndex.clamp(0, siblings.length);
    siblings.insert(
      index,
      moving.copyWith(
        parentFolderId: targetFolderId,
        moveToRoot: targetFolderId == null,
      ),
    );
    final reordered = {
      for (var i = 0; i < siblings.length; i++)
        siblings[i].id: siblings[i].copyWith(sortOrder: i),
    };
    final updated = [
      for (final playlist in playlists) reordered[playlist.id] ?? playlist,
    ];
    if (moving.parentFolderId != targetFolderId) {
      _normalizePlaylistOrders(updated, {moving.parentFolderId});
    }
    await _repository.saveAll(updated);
    state = AsyncData(List.unmodifiable(updated));
  }

  Playlist? _playlist(String id) =>
      state.valueOrNull?.where((entry) => entry.id == id).firstOrNull;

  Future<int> _nextSortOrder(String? parentFolderId) async {
    final siblings = (await _repository.loadAll()).where(
      (entry) => entry.parentFolderId == parentFolderId,
    );
    return siblings.fold<int>(
      0,
      (next, entry) => entry.sortOrder >= next ? entry.sortOrder + 1 : next,
    );
  }

  int _nextFolderSortOrder(
    List<PlaylistFolder> folders,
    String? parentFolderId,
  ) => folders
      .where((entry) => entry.parentFolderId == parentFolderId)
      .fold<int>(
        0,
        (next, entry) => entry.sortOrder >= next ? entry.sortOrder + 1 : next,
      );

  void _normalizePlaylistOrders(
    List<Playlist> playlists,
    Set<String?> parentFolderIds,
  ) {
    for (final parentFolderId in parentFolderIds) {
      final siblings =
          playlists
              .where((entry) => entry.parentFolderId == parentFolderId)
              .toList()
            ..sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
      for (var index = 0; index < siblings.length; index++) {
        final position = playlists.indexWhere(
          (entry) => entry.id == siblings[index].id,
        );
        playlists[position] = siblings[index].copyWith(sortOrder: index);
      }
    }
  }

  Future<void> _normalizeFolderOrders(Set<String?> parentFolderIds) async {
    final folders = await _repository.loadFolders();
    for (final parentFolderId in parentFolderIds) {
      final siblings =
          folders
              .where((entry) => entry.parentFolderId == parentFolderId)
              .toList()
            ..sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
      for (var index = 0; index < siblings.length; index++) {
        if (siblings[index].sortOrder != index) {
          await _repository.saveFolder(
            siblings[index].copyWith(sortOrder: index),
          );
        }
      }
    }
  }

  Set<String> _descendantIds(String id, List<PlaylistFolder> folders) {
    final result = <String>{};
    void collect(String parent) {
      for (final folder in folders.where(
        (entry) => entry.parentFolderId == parent,
      )) {
        if (result.add(folder.id)) collect(folder.id);
      }
    }

    collect(id);
    return result;
  }

  Future<void> _refresh() async {
    state = AsyncData(await _repository.loadAll());
  }
}
