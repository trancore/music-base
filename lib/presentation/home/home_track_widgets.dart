part of 'home_page.dart';

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
