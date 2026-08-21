import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/library_providers.dart';
import '../../app/playback_providers.dart';
import '../../app/smb_providers.dart';
import '../../domain/library/library_audio_formats.dart';
import '../../data/playback/library_playback_queue.dart';
import '../../domain/library/library_query.dart';
import '../../domain/library/library_track.dart';
import '../../domain/playback/playback_service.dart';

part 'home_group_widgets.dart';
part 'home_track_widgets.dart';

enum _LibraryViewMode { songs, albums, artists }

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _searchQuery = '';
  int _sortColumn = 0;
  bool _sortAscending = true;
  Timer? _searchDebounce;
  _LibraryViewMode _viewMode = _LibraryViewMode.songs;
  LibraryGroup? _selectedGroup;
  DateTime? _readyBannerHiddenSinceScanAt;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(libraryProvider);
    final groups = ref.watch(libraryGroupsProvider);
    final playback = ref.watch(playbackServiceProvider);
    final snapshot = playback.snapshot;
    final tracks = library.valueOrNull ?? const <LibraryTrack>[];
    final filteredTracks = tracks;
    final libraryNotifier = ref.read(libraryProvider.notifier);
    final refreshWarning = libraryNotifier.refreshWarning;
    final groupNotifier = ref.read(libraryGroupsProvider.notifier);
    final showTracks =
        _viewMode == _LibraryViewMode.songs || _selectedGroup != null;
    final isCompact = MediaQuery.sizeOf(context).width < 700;
    final hasActivePlayback =
        snapshot.currentTrack != null || snapshot.currentRadioStation != null;
    final showLoadStatusBanner =
        isCompact && _shouldShowLoadStatusBanner(libraryNotifier);

    return Scaffold(
      primary: !(isCompact && hasActivePlayback),
      appBar: isCompact
          ? AppBar(
              primary: !hasActivePlayback,
              title: const Text('Library'),
              actions: [
                IconButton(
                  tooltip: 'Search library',
                  onPressed: () => _searchFocusNode.requestFocus(),
                  icon: const Icon(Icons.search),
                ),
              ],
            )
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth < 700 ? 16.0 : 32.0;
          final compactHeight = constraints.maxHeight < 300;
          return Column(
            children: [
              if (!compactHeight && !isCompact)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    28,
                    horizontalPadding,
                    0,
                  ),
                  child: _PageIntro(
                    eyebrow: 'COLLECTION',
                    title: 'Music library',
                    subtitle: 'Your local and network music, ready to play.',
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  isCompact ? 4 : (compactHeight ? 8 : 22),
                  horizontalPadding,
                  isCompact ? 8 : 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<_LibraryViewMode>(
                        segments: const [
                          ButtonSegment(
                            value: _LibraryViewMode.songs,
                            icon: Icon(Icons.music_note_outlined),
                            label: Text('Songs'),
                          ),
                          ButtonSegment(
                            value: _LibraryViewMode.albums,
                            icon: Icon(Icons.album_outlined),
                            label: Text('Albums'),
                          ),
                          ButtonSegment(
                            value: _LibraryViewMode.artists,
                            icon: Icon(Icons.person_outline),
                            label: Text('Artists'),
                          ),
                        ],
                        selected: {_viewMode},
                        onSelectionChanged: (selection) {
                          _changeView(
                            selection.single,
                            libraryNotifier,
                            groupNotifier,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_selectedGroup case final selectedGroup?) ...[
                      Row(
                        children: [
                          IconButton(
                            tooltip:
                                'Back to ${_viewMode == _LibraryViewMode.albums ? 'albums' : 'artists'}',
                            onPressed: () =>
                                _closeGroup(libraryNotifier, groupNotifier),
                            icon: const Icon(Icons.arrow_back),
                          ),
                          Expanded(
                            child: Text(
                              selectedGroup.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            decoration: InputDecoration(
                              hintText: 'Search title, artist, album...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchQuery.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Clear search',
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                        _applySearch(
                                          '',
                                          showTracks,
                                          libraryNotifier,
                                          groupNotifier,
                                        );
                                      },
                                      icon: const Icon(Icons.clear),
                                    ),
                            ),
                            onChanged: (value) {
                              setState(() => _searchQuery = value);
                              _searchDebounce?.cancel();
                              _searchDebounce = Timer(
                                const Duration(milliseconds: 250),
                                () => _applySearch(
                                  value,
                                  showTracks,
                                  libraryNotifier,
                                  groupNotifier,
                                ),
                              );
                            },
                          ),
                        ),
                        if (showTracks && filteredTracks.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: () async {
                              final repository = ref.read(
                                libraryRepositoryProvider,
                              );
                              final queue = await repository
                                  .createPlaybackQueue(
                                    libraryNotifier.effectiveQuery,
                                  );
                              if (queue.length == 0) return;
                              await playback.playLazyQueue(
                                LibraryPlaybackQueue(repository, queue),
                              );
                            },
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Play all'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (showLoadStatusBanner)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    4,
                  ),
                  child: _LibraryLoadStatusBanner(
                    onDismiss: _isLibraryReady(libraryNotifier)
                        ? () => setState(
                            () => _readyBannerHiddenSinceScanAt =
                                libraryNotifier.lastScanCompletedAt ??
                                DateTime.now(),
                          )
                        : null,
                  ),
                )
              else if (libraryNotifier.isRefreshing)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: isCompact
                    ? _buildCompactLibraryBody(
                        context: context,
                        library: library,
                        groups: groups,
                        tracks: filteredTracks,
                        showTracks: showTracks,
                        refreshWarning: refreshWarning,
                        libraryNotifier: libraryNotifier,
                        groupNotifier: groupNotifier,
                        snapshot: snapshot,
                        playback: playback,
                      )
                    : LayoutBuilder(
                        builder: (context, contentConstraints) => ListView(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            0,
                            horizontalPadding,
                            28,
                          ),
                          children: [
                            if (!library.hasError && refreshWarning != null)
                              Card(
                                color: Theme.of(
                                  context,
                                ).colorScheme.tertiaryContainer,
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.warning_amber_outlined,
                                  ),
                                  title: const Text(
                                    'Library refresh incomplete',
                                  ),
                                  subtitle: Text(refreshWarning),
                                  trailing: TextButton(
                                    onPressed: libraryNotifier.isRefreshing
                                        ? null
                                        : libraryNotifier.rescan,
                                    child: const Text('Retry'),
                                  ),
                                ),
                              ),
                            if (!showTracks)
                              _LibraryGroupGrid(
                                groups: groups.valueOrNull ?? const [],
                                totalCount: groupNotifier.totalCount,
                                isLoading: groups.isLoading,
                                error: groups.error,
                                availableHeight: contentConstraints.maxHeight,
                                expandToFill: false,
                                onNearEnd: groupNotifier.loadNextPage,
                                onOpen: (group) =>
                                    _openGroup(group, libraryNotifier),
                                onPlay: (group) => _playGroup(group, playback),
                              )
                            else if (library.isLoading && tracks.isEmpty)
                              const Center(child: CircularProgressIndicator())
                            else if (library.hasError)
                              Card(
                                color: Theme.of(
                                  context,
                                ).colorScheme.errorContainer,
                                child: ListTile(
                                  leading: const Icon(Icons.error_outline),
                                  title: Text(
                                    libraryNotifier.refreshWarning ==
                                            'Library not found.'
                                        ? 'Library not found'
                                        : 'Library scan failed',
                                  ),
                                  subtitle: Text(library.error.toString()),
                                  trailing: TextButton(
                                    onPressed: () => ref
                                        .read(libraryProvider.notifier)
                                        .rescan(),
                                    child: const Text('Retry'),
                                  ),
                                ),
                              )
                            else if (tracks.isEmpty)
                              const Card(
                                child: ListTile(
                                  leading: Icon(Icons.music_off),
                                  title: Text(
                                    'No $kSupportedLibraryFormatsDescription files found',
                                  ),
                                  subtitle: Text(
                                    'Choose a directory containing your music files.',
                                  ),
                                ),
                              )
                            else if (filteredTracks.isEmpty)
                              const Card(
                                child: ListTile(
                                  leading: Icon(Icons.search_off),
                                  title: Text('No matching tracks'),
                                  subtitle: Text(
                                    'Try a different search term.',
                                  ),
                                ),
                              )
                            else
                              _TrackTable(
                                tracks: filteredTracks,
                                currentPath: snapshot.currentTrack?.sourcePath,
                                availableWidth: constraints.maxWidth,
                                availableHeight: contentConstraints.maxHeight,
                                sortColumn: _sortColumn,
                                sortAscending: _sortAscending,
                                onSort: (column) {
                                  setState(() {
                                    if (_sortColumn == column) {
                                      _sortAscending = !_sortAscending;
                                    } else {
                                      _sortColumn = column;
                                      _sortAscending = true;
                                    }
                                  });
                                  libraryNotifier.setQuery(
                                    sortField: LibrarySortField.values[column],
                                    ascending: _sortAscending,
                                  );
                                },
                                onDoubleTap: playback.playTrack,
                                onNearEnd: libraryNotifier.loadNextPage,
                              ),
                          ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _isLibraryReady(LibraryNotifier notifier) =>
      !notifier.isRefreshing &&
      notifier.refreshWarning == null &&
      notifier.totalCount > 0;

  bool _shouldShowLoadStatusBanner(LibraryNotifier notifier) {
    if (notifier.isRefreshing ||
        notifier.refreshWarning != null ||
        notifier.totalCount == 0) {
      return true;
    }
    final hiddenSince = _readyBannerHiddenSinceScanAt;
    if (hiddenSince == null) return true;
    final lastScan = notifier.lastScanCompletedAt;
    if (lastScan == null) return false;
    return lastScan.isAfter(hiddenSince);
  }

  void _applySearch(
    String value,
    bool showTracks,
    LibraryNotifier libraryNotifier,
    LibraryGroupsNotifier groupNotifier,
  ) {
    if (showTracks) {
      unawaited(libraryNotifier.setQuery(search: value));
    } else {
      unawaited(groupNotifier.setQuery(search: value));
    }
  }

  void _changeView(
    _LibraryViewMode mode,
    LibraryNotifier libraryNotifier,
    LibraryGroupsNotifier groupNotifier,
  ) {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {
      _viewMode = mode;
      _selectedGroup = null;
      _searchQuery = '';
      _sortColumn = 0;
      _sortAscending = true;
    });
    unawaited(libraryNotifier.setGroup(null));
    if (mode != _LibraryViewMode.songs) {
      unawaited(
        groupNotifier.setQuery(
          kind: mode == _LibraryViewMode.albums
              ? LibraryGroupKind.album
              : LibraryGroupKind.artist,
          search: '',
        ),
      );
    }
  }

  void _openGroup(LibraryGroup group, LibraryNotifier notifier) {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {
      _selectedGroup = group;
      _searchQuery = '';
      _sortColumn = group.kind == LibraryGroupKind.artist ? 2 : -1;
      _sortAscending = true;
    });
    unawaited(notifier.setGroup(group));
  }

  void _closeGroup(
    LibraryNotifier libraryNotifier,
    LibraryGroupsNotifier groupNotifier,
  ) {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {
      _selectedGroup = null;
      _searchQuery = '';
      _sortColumn = 0;
      _sortAscending = true;
    });
    unawaited(libraryNotifier.setGroup(null));
    unawaited(groupNotifier.setQuery(search: ''));
  }

  Future<void> _playGroup(LibraryGroup group, PlaybackService playback) async {
    final repository = ref.read(libraryRepositoryProvider);
    final source = ref.read(libraryProvider.notifier).activeSourcePath;
    final queue = await repository.createPlaybackQueue(
      group.tracksQuery(sourceKey: source),
    );
    if (queue.length == 0) return;
    await playback.playLazyQueue(LibraryPlaybackQueue(repository, queue));
  }

  Widget _buildCompactLibraryBody({
    required BuildContext context,
    required AsyncValue<List<LibraryTrack>> library,
    required AsyncValue<List<LibraryGroup>> groups,
    required List<LibraryTrack> tracks,
    required bool showTracks,
    required String? refreshWarning,
    required LibraryNotifier libraryNotifier,
    required LibraryGroupsNotifier groupNotifier,
    required PlaybackSnapshot snapshot,
    required PlaybackService playback,
  }) {
    final horizontalPadding = MediaQuery.sizeOf(context).width < 700
        ? 16.0
        : 32.0;
    final header = <Widget>[
      if (!library.hasError && refreshWarning != null)
        Card(
          color: Theme.of(context).colorScheme.tertiaryContainer,
          child: ListTile(
            leading: const Icon(Icons.warning_amber_outlined),
            title: const Text('Library refresh incomplete'),
            subtitle: Text(refreshWarning),
            trailing: TextButton(
              onPressed: libraryNotifier.isRefreshing
                  ? null
                  : libraryNotifier.rescan,
              child: const Text('Retry'),
            ),
          ),
        ),
    ];

    if (!showTracks) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          0,
          horizontalPadding,
          8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...header,
            Expanded(
              child: _LibraryGroupGrid(
                groups: groups.valueOrNull ?? const [],
                totalCount: groupNotifier.totalCount,
                isLoading: groups.isLoading,
                error: groups.error,
                availableHeight: 0,
                expandToFill: true,
                onNearEnd: groupNotifier.loadNextPage,
                onOpen: (group) => _openGroup(group, libraryNotifier),
                onPlay: (group) => _playGroup(group, playback),
              ),
            ),
          ],
        ),
      );
    }

    if (libraryNotifier.isRefreshing && tracks.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ...header,
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(
              'Scanning library…',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Searching for $kSupportedLibraryFormatsDescription files on the SMB share.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }
    if (library.isLoading && tracks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (library.hasError) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Card(
          color: Theme.of(context).colorScheme.errorContainer,
          child: ListTile(
            leading: const Icon(Icons.error_outline),
            title: Text(
              libraryNotifier.refreshWarning == 'Library not found.'
                  ? 'Library not found'
                  : 'Library scan failed',
            ),
            subtitle: Text(library.error.toString()),
            trailing: TextButton(
              onPressed: () => ref.read(libraryProvider.notifier).rescan(),
              child: const Text('Retry'),
            ),
          ),
        ),
      );
    }
    if (libraryNotifier.totalCount == 0 && tracks.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...header,
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.music_off),
                title: Text(
                  'No $kSupportedLibraryFormatsDescription files found',
                ),
                subtitle: Text(
                  libraryNotifier.activeSourcePath?.startsWith('smb://') == true
                      ? 'Check the SMB subfolder in Settings and run Scan library. '
                            'Only $kSupportedLibraryExtensionsDescription files are indexed.'
                      : 'Choose a directory containing your music files.',
                ),
                trailing:
                    libraryNotifier.activeSourcePath?.startsWith('smb://') ==
                        true
                    ? TextButton(
                        onPressed: libraryNotifier.isRefreshing
                            ? null
                            : libraryNotifier.rescan,
                        child: const Text('Rescan'),
                      )
                    : null,
              ),
            ),
          ],
        ),
      );
    }
    if (tracks.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: const Card(
          child: ListTile(
            leading: Icon(Icons.search_off),
            title: Text('No matching tracks'),
            subtitle: Text('Try a different search term.'),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...header,
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              tracks.length == libraryNotifier.totalCount
                  ? '${libraryNotifier.totalCount} songs'
                  : 'Showing ${tracks.length} of ${libraryNotifier.totalCount} songs',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: _CompactTrackList(
              tracks: tracks,
              currentPath: snapshot.currentTrack?.sourcePath,
              onPlay: playback.playTrack,
              onNearEnd: libraryNotifier.loadNextPage,
            ),
          ),
        ],
      ),
    );
  }
}
