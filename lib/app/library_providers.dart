import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../data/library/local_directory_library_scanner.dart';
import '../data/library/default_local_directory_access_service.dart';
import '../data/library/macos_local_directory_access_service.dart';
import '../data/library/shared_preferences_library_repository.dart';
import '../data/library/smb_library_scanner.dart';
import '../domain/library/library_repository.dart';
import '../domain/library/local_directory_access_service.dart';
import '../domain/library/library_query.dart';
import '../domain/library/library_track.dart';
import 'providers.dart';
import 'smb_providers.dart';

part 'library_group_providers.dart';

final libraryScannerProvider = Provider(
  (ref) => const LocalDirectoryLibraryScanner(),
);

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return SharedPreferencesLibraryRepository(
    preferences: ref.watch(sharedPreferencesProvider),
    database: ref.watch(appDatabaseProvider),
    scanner: ref.watch(libraryScannerProvider),
    smbScanner: ref.watch(smbLibraryScannerProvider),
    directoryAccess: ref.watch(localDirectoryAccessServiceProvider),
  );
});

final localDirectoryAccessServiceProvider =
    Provider<LocalDirectoryAccessService>((ref) {
      if (defaultTargetPlatform == TargetPlatform.macOS) {
        return MacosLocalDirectoryAccessService();
      }
      return const DefaultLocalDirectoryAccessService();
    });

final smbLibraryScannerProvider = Provider((ref) => const SmbLibraryScanner());

final libraryProvider =
    AsyncNotifierProvider<LibraryNotifier, List<LibraryTrack>>(
      LibraryNotifier.new,
    );

final librarySearchQueryProvider = StateProvider<String>((ref) => '');

final libraryArtworkProvider = FutureProvider.family<List<int>?, int>((
  ref,
  id,
) {
  return ref.watch(libraryRepositoryProvider).loadArtwork(id);
});

class LibraryNotifier extends AsyncNotifier<List<LibraryTrack>> {
  late final LibraryRepository _repository;

  String? sourcePath;
  String? activeSourcePath;
  LibraryQuery query = const LibraryQuery();
  LibraryQuery get effectiveQuery => LibraryQuery(
    sourceKey: activeSourcePath,
    search: query.search,
    sortField: query.sortField,
    ascending: query.ascending,
    album: query.album,
    artist: query.artist,
  );
  int totalCount = 0;
  LibraryCursor? _nextCursor;
  bool isLoadingMore = false;
  bool isRefreshing = false;
  String? refreshWarning;
  int _queryGeneration = 0;

  @override
  Future<List<LibraryTrack>> build() async {
    _repository = ref.watch(libraryRepositoryProvider);
    sourcePath = await _repository.loadSourcePath();
    activeSourcePath = sourcePath;
    final tracks = await _reloadFirstPage();
    final refreshTimer = Timer(const Duration(seconds: 1), refreshInBackground);
    ref.onDispose(refreshTimer.cancel);
    return tracks;
  }

  Future<List<LibraryTrack>> _reloadFirstPage() async {
    final page = await _repository.queryTracks(effectiveQuery);
    _applyPage(page);
    return page.items;
  }

  Future<void> _refreshVisiblePage() async {
    final generation = ++_queryGeneration;
    final page = await _repository.queryTracks(effectiveQuery);
    if (generation != _queryGeneration) return;
    _applyPage(page);
    state = AsyncData(page.items);
  }

  void _applyPage(LibraryPage page) {
    totalCount = page.totalCount;
    _nextCursor = page.nextCursor;
  }

  Future<void> setQuery({
    String? search,
    LibrarySortField? sortField,
    bool? ascending,
    String? album,
    String? artist,
    bool clearGroup = false,
  }) async {
    final nextQuery = LibraryQuery(
      sourceKey: activeSourcePath,
      search: search ?? query.search,
      sortField: sortField ?? query.sortField,
      ascending: ascending ?? query.ascending,
      album: clearGroup ? null : album ?? query.album,
      artist: clearGroup ? null : artist ?? query.artist,
    );
    query = nextQuery;
    final generation = ++_queryGeneration;
    isLoadingMore = false;
    state = const AsyncLoading<List<LibraryTrack>>().copyWithPrevious(state);
    try {
      final page = await _repository.queryTracks(effectiveQuery);
      if (generation != _queryGeneration) return;
      _applyPage(page);
      state = AsyncData(page.items);
    } catch (error, stackTrace) {
      if (generation == _queryGeneration) {
        state = AsyncError(error, stackTrace);
      }
    }
  }

  Future<void> setGroup(LibraryGroup? group) => setQuery(
    search: '',
    sortField: group == null
        ? LibrarySortField.title
        : group.kind == LibraryGroupKind.artist
        ? LibrarySortField.album
        : LibrarySortField.albumTrack,
    ascending: true,
    album: group?.kind == LibraryGroupKind.album ? group!.value : null,
    artist: group?.kind == LibraryGroupKind.artist ? group!.value : null,
    clearGroup: group == null,
  );

