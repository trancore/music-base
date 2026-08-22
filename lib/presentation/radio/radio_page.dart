import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../app/playback_providers.dart';
import '../../app/radio_providers.dart';
import '../../domain/radio/internet_radio_station.dart';
import '../../domain/radio/radio_browser_station.dart';
import '../../domain/radio/radio_station_sort.dart';
import '../../domain/playback/playback_service.dart';
import '../../app/providers.dart';
import '../../data/radio/radio_station_transfer.dart';

part 'radio_station_widgets.dart';
part 'radio_dialogs.dart';

typedef RadioStationFileOpener = Future<XFile?> Function();
typedef RadioStationSaveLocationPicker = Future<FileSaveLocation?> Function();

final radioStationFileOpenerProvider = Provider<RadioStationFileOpener>((ref) {
  return () => openFile(
    acceptedTypeGroups: const [
      XTypeGroup(label: 'Internet radio stations', extensions: ['json']),
    ],
  );
});

final radioStationSaveLocationPickerProvider =
    Provider<RadioStationSaveLocationPicker>((ref) {
      return () => getSaveLocation(
        suggestedName: 'internet-radio.json',
        acceptedTypeGroups: const [
          XTypeGroup(label: 'Internet radio stations', extensions: ['json']),
        ],
      );
    });

class RadioPage extends ConsumerWidget {
  const RadioPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stations = ref.watch(radioStationProvider);
    final playback = ref.watch(playbackServiceProvider);
    final sort =
        ref.watch(appSettingsProvider).valueOrNull?.radioStationSort ??
        RadioStationSort.manual;
    final isCompact = MediaQuery.sizeOf(context).width < 700;
    final hasActivePlayback =
        playback.snapshot.currentTrack != null ||
        playback.snapshot.currentRadioStation != null;
    return Scaffold(
      appBar: AppBar(
        primary: !(isCompact && hasActivePlayback),
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
          IconButton(
            tooltip: 'Import stations',
            onPressed: () => _importStations(context, ref),
            icon: const Icon(Icons.file_open_outlined),
          ),
          IconButton(
            tooltip: 'Export stations',
            onPressed: () => _exportStations(context, ref),
            icon: const Icon(Icons.save_alt_outlined),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Sort stations',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<RadioStationSort>(
                              initialValue: sort,
                              isExpanded: true,
                              decoration: const InputDecoration(
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
                                      .read(appSettingsProvider.notifier)
                                      .setRadioStationSort(value);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _StationList(
                        stations: _sortedStations(items, sort),
                        manualOrder: sort == RadioStationSort.manual,
                        groupByGenre: sort == RadioStationSort.genre,
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

  Future<void> _importStations(BuildContext context, WidgetRef ref) async {
    final file = await ref.read(radioStationFileOpenerProvider)();
    if (file == null || !context.mounted) return;
    try {
      final stations = RadioStationTransfer.decode(await file.readAsString());
      final imported = await ref
          .read(radioStationProvider.notifier)
          .importStations(stations);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Imported $imported station(s).')));
    } on Object catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not import stations: $error')),
      );
    }
  }

  Future<void> _exportStations(BuildContext context, WidgetRef ref) async {
    final stations = ref.read(radioStationProvider).valueOrNull ?? const [];
    if (stations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('There are no stations to export.')),
      );
      return;
    }
    final location = await ref.read(radioStationSaveLocationPickerProvider)();
    if (location == null || !context.mounted) return;
    try {
      final file = XFile.fromData(
        utf8.encode(RadioStationTransfer.encode(stations)),
        name: p.basename(location.path),
        mimeType: 'application/json',
      );
      await file.saveTo(location.path);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Stations exported.')));
    } on Object catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not export stations: $error')),
      );
    }
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
      await ref.read(radioStationProvider.notifier).save(result);
    } on Object {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save this station.')),
      );
      return;
    }
    try {
      await ref.read(playbackServiceProvider).playRadioStation(result);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Added ${result.name}.')));
    } on Object {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added ${result.name}, but playback could not start. Try again later.',
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

Future<void> _playRadioStation(
  BuildContext context,
  PlaybackService playback,
  InternetRadioStation station,
) async {
  try {
    await playback.playRadioStation(station);
  } on Object {
    if (!context.mounted) return;
    final detail = playback.snapshot.errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          detail == null || detail.isEmpty
              ? 'Could not play ${station.name}. Try again later.'
              : detail,
        ),
      ),
    );
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
      sorted.sort((a, b) {
        final genreComparison = _primaryGenre(
          a,
        ).toLowerCase().compareTo(_primaryGenre(b).toLowerCase());
        if (genreComparison != 0) return genreComparison;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
  }
  return sorted;
}

String _primaryGenre(InternetRadioStation station) {
  final tags = _radioTags(station.genre);
  return tags.isEmpty ? 'Other' : tags.first;
}

List<({String genre, List<InternetRadioStation> stations})> _genreGroups(
  List<InternetRadioStation> stations,
) {
  final grouped =
      <String, ({String genre, List<InternetRadioStation> stations})>{};
  for (final station in stations) {
    final genre = _primaryGenre(station);
    final key = genre.toLowerCase();
    final group = grouped.putIfAbsent(
      key,
      () => (genre: genre, stations: <InternetRadioStation>[]),
    );
    group.stations.add(station);
  }
  final groups = grouped.values.toList(growable: false);
  groups.sort((a, b) {
    if (a.genre == 'Other') return 1;
    if (b.genre == 'Other') return -1;
    return a.genre.toLowerCase().compareTo(b.genre.toLowerCase());
  });
  return groups;
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
