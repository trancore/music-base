part of 'radio_page.dart';

class _GenreTags extends StatelessWidget {
  const _GenreTags({required this.tags, this.large = false});

  final List<String> tags;
  final bool large;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: large ? 6 : 2,
    children: [
      for (final tag in tags)
        Chip(
          label: Text(tag),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSecondaryContainer,
            fontWeight: FontWeight.w600,
          ),
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          side: BorderSide.none,
        ),
    ],
  );
}

class _StationList extends StatelessWidget {
  const _StationList({
    required this.stations,
    required this.manualOrder,
    required this.groupByGenre,
    required this.playback,
    required this.onReorder,
    required this.onEdit,
    required this.onDelete,
  });

  final List<InternetRadioStation> stations;
  final bool manualOrder;
  final bool groupByGenre;
  final PlaybackService playback;
  final void Function(int oldIndex, int newIndex) onReorder;
  final ValueChanged<InternetRadioStation> onEdit;
  final ValueChanged<InternetRadioStation> onDelete;

  @override
  Widget build(BuildContext context) {
    if (groupByGenre) {
      return ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          for (final group in _genreGroups(stations)) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      group.genre,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${group.stations.length}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            for (final station in group.stations)
              _stationCard(context, station),
          ],
        ],
      );
    }

    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: stations.length,
      onReorderItem: manualOrder ? onReorder : (_, _) {},
      itemBuilder: (context, index) =>
          _stationCard(context, stations[index], reorderIndex: index),
    );
  }

  Widget _stationCard(
    BuildContext context,
    InternetRadioStation station, {
    int? reorderIndex,
  }) {
    final isCurrent = playback.snapshot.currentRadioStation?.id == station.id;
    final isPlaying = isCurrent && playback.snapshot.isPlaying;
    return Card(
      key: ValueKey(station.id),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (manualOrder && reorderIndex != null)
              ReorderableDragStartListener(
                index: reorderIndex,
                child: const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.drag_handle),
                ),
              ),
            CircleAvatar(
              radius: 24,
              backgroundColor: isCurrent
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              foregroundColor: isCurrent
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              child: Icon(isCurrent ? Icons.graphic_eq : Icons.radio),
            ),
          ],
        ),
        title: Text(station.name, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          station.streamUrl,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: Wrap(
          spacing: 0,
          children: [
            IconButton(
              tooltip: isPlaying ? 'Playing' : 'Play',
              onPressed: isPlaying
                  ? null
                  : () => _playRadioStation(context, playback, station),
              icon: const Icon(Icons.play_arrow),
            ),
            IconButton(
              tooltip: 'Edit station',
              onPressed: () => onEdit(station),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Delete station',
              onPressed: () => onDelete(station),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (_) => _RadioStationDetailsSheet(
            station: station,
            isPlaying: isPlaying,
            onPlay: () {
              Navigator.of(context).pop();
              if (!isPlaying) {
                _playRadioStation(context, playback, station);
              }
            },
            onEdit: () {
              Navigator.of(context).pop();
              onEdit(station);
            },
            onDelete: () {
              Navigator.of(context).pop();
              onDelete(station);
            },
          ),
        ),
      ),
    );
  }
}

class _RadioStationDetailsSheet extends StatelessWidget {
  const _RadioStationDetailsSheet({
    required this.station,
    required this.isPlaying,
    required this.onPlay,
    required this.onEdit,
    required this.onDelete,
  });

  final InternetRadioStation station;
  final bool isPlaying;
  final VoidCallback onPlay;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = [
      if (station.description case final description?
          when description.trim().isNotEmpty)
        ('Details', description),
      ('Stream URL', station.streamUrl),
    ];
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                  child: const Icon(Icons.radio, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    station.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_radioTags(station.genre).isNotEmpty) ...[
              Text(
                'Tags',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _GenreTags(tags: _radioTags(station.genre), large: true),
              const SizedBox(height: 16),
            ],
            for (final detail in details) ...[
              Text(
                detail.$1,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                detail.$2,
                style: detail.$1 == 'Stream URL'
                    ? theme.textTheme.bodySmall
                    : theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isPlaying ? null : onPlay,
                    icon: Icon(isPlaying ? Icons.equalizer : Icons.play_arrow),
                    label: Text(isPlaying ? 'Playing' : 'Play station'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Edit station',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton.filledTonal(
                  tooltip: 'Delete station',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRadioState extends StatelessWidget {
  const _EmptyRadioState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.radio_outlined, size: 42),
            const SizedBox(height: 12),
            const Text(
              'No radio stations yet',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Add a station using its direct audio stream URL.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add station'),
            ),
          ],
        ),
      ),
    ),
  );
}
