import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/library_providers.dart';
import '../../app/playback_providers.dart';
import '../../data/playback/library_playback_queue.dart';
import '../../domain/library/library_query.dart';
import '../../domain/library/library_track.dart';
import '../../domain/playback/playback_service.dart';

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

    return Scaffold(
      appBar: isCompact
          ? AppBar(
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
              if (!compactHeight)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    constraints.maxWidth < 700 ? 8 : 28,
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
                  compactHeight ? 8 : 22,
                  horizontalPadding,
                  12,
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
              if (libraryNotifier.isRefreshing)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: LayoutBuilder(
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
                      if (!showTracks)
                        _LibraryGroupGrid(
                          groups: groups.valueOrNull ?? const [],
                          totalCount: groupNotifier.totalCount,
                          isLoading: groups.isLoading,
                          error: groups.error,
                          availableHeight: contentConstraints.maxHeight,
                          onNearEnd: groupNotifier.loadNextPage,
                          onOpen: (group) => _openGroup(group, libraryNotifier),
                          onPlay: (group) => _playGroup(group, playback),
                        )
                      else if (library.isLoading && tracks.isEmpty)
                        const Center(child: CircularProgressIndicator())
                      else if (library.hasError)
                        Card(
                          color: Theme.of(context).colorScheme.errorContainer,
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
                              onPressed: () =>
                                  ref.read(libraryProvider.notifier).rescan(),
                              child: const Text('Retry'),
                            ),
                          ),
                        )
                      else if (tracks.isEmpty)
                        const Card(
                          child: ListTile(
                            leading: Icon(Icons.music_off),
                            title: Text('No FLAC or MP3 files found'),
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
                            subtitle: Text('Try a different search term.'),
                          ),
                        )
                      else if (isCompact) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            '${libraryNotifier.totalCount} songs',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                        _CompactTrackList(
                          tracks: filteredTracks,
                          currentPath: snapshot.currentTrack?.sourcePath,
                          onPlay: playback.playTrack,
                          onNearEnd: libraryNotifier.loadNextPage,
                        ),
                      ] else
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
}

class _LibraryGroupGrid extends StatelessWidget {
  const _LibraryGroupGrid({
    required this.groups,
    required this.totalCount,
    required this.isLoading,
    required this.error,
    required this.availableHeight,
    required this.onNearEnd,
    required this.onOpen,
    required this.onPlay,
  });

  final List<LibraryGroup> groups;
  final int totalCount;
  final bool isLoading;
  final Object? error;
  final double availableHeight;
  final VoidCallback onNearEnd;
  final ValueChanged<LibraryGroup> onOpen;
  final ValueChanged<LibraryGroup> onPlay;

  @override
  Widget build(BuildContext context) {
    if (isLoading && groups.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null && groups.isEmpty) {
      return Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: ListTile(
          leading: const Icon(Icons.error_outline),
          title: const Text('Could not load library groups'),
          subtitle: Text('$error'),
        ),
      );
    }
    if (groups.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.search_off),
          title: Text('No matching items'),
          subtitle: Text('Try a different search term.'),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '$totalCount ${groups.first.kind == LibraryGroupKind.album ? 'albums' : 'artists'}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        SizedBox(
          height: availableHeight * 0.78,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 240,
              mainAxisExtent: 250,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              if (index >= groups.length - 20) onNearEnd();
              final group = groups[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onOpen(group),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _GroupArtwork(trackId: group.artworkTrackId),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    group.displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${group.trackCount} songs',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Play',
                              onPressed: () => onPlay(group),
                              icon: const Icon(Icons.play_arrow),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GroupArtwork extends ConsumerWidget {
  const _GroupArtwork({required this.trackId});

  final int? trackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bytes = trackId == null
        ? const AsyncData<List<int>?>(null)
        : ref.watch(libraryArtworkProvider(trackId!));
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: bytes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Icon(Icons.album_outlined, size: 52)),
        data: (artwork) => artwork == null || artwork.isEmpty
            ? const Center(child: Icon(Icons.album_outlined, size: 52))
            : Image.memory(
                Uint8List.fromList(artwork),
                fit: BoxFit.cover,
                cacheWidth: 480,
                cacheHeight: 360,
                errorBuilder: (_, _, _) => const Icon(Icons.album_outlined),
              ),
      ),
    );
  }
}

class _CompactTrackList extends StatelessWidget {
  const _CompactTrackList({
    required this.tracks,
    required this.currentPath,
    required this.onPlay,
    required this.onNearEnd,
  });

  final List<LibraryTrack> tracks;
  final String? currentPath;
  final ValueChanged<LibraryTrack> onPlay;
  final VoidCallback onNearEnd;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * 0.65,
    child: ListView.builder(
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        if (index >= tracks.length - 40) onNearEnd();
        final track = tracks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            leading: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: currentPath == track.sourcePath
                      ? [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.tertiary,
                        ]
                      : [
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                          Theme.of(context).colorScheme.surfaceContainer,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: track.cacheId != null || track.artwork != null
                  ? _CachedArtwork(track: track, size: 52, radius: 14)
                  : Icon(
                      currentPath == track.sourcePath
                          ? Icons.equalizer
                          : Icons.music_note,
                      color: currentPath == track.sourcePath
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
            ),
            title: Text(
              track.title ?? track.sourcePath,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              [
                if (_trackNumberLabel(track) case final number?) '#$number',
                if (track.artist case final artist?
                    when artist.trim().isNotEmpty)
                  artist,
                if (track.album case final album? when album.trim().isNotEmpty)
                  album,
              ].join('  •  '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton.filledTonal(
              tooltip: 'Play',
              onPressed: () => onPlay(track),
              icon: const Icon(Icons.play_arrow),
            ),
            onTap: () => onPlay(track),
          ),
        );
      },
    ),
  );
}

