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
  DateTime? lastScanCompletedAt;
  int? lastScanTrackCount;
  String? lastScanTargetPath;
  int _queryGeneration = 0;
  int _scanGeneration = 0;

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
      final tracks = await _repository.scanAndCache(path);
      ref.invalidate(libraryArtworkProvider);
      activeSourcePath = path;
      lastScanTargetPath = path;
      lastScanTrackCount = tracks.length;
      lastScanCompletedAt = DateTime.now();
    });
    await _refreshGroupsAfterScan();
  }

  Future<void> scanSmb() async {
    final source = await ref.read(smbSourceProvider.future);
    if (source == null) {
      refreshWarning = 'SMB library is not configured.';
      return;
    }
    final password =
        await ref.read(smbSettingsRepositoryProvider).loadPassword() ?? '';
    final path = source.librarySourceKey;
    sourcePath = path;
    lastScanTargetPath = source.displayPath;
    await _scanWithoutHidingCache(() async {
      final tracks = await _repository.scanSmbAndCache(source, password);
      ref.invalidate(libraryArtworkProvider);
      activeSourcePath = path;
      lastScanTrackCount = tracks.length;
      lastScanCompletedAt = DateTime.now();
    });
    await _refreshGroupsAfterScan();
  }

  Future<void> _scanWithoutHidingCache(Future<void> Function() scan) async {
    final generation = ++_scanGeneration;
    final cached = state.valueOrNull;
    isRefreshing = true;
    refreshWarning = null;
    if (cached != null) state = AsyncData(cached);
    try {
      await scan();
      if (generation != _scanGeneration) return;
      await _refreshVisiblePage();
    } catch (error, stackTrace) {
      if (generation != _scanGeneration) return;
      refreshWarning = 'Library scan failed: $error';
      state = cached != null
          ? AsyncData(cached)
          : AsyncError(error, stackTrace);
    } finally {
      if (generation == _scanGeneration) {
        isRefreshing = false;
        if (state case AsyncData(value: final visible)) {
          state = AsyncData(visible);
        }
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

  /// Restores the last local library when SMB settings are cleared.
  Future<void> restoreLocalSourceAfterSmbClear() async {
    if (sourcePath?.startsWith('smb://') != true) return;
    final local = await _repository.loadLastLocalSourcePath();
    if (local == null || local.isEmpty) return;
    sourcePath = local;
    activeSourcePath = local;
    await _repository.saveSourcePath(local);
    await _refreshVisiblePage();
  }

  Future<void> refreshInBackground() async {
    final primary = sourcePath;
    if (primary == null || primary.isEmpty || isRefreshing) return;
    // SMB rescans walk the share over the network and can take a long time.
    // When cached tracks are already available, defer refresh to manual scans.
    if (primary.startsWith('smb://') && totalCount > 0) return;
    final generation = ++_scanGeneration;
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
        lastScanTargetPath = source.displayPath;
        final tracks = await _repository
            .scanSmbAndCache(source, password)
            .timeout(const Duration(minutes: 5));
        ref.invalidate(libraryArtworkProvider);
        activeSourcePath = primary;
        lastScanTrackCount = tracks.length;
        lastScanCompletedAt = DateTime.now();
      } else {
        final tracks = await _repository.scanAndCache(primary);
        ref.invalidate(libraryArtworkProvider);
        activeSourcePath = primary;
        lastScanTargetPath = primary;
        lastScanTrackCount = tracks.length;
        lastScanCompletedAt = DateTime.now();
      }
      if (generation != _scanGeneration) return;
      await _refreshVisiblePage();
      await _refreshGroupsAfterScan();
    } on Object catch (error) {
      if (generation != _scanGeneration) return;
      activeSourcePath = primary;
      refreshWarning = primary.startsWith('smb://')
          ? 'SMB library refresh failed: $error'
          : 'Library not found.';
      state = cached != null
          ? AsyncData(cached)
          : AsyncError(StateError(refreshWarning!), StackTrace.current);
    } finally {
      if (generation == _scanGeneration) {
        isRefreshing = false;
        if (state case AsyncData(value: final visible)) {
          state = AsyncData(visible);
        }
      }
    }
  }

  Future<void> _refreshGroupsAfterScan() async {
    if (refreshWarning != null) return;
    final groupsNotifier = ref.read(libraryGroupsProvider.notifier);
    await groupsNotifier.setQuery(
      kind: groupsNotifier.kind,
      search: groupsNotifier.search,
    );
  }
}