  Future<void> loadNextPage() async {
    final cursor = _nextCursor;
    if (cursor == null || isLoadingMore) return;
    final generation = _queryGeneration;
    final currentQuery = effectiveQuery;
    isLoadingMore = true;
    try {
      final page = await _repository.queryTracks(
        LibraryQuery(
          sourceKey: currentQuery.sourceKey,
          search: currentQuery.search,
          sortField: currentQuery.sortField,
          ascending: currentQuery.ascending,
          cursor: cursor,
          album: currentQuery.album,
          artist: currentQuery.artist,
        ),
      );
      if (generation != _queryGeneration) return;
      _nextCursor = page.nextCursor;
      totalCount = page.totalCount;
      state = AsyncData([
        ...state.valueOrNull ?? const <LibraryTrack>[],
        ...page.items,
      ]);
    } finally {
      isLoadingMore = false;
    }
  }

  Future<void> chooseDirectory() async {
    // The UI supplies the platform picker result through scanDirectory.
  }

  /// Starts a scan for a directory explicitly selected by the user.
  ///
  /// On macOS the picker grants access to the selected directory. Persisting
  /// that new security-scoped bookmark before scanning is important when the
  /// user changes from a parent directory to one of its children.
  Future<void> selectDirectory(String path) async {
    await _repository.saveSourcePath(path);
    await scanDirectory(path);
  }

  Future<void> scanDirectory(String path) async {
    sourcePath = path;
    await _scanWithoutHidingCache(() async {
      await _repository.scanAndCache(path);
      ref.invalidate(libraryArtworkProvider);
      activeSourcePath = path;
    });
  }

  Future<void> scanSmb() async {
    final source = await ref.read(smbSourceProvider.future);
    if (source == null) return;
    final password =
        await ref.read(smbSettingsRepositoryProvider).loadPassword() ?? '';
    final path = 'smb://${source.host}/${source.share}';
    sourcePath = path;
    await _scanWithoutHidingCache(() async {
      await _repository.scanSmbAndCache(source, password);
      ref.invalidate(libraryArtworkProvider);
      activeSourcePath = path;
    });
  }

  Future<void> _scanWithoutHidingCache(Future<void> Function() scan) async {
    if (isRefreshing) return;
    final cached = state.valueOrNull;
    isRefreshing = true;
    refreshWarning = null;
    if (cached != null) state = AsyncData(cached);
    try {
      await scan();
      await _refreshVisiblePage();
    } catch (error, stackTrace) {
      refreshWarning = 'Library scan failed: $error';
      state = cached != null
          ? AsyncData(cached)
          : AsyncError(error, stackTrace);
    } finally {
      isRefreshing = false;
      if (state case AsyncData(value: final visible)) {
        state = AsyncData(visible);
      }
    }
  }

  Future<void> rescan() async {
    final path = sourcePath;
    if (path == null || path.isEmpty) return;
    if (path.startsWith('smb://')) {
      await scanSmb();
    } else {
      await scanDirectory(path);
    }
  }

  Future<void> refreshInBackground() async {
    final primary = sourcePath;
    if (primary == null || primary.isEmpty || isRefreshing) return;
    isRefreshing = true;
    refreshWarning = null;
    final cached = state.valueOrNull;
    if (cached != null) state = AsyncData(cached);
    try {
      if (primary.startsWith('smb://')) {
        final source = await ref.read(smbSourceProvider.future);
        if (source == null) throw StateError('SMB library is not configured.');
        final password =
            await ref.read(smbSettingsRepositoryProvider).loadPassword() ?? '';
        await _repository.scanSmbAndCache(source, password);
        ref.invalidate(libraryArtworkProvider);
        activeSourcePath = primary;
      } else {
        await _repository.scanAndCache(primary);
        ref.invalidate(libraryArtworkProvider);
        activeSourcePath = primary;
      }
      await _refreshVisiblePage();
    } on Object {
      if (primary.startsWith('smb://')) {
        final local = await _repository.loadLastLocalSourcePath();
        if (local != null && local.isNotEmpty) {
          try {
            await _repository.scanFallbackLocal(local);
            ref.invalidate(libraryArtworkProvider);
            activeSourcePath = local;
            refreshWarning =
                'SMB library is unavailable. Using the local library.';
            await _refreshVisiblePage();
            return;
          } on Object {
            // Report the common terminal state below.
          }
        }
      }
      refreshWarning = 'Library not found.';
      state = cached != null
          ? AsyncData(cached)
          : AsyncError(StateError(refreshWarning!), StackTrace.current);
    } finally {
      isRefreshing = false;
      if (state case AsyncData(value: final visible)) {
        state = AsyncData(visible);
      }
    }
  }
}
