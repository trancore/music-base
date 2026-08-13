import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/playback_providers.dart';
import '../../app/radio_providers.dart';
import '../../domain/radio/internet_radio_station.dart';
import '../../domain/radio/radio_browser_station.dart';
import '../../domain/playback/playback_service.dart';

class RadioPage extends ConsumerWidget {
  const RadioPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stations = ref.watch(radioStationProvider);
    final playback = ref.watch(playbackServiceProvider);
    final sort = ref.watch(radioStationSortProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Internet radio'),
        actions: [
          IconButton(
            tooltip: 'Search Radio Browser',
            onPressed: () => _searchRadioBrowser(context, ref),
            icon: const Icon(Icons.travel_explore),
          ),
          IconButton(
            tooltip: 'Add station',
            onPressed: () => _editStation(context, ref),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
        child: stations.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('$error')),
          data: (items) => items.isEmpty
              ? _EmptyRadioState(onAdd: () => _editStation(context, ref))
              : Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 220,
                        child: DropdownButtonFormField<RadioStationSort>(
                          initialValue: sort,
                          decoration: const InputDecoration(
                            labelText: 'Sort stations',
                            prefixIcon: Icon(Icons.sort),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: RadioStationSort.manual,
                              child: Text('Manual order'),
                            ),
                            DropdownMenuItem(
                              value: RadioStationSort.nameAscending,
                              child: Text('Name (A–Z)'),
                            ),
                            DropdownMenuItem(
                              value: RadioStationSort.nameDescending,
                              child: Text('Name (Z–A)'),
                            ),
                            DropdownMenuItem(
                              value: RadioStationSort.genre,
                              child: Text('Genre'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              ref
                                      .read(radioStationSortProvider.notifier)
                                      .state =
                                  value;
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _StationList(
                        stations: _sortedStations(items, sort),
                        manualOrder: sort == RadioStationSort.manual,
                        playback: playback,
                        onReorder: (oldIndex, newIndex) async {
                          if (sort != RadioStationSort.manual) return;
                          final reordered = [...items];
                          final station = reordered.removeAt(oldIndex);
                          reordered.insert(newIndex, station);
                          await ref
                              .read(radioStationProvider.notifier)
                              .reorder(reordered);
                        },
                        onEdit: (station) =>
                            _editStation(context, ref, station),
                        onDelete: (station) =>
                            _deleteStation(context, ref, station),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _editStation(
    BuildContext context,
    WidgetRef ref, [
    InternetRadioStation? station,
  ]) async {
    final result = await showDialog<InternetRadioStation>(
      context: context,
      builder: (_) => _StationDialog(station: station),
    );
    if (result != null && context.mounted) {
      final existing = ref.read(radioStationProvider).valueOrNull ?? const [];
      final duplicate = existing.any(
        (entry) => entry.id != result.id && entry.streamUrl == result.streamUrl,
      );
      if (duplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('That stream URL is already saved.')),
        );
        return;
      }
      try {
        await ref.read(radioStreamTesterProvider).test(result);
        await ref.read(radioStationProvider.notifier).save(result);
      } on Object {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Stream test failed. Check the stream URL and try again.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _searchRadioBrowser(BuildContext context, WidgetRef ref) async {
    final station = await showDialog<RadioBrowserStation>(
      context: context,
      builder: (_) => const _RadioBrowserSearchDialog(),
    );
    if (station == null || !context.mounted) return;
    final result = station.toInternetRadioStation();
    try {
      await ref.read(radioStreamTesterProvider).test(result);
      await ref.read(radioStationProvider.notifier).save(result);
      await ref.read(playbackServiceProvider).playRadioStation(result);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Added ${result.name}.')));
    } on Object {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Stream test failed. Check the stream URL and try again.',
          ),
        ),
      );
    }
  }

  Future<void> _deleteStation(
    BuildContext context,
    WidgetRef ref,
    InternetRadioStation station,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete station?'),
        content: Text('Remove “${station.name}” from your stations?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(radioStationProvider.notifier).delete(station.id);
    }
  }
}

List<InternetRadioStation> _sortedStations(
  List<InternetRadioStation> stations,
  RadioStationSort sort,
) {
  final sorted = [...stations];
  switch (sort) {
    case RadioStationSort.manual:
      return sorted;
    case RadioStationSort.nameAscending:
      sorted.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    case RadioStationSort.nameDescending:
      sorted.sort(
        (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
      );
    case RadioStationSort.genre:
      sorted.sort(
        (a, b) => (a.genre ?? '').toLowerCase().compareTo(
          (b.genre ?? '').toLowerCase(),
        ),
      );
  }
  return sorted;
}

List<String> _radioTags(String? value) {
  if (value == null || value.trim().isEmpty) return const [];
  return value
      .split(RegExp(r'[,;]'))
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toSet()
      .take(8)
      .toList(growable: false);
}

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
    required this.playback,
    required this.onReorder,
    required this.onEdit,
    required this.onDelete,
  });

  final List<InternetRadioStation> stations;
  final bool manualOrder;
  final PlaybackService playback;
  final void Function(int oldIndex, int newIndex) onReorder;
  final ValueChanged<InternetRadioStation> onEdit;
  final ValueChanged<InternetRadioStation> onDelete;

  @override
  Widget build(BuildContext context) => ReorderableListView.builder(
    buildDefaultDragHandles: false,
    padding: const EdgeInsets.only(bottom: 24),
    itemCount: stations.length,
    onReorderItem: manualOrder ? onReorder : (_, _) {},
    itemBuilder: (context, index) {
      final station = stations[index];
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
              if (manualOrder)
                ReorderableDragStartListener(
                  index: index,
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
          title: Text(
            station.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
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
                    : () => playback.playRadioStation(station),
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
                if (!isPlaying) playback.playRadioStation(station);
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
    },
  );
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

class _RadioBrowserSearchDialog extends ConsumerStatefulWidget {
  const _RadioBrowserSearchDialog();

  @override
  ConsumerState<_RadioBrowserSearchDialog> createState() =>
      _RadioBrowserSearchDialogState();
}

class _RadioBrowserSearchDialogState
    extends ConsumerState<_RadioBrowserSearchDialog> {
  final _queryController = TextEditingController();
  List<RadioBrowserStation> _stations = const [];
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      title: Row(
        children: [
          Icon(Icons.travel_explore, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Find a station',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 620,
        height: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search Radio Browser by station name, genre, or country.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Search stations',
                      hintText: 'BBC, jazz...',
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _busy ? null : _search,
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_busy) const LinearProgressIndicator(minHeight: 2),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            if (_stations.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '${_stations.length} stations found',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Expanded(
              child: _stations.isEmpty && !_busy
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.radio_outlined,
                            size: 40,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Search to discover internet radio stations.',
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 8),
                      itemCount: _stations.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final station = _stations[index];
                        final metadata = [
                          if (station.tags case final tags?
                              when tags.trim().isNotEmpty)
                            tags,
                          if (station.codec case final codec?
                              when codec.trim().isNotEmpty)
                            codec,
                          if (station.bitrate case final bitrate?)
                            '$bitrate kbps',
                        ].join('  •  ');
                        return Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.fromLTRB(
                              16,
                              8,
                              8,
                              8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.14),
                              foregroundColor: theme.colorScheme.primary,
                              child: const Icon(Icons.radio, size: 20),
                            ),
                            title: Text(
                              station.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: metadata.isEmpty
                                ? null
                                : Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      metadata,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                            trailing: IconButton.filledTonal(
                              tooltip: 'Add station',
                              onPressed: () =>
                                  Navigator.of(context).pop(station),
                              icon: const Icon(Icons.add),
                            ),
                            onTap: () => Navigator.of(context).pop(station),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      setState(() => _error = 'Enter a station name or search term.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _stations = const [];
    });
    try {
      final stations = await ref
          .read(radioBrowserServiceProvider)
          .search(query);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _stations = stations;
        if (stations.isEmpty) _error = 'No reachable stations found.';
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Radio Browser search failed: $error';
      });
    }
  }
}

class _StationDialog extends StatefulWidget {
  const _StationDialog({this.station});

  final InternetRadioStation? station;

  @override
  State<_StationDialog> createState() => _StationDialogState();
}

class _StationDialogState extends State<_StationDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _urlController;
  late final TextEditingController _genreController;
  late final TextEditingController _descriptionController;
  String? _urlError;

  @override
  void initState() {
    super.initState();
    final station = widget.station;
    _nameController = TextEditingController(text: station?.name);
    _urlController = TextEditingController(text: station?.streamUrl);
    _genreController = TextEditingController(text: station?.genre);
    _descriptionController = TextEditingController(text: station?.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _genreController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.station == null ? 'Add radio station' : 'Edit radio station',
    ),
    content: SizedBox(
      width: 520,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Station name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: 'Audio stream URL',
                hintText: 'https://u1.happyhardcore.com/',
                helperText:
                    'Use the direct audio URL, not the station web page.',
                errorText: _urlError,
              ),
              onChanged: (_) {
                if (_urlError != null) setState(() => _urlError = null);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _genreController,
              decoration: const InputDecoration(labelText: 'Genre (optional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Test and save')),
    ],
  );

  void _save() {
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();
    if (name.isEmpty) return;
    final error = validateRadioStationUrl(url);
    if (error != null) {
      setState(() => _urlError = error);
      return;
    }
    Navigator.of(context).pop(
      InternetRadioStation(
        id:
            widget.station?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        streamUrl: url,
        genre: _genreController.text.trim().isEmpty
            ? null
            : _genreController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      ),
    );
  }
}
