import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/library_providers.dart';
import '../../app/playback_providers.dart';
import '../../domain/library/library_search.dart';
import '../../domain/library/library_track.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int _sortColumn = 0;
  bool _sortAscending = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(libraryProvider);
    final playback = ref.watch(playbackServiceProvider);
    final snapshot = playback.snapshot;
    final tracks = library.valueOrNull ?? const <LibraryTrack>[];
    final filteredTracks = _sortedTracks(
      filterLibraryTracks(tracks, _searchQuery),
      _sortColumn,
      _sortAscending,
    );
    final isCompact = MediaQuery.sizeOf(context).width < 700;

    return Scaffold(
      appBar: isCompact ? AppBar(title: const Text('Music Base')) : null,
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
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
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
                                  },
                                  icon: const Icon(Icons.clear),
                                ),
                        ),
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                      ),
                    ),
                    if (filteredTracks.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: () => playback.playQueue(filteredTracks),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play all'),
                      ),
                    ],
                  ],
                ),
              ),
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
                      if (library.isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (library.hasError)
                        Card(
                          color: Theme.of(context).colorScheme.errorContainer,
                          child: ListTile(
                            leading: const Icon(Icons.error_outline),
                            title: const Text('Library scan failed'),
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
                          },
                          onDoubleTap: playback.playTrack,
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

List<LibraryTrack> _sortedTracks(
  List<LibraryTrack> tracks,
  int column,
  bool ascending,
) {
  final sorted = [...tracks];
  String value(LibraryTrack track) => switch (column) {
    0 => track.title ?? track.sourcePath,
    1 => track.artist ?? '',
    2 => track.album ?? '',
    _ => track.sourcePath,
  };
  sorted.sort((a, b) {
    final result = value(a).toLowerCase().compareTo(value(b).toLowerCase());
    return ascending ? result : -result;
  });
  return sorted;
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
  });

  final List<LibraryTrack> tracks;
  final String? currentPath;
  final double availableWidth;
  final double availableHeight;
  final int sortColumn;
  final bool sortAscending;
  final ValueChanged<int> onSort;
  final ValueChanged<LibraryTrack> onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).dividerColor;
    const columnWidths = {
      0: FixedColumnWidth(64),
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
    final rows = Table(
      columnWidths: columnWidths,
      border: TableBorder(horizontalInside: BorderSide(color: borderColor)),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        for (var index = 0; index < tracks.length; index++)
          _trackRow(
            context,
            tracks[index],
            index,
            currentPath == tracks[index].sourcePath,
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
              Expanded(child: SingleChildScrollView(child: rows)),
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
          SizedBox.square(
            dimension: 38,
            child: track.artwork == null
                ? Icon(isCurrent ? Icons.graphic_eq : Icons.music_note_outlined)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.memory(
                      track.artwork!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.music_note_outlined),
                    ),
                  ),
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