class _PageIntro extends StatelessWidget {
  const _PageIntro({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });
  final String eyebrow;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        eyebrow,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 1.6,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      const SizedBox(height: 7),
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 5),
      Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
    ],
  );
}

class _TrackTable extends StatelessWidget {
  const _TrackTable({
    required this.tracks,
    required this.currentPath,
    required this.availableWidth,
    required this.availableHeight,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSort,
    required this.onDoubleTap,
    required this.onNearEnd,
  });

  final List<LibraryTrack> tracks;
  final String? currentPath;
  final double availableWidth;
  final double availableHeight;
  final int sortColumn;
  final bool sortAscending;
  final ValueChanged<int> onSort;
  final ValueChanged<LibraryTrack> onDoubleTap;
  final VoidCallback onNearEnd;

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).dividerColor;
    const columnWidths = {
      0: FixedColumnWidth(104),
      1: FlexColumnWidth(2.4),
      2: FlexColumnWidth(1.5),
      3: FlexColumnWidth(1.5),
      4: FlexColumnWidth(2.2),
    };
    final tableWidth = availableWidth > 860 ? availableWidth : 860.0;
    final header = Table(
      columnWidths: columnWidths,
      border: TableBorder(bottom: BorderSide(color: borderColor)),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          children: [
            const _TableHeader(label: '#'),
            _TableHeader(
              label: 'Title',
              onTap: () => onSort(0),
              sorted: sortColumn == 0,
              ascending: sortAscending,
            ),
            _TableHeader(
              label: 'Artist',
              onTap: () => onSort(1),
              sorted: sortColumn == 1,
              ascending: sortAscending,
            ),
            _TableHeader(
              label: 'Album',
              onTap: () => onSort(2),
              sorted: sortColumn == 2,
              ascending: sortAscending,
            ),
            _TableHeader(
              label: 'Source',
              onTap: () => onSort(3),
              sorted: sortColumn == 3,
              ascending: sortAscending,
            ),
          ],
        ),
      ],
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: tableWidth,
          height: availableHeight,
          child: Column(
            children: [
              header,
              Expanded(
                child: ListView.builder(
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    if (index >= tracks.length - 40) onNearEnd();
                    return Table(
                      columnWidths: columnWidths,
                      border: TableBorder(
                        bottom: BorderSide(color: borderColor),
                      ),
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      children: [
                        _trackRow(
                          context,
                          tracks[index],
                          index,
                          currentPath == tracks[index].sourcePath,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _trackRow(
    BuildContext context,
    LibraryTrack track,
    int index,
    bool isCurrent,
  ) {
    final rowColor = isCurrent
        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
        : null;
    Widget cell(Widget child) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: () => onDoubleTap(track),
      child: SizedBox(
        height: 58,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Align(alignment: Alignment.centerLeft, child: child),
        ),
      ),
    );
    return TableRow(
      decoration: BoxDecoration(color: rowColor),
      children: [
        cell(
          Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  _trackNumberLabel(track) ?? '${index + 1}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              const SizedBox(width: 6),
              SizedBox.square(
                dimension: 34,
                child: track.cacheId == null && track.artwork == null
                    ? Icon(
                        isCurrent
                            ? Icons.graphic_eq
                            : Icons.music_note_outlined,
                      )
                    : _CachedArtwork(track: track, size: 34, radius: 6),
              ),
            ],
          ),
        ),
        cell(
          Text(
            track.title ?? track.sourcePath,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        cell(
          Text(
            track.artist ?? '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        cell(
          Text(
            track.album ?? '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        cell(
          Text(
            track.sourcePath,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

String? _trackNumberLabel(LibraryTrack track) {
  final trackNumber = track.trackNumber;
  if (trackNumber == null) return null;
  final discNumber = track.discNumber;
  return discNumber != null && discNumber > 1
      ? '$discNumber-$trackNumber'
      : '$trackNumber';
}

class _CachedArtwork extends ConsumerWidget {
  const _CachedArtwork({
    required this.track,
    required this.size,
    required this.radius,
  });

  final LibraryTrack track;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final legacy = track.artwork;
    final artwork = track.cacheId == null
        ? AsyncData<List<int>?>(legacy)
        : ref.watch(libraryArtworkProvider(track.cacheId!));
    return artwork.when(
      loading: () => const Center(
        child: SizedBox.square(
          dimension: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (error, stackTrace) => const Icon(Icons.music_note_outlined),
      data: (bytes) => bytes == null || bytes.isEmpty
          ? const Icon(Icons.music_note_outlined)
          : ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Image.memory(
                Uint8List.fromList(bytes),
                width: size,
                height: size,
                cacheWidth: (size * 2).round(),
                cacheHeight: (size * 2).round(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.music_note_outlined),
              ),
            ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({
    required this.label,
    this.onTap,
    this.sorted = false,
    this.ascending = true,
  });
  final String label;
  final VoidCallback? onTap;
  final bool sorted;
  final bool ascending;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 44,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (onTap != null)
                Icon(
                  sorted && !ascending
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                  size: 15,
                  color: sorted
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).hintColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
