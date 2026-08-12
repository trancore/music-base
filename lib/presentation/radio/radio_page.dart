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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
      } on Object catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Stream test failed: $error')));
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
    } on Object catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Stream test failed: $error')));
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
                child: Icon(isCurrent ? Icons.graphic_eq : Icons.radio),
              ),
            ],
          ),
          title: Text(station.name),
          subtitle: Text(
            [
              if (station.genre case final genre? when genre.trim().isNotEmpty)
                genre,
              station.streamUrl,
            ].join(' • '),
            maxLines: 2,
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
        ),
      );
    },
  );
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
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Search Radio Browser'),
    content: SizedBox(
      width: 620,
      height: 480,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _queryController,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    labelText: 'Station name',
                    hintText: 'SomaFM, BBC, jazz...',
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _busy ? null : _search,
                child: const Text('Search'),
              ),
            ],
          ),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _stations.isEmpty && !_busy
                ? Center(
                    child: Text(
                      'Search for a station to see available streams.',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    itemCount: _stations.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final station = _stations[index];
                      return ListTile(
                        title: Text(station.name),
                        subtitle: Text(
                          [
                            if (station.tags case final tags?
                                when tags.trim().isNotEmpty)
                              tags,
                            if (station.codec case final codec?
                                when codec.trim().isNotEmpty)
                              codec,
                            if (station.bitrate case final bitrate?)
                              '${bitrate}kbps',
                          ].join(' • '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.add_circle_outline),
                        onTap: () => Navigator.of(context).pop(station),
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
        child: const Text('Cancel'),
      ),
    ],
  );

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
