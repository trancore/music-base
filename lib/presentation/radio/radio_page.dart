import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/playback_providers.dart';
import '../../app/radio_providers.dart';
import '../../domain/radio/internet_radio_station.dart';
import '../../domain/radio/radio_browser_station.dart';
import '../../domain/playback/playback_service.dart';

part 'radio_station_widgets.dart';
part 'radio_dialogs.dart';

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
