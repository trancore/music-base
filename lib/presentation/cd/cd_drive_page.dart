import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../app/cd_providers.dart';
import '../../app/musicbrainz_providers.dart';
import '../../domain/cd/cd_drive_service.dart';
import '../../domain/cd/cd_import_plan.dart';
import '../../domain/cd/cd_ripping_service.dart';
import '../../domain/metadata/musicbrainz_release.dart';

class CdDrivePage extends ConsumerStatefulWidget {
  const CdDrivePage({super.key});

  @override
  ConsumerState<CdDrivePage> createState() => _CdDrivePageState();
}

class _CdDrivePageState extends ConsumerState<CdDrivePage> {
  Timer? _pollTimer;
  bool _loading = false;
  bool _ripping = false;
  bool _cancelRequested = false;
  CdRippingCancellationToken? _cancellationToken;
  String? _error;
  String? _statusMessage;
  String? _outputDirectory;
  CdImportFormat _format = CdImportFormat.flac;
  CdDrive? _selectedDrive;
  final _artistController = TextEditingController();
  final _albumController = TextEditingController();
  bool _metadataLoading = false;
  bool _metadataSearched = false;
  String? _metadataError;
  List<MusicBrainzRelease> _releaseCandidates = const [];
  MusicBrainzRelease? _release;
  int _completedTracks = 0;
  int _totalTracks = 0;
  List<CdDrive> _drives = const [];
  final Map<String, Future<List<CdTrack>>> _trackRequests = {};
  final Map<String, Set<int>> _selectedTracks = {};

  @override
  void initState() {
    super.initState();
    _refresh();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _refresh(silent: true),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cancellationToken?.cancel();
    _artistController.dispose();
    _albumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDrive = _selectedDrive;
    final selectedTrackNumbers = selectedDrive == null
        ? const <int>{}
        : (_selectedTracks[selectedDrive.deviceId] ?? const <int>{});

    return Scaffold(
      appBar: AppBar(
        title: const Text('CD import'),
        actions: [
          IconButton(
            tooltip: 'Refresh drives',
            onPressed: _loading || _ripping ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('CD drives', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text(
            'Select a drive and tracks, then choose an output directory to rip them.',
          ),
          const SizedBox(height: 24),
          if (_loading) const LinearProgressIndicator(),
          if (_error case final message?) ...[
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: ListTile(
                leading: const Icon(Icons.error_outline),
                title: const Text('CD import failed'),
                subtitle: Text(message),
              ),
            ),
          ] else if (_statusMessage case final message?) ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(message),
              ),
            ),
          ] else if (!_loading && _drives.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.album_outlined),
                title: Text('No CD drives detected'),
                subtitle: Text('Connect a CD drive and refresh this page.'),
              ),
            )
          else
            ..._drives.map(_buildDriveCard),
          if (selectedDrive != null && selectedTrackNumbers.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildImportControls(selectedDrive, selectedTrackNumbers),
          ],
        ],
      ),
    );
  }

  Widget _buildDriveCard(CdDrive drive) {
    final tracksFuture = drive.mediaLoaded
        ? (_trackRequests[drive.deviceId] ??= ref
              .read(cdTrackServiceProvider)
              .readTracks(drive))
        : null;
    final selected = _selectedDrive?.deviceId == drive.deviceId;
    return _CdDriveCard(
      drive,
      selected: selected,
      tracksFuture: tracksFuture,
      selectedTracks: _selectedTracks[drive.deviceId] ?? const <int>{},
      onSelectDrive: () => _selectDrive(drive),
      onToggleTrack: (track, checked) => _toggleTrack(drive, track, checked),
    );
  }

  Widget _buildImportControls(CdDrive drive, Set<int> selectedTracks) {
    final progress = _totalTracks == 0 ? 0.0 : _completedTracks / _totalTracks;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rip from ${drive.driveLetter}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _outputDirectory ?? 'No output directory selected',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _ripping ? null : _chooseOutputDirectory,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Choose output'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'MusicBrainz metadata',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _artistController,
                    decoration: const InputDecoration(labelText: 'Artist'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _albumController,
                    decoration: const InputDecoration(labelText: 'Album'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Search MusicBrainz',
                  onPressed: _metadataLoading ? null : _searchMetadata,
                  icon: _metadataLoading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                ),
              ],
            ),
            if (_metadataError case final message?)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (_releaseCandidates.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final candidate in _releaseCandidates)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.album_outlined),
                  title: Text(candidate.title),
                  subtitle: Text(
                    [
                      ?candidate.artist,
                      ?candidate.releaseDate,
                      if (candidate.trackCount case final count?)
                        '$count tracks',
                    ].join(' · '),
                  ),
                  trailing: TextButton(
                    onPressed: _metadataLoading
                        ? null
                        : () => _selectRelease(candidate),
                    child: const Text('Use'),
                  ),
                ),
            ] else if (_metadataSearched)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('No matching releases found.'),
              ),
            if (_release case final release?)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Selected release: ${release.title}'),
              ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CdImportFormat>(
              initialValue: _format,
              decoration: const InputDecoration(labelText: 'Format'),
              items: const [
                DropdownMenuItem(
                  value: CdImportFormat.flac,
                  child: Text('FLAC'),
                ),
                DropdownMenuItem(value: CdImportFormat.mp3, child: Text('MP3')),
              ],
              onChanged: _ripping
                  ? null
                  : (value) {
                      if (value != null) setState(() => _format = value);
                    },
            ),
            if (_ripping) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 8),
              Text('Ripping $_completedTracks of $_totalTracks tracks...'),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _requestCancellation,
                  child: const Text('Cancel'),
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _outputDirectory == null
                    ? null
                    : () => _ripSelectedTracks(drive, selectedTracks),
                icon: const Icon(Icons.album),
                label: Text('Start ripping (${selectedTracks.length})'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _selectDrive(CdDrive drive) {
    if (!drive.mediaLoaded) return;
    setState(() {
      _selectedDrive = drive;
      _selectedTracks.putIfAbsent(drive.deviceId, () => <int>{});
      _error = null;
      _statusMessage = null;
    });
  }

  void _toggleTrack(CdDrive drive, CdTrack track, bool checked) {
    setState(() {
      final tracks = _selectedTracks.putIfAbsent(drive.deviceId, () => <int>{});
      if (checked) {
        tracks.add(track.number);
      } else {
        tracks.remove(track.number);
      }
    });
  }

  Future<void> _chooseOutputDirectory() async {
    final path = await getDirectoryPath();
    if (!mounted || path == null || path.trim().isEmpty) return;
    setState(() {
      _outputDirectory = path;
      _error = null;
    });
  }

  Future<void> _searchMetadata() async {
    final artist = _artistController.text.trim();
    final album = _albumController.text.trim();
    if (artist.isEmpty && album.isEmpty) {
      setState(() => _metadataError = 'Enter an artist or album name.');
      return;
    }
    setState(() {
      _metadataLoading = true;
      _metadataSearched = false;
      _metadataError = null;
      _release = null;
    });
    try {
      final results = await ref
          .read(musicBrainzServiceProvider)
          .searchReleases(artist: artist, album: album);
      if (!mounted) return;
      setState(() {
        _metadataLoading = false;
        _metadataSearched = true;
        _releaseCandidates = results;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _metadataLoading = false;
        _metadataSearched = true;
        _metadataError = error.toString();
      });
    }
  }

  Future<void> _selectRelease(MusicBrainzRelease candidate) async {
    setState(() {
      _metadataLoading = true;
      _metadataError = null;
    });
    try {
      final release = await ref
          .read(musicBrainzServiceProvider)
          .getRelease(candidate.id);
      if (!mounted) return;
      setState(() {
        _metadataLoading = false;
        _release = release;
        _releaseCandidates = const [];
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _metadataLoading = false;
        _metadataError = error.toString();
      });
    }
  }

  Future<void> _ripSelectedTracks(
    CdDrive drive,
    Set<int> selectedTrackNumbers,
  ) async {
    final outputDirectory = _outputDirectory?.trim();
    if (outputDirectory == null || outputDirectory.isEmpty) return;
    final tracks = (_trackRequests[drive.deviceId] == null)
        ? const <CdTrack>[]
        : await _trackRequests[drive.deviceId]!;
    final selected = tracks
        .where((track) => selectedTrackNumbers.contains(track.number))
        .toList(growable: false);
    if (selected.isEmpty) return;

    late final List<_CdRipTarget> targets;
    try {
      targets = _buildRipTargets(selected);
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
      return;
    }
    final existingPaths = targets
        .where((target) => File(target.outputPath).existsSync())
        .map((target) => target.outputPath)
        .toList(growable: false);
    if (existingPaths.isNotEmpty) {
      if (!mounted) return;
      await _showExistingFiles(existingPaths);
      return;
    }

    setState(() {
      _ripping = true;
      _cancelRequested = false;
      _cancellationToken = CdRippingCancellationToken();
      _completedTracks = 0;
      _totalTracks = selected.length;
      _error = null;
      _statusMessage = null;
    });
    try {
      for (final target in targets) {
        if (_cancelRequested) break;
        await ref
            .read(cdRippingServiceProvider)
            .ripTrack(
              drive: drive,
              track: target.track,
              outputPath: target.outputPath,
              format: _format,
              title: target.title,
              artist: target.artist,
              album: target.album,
              releaseDate: target.releaseDate,
              cancellationToken: _cancellationToken,
            );
        if (!mounted) return;
        setState(() => _completedTracks++);
      }
      if (!mounted) return;
      setState(() {
        _ripping = false;
        _cancellationToken = null;
        _statusMessage = _cancelRequested
            ? 'Ripping cancelled after $_completedTracks tracks.'
            : 'Ripping completed: $_completedTracks tracks.';
      });
    } on Exception catch (error) {
      if (!mounted) return;
      final cancelled = _cancellationToken?.isCancelled ?? false;
      setState(() {
        _ripping = false;
        _cancellationToken = null;
        if (cancelled) {
          _statusMessage = 'Ripping cancelled after $_completedTracks tracks.';
        } else {
          _error = error.toString();
        }
      });
    }
  }

  void _requestCancellation() {
    _cancellationToken?.cancel();
    setState(() => _cancelRequested = true);
  }

  List<_CdRipTarget> _buildRipTargets(List<CdTrack> tracks) {
    final release = _release;
    if (release == null) {
      final outputDirectory = _outputDirectory!.trim();
      return [
        for (final track in tracks)
          _CdRipTarget(
            track: track,
            outputPath: p.join(
              outputDirectory,
              'Track ${track.number.toString().padLeft(2, '0')}${_format.extension}',
            ),
          ),
      ];
    }
    final plan = const CdImportPlanner().create(
      release: release,
      cdTracks: tracks,
      outputDirectory: _outputDirectory!.trim(),
      format: _format,
      cdTrackCount: tracks.length,
    );
    return [
      for (final planned in plan.tracks)
        _CdRipTarget(
          track: tracks.firstWhere(
            (track) => track.number == planned.sourceTrackNumber,
          ),
          outputPath: planned.targetPath,
          title: planned.title,
          artist: planned.artist,
          album: planned.album,
          releaseDate: planned.releaseDate,
        ),
    ];
  }

  Future<void> _showExistingFiles(List<String> paths) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Existing files found'),
        content: SizedBox(
          width: 560,
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text('Import stopped to avoid overwriting these files.'),
              const SizedBox(height: 12),
              for (final path in paths) Text(path),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _refresh({bool silent = false}) async {
    if (_loading || _ripping) return;
    setState(() {
      _loading = !silent;
      if (!silent) {
        _error = null;
        _statusMessage = null;
      }
    });
    try {
      final drives = await ref.read(cdDriveServiceProvider).listDrives();
      if (!mounted) return;
      final previousMedia = {
        for (final drive in _drives) drive.driveLetter: drive.mediaLoaded,
      };
      final inserted = drives.where(
        (drive) =>
            drive.mediaLoaded && previousMedia[drive.driveLetter] == false,
      );
      final removed = drives.where(
        (drive) =>
            !drive.mediaLoaded && previousMedia[drive.driveLetter] == true,
      );
      _trackRequests.removeWhere(
        (deviceId, _) => drives.every((drive) => drive.deviceId != deviceId),
      );
      for (final drive in drives.where((drive) => !drive.mediaLoaded)) {
        _trackRequests.remove(drive.deviceId);
        _selectedTracks.remove(drive.deviceId);
      }
      if (_selectedDrive != null &&
          drives.every((drive) => drive.deviceId != _selectedDrive!.deviceId)) {
        _selectedDrive = null;
      }
      setState(() {
        _loading = false;
        _drives = drives;
        if (inserted.isNotEmpty) {
          _statusMessage = 'CD inserted in ${inserted.first.driveLetter}.';
        } else if (removed.isNotEmpty) {
          _statusMessage = 'CD removed from ${removed.first.driveLetter}.';
        }
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }
}

class _CdRipTarget {
  const _CdRipTarget({
    required this.track,
    required this.outputPath,
    this.title,
    this.artist,
    this.album,
    this.releaseDate,
  });

  final CdTrack track;
  final String outputPath;
  final String? title;
  final String? artist;
  final String? album;
  final String? releaseDate;
}

class _CdDriveCard extends StatelessWidget {
  const _CdDriveCard(
    this.drive, {
    required this.selected,
    required this.tracksFuture,
    required this.selectedTracks,
    required this.onSelectDrive,
    required this.onToggleTrack,
  });

  final CdDrive drive;
  final bool selected;
  final Future<List<CdTrack>>? tracksFuture;
  final Set<int> selectedTracks;
  final VoidCallback onSelectDrive;
  final void Function(CdTrack track, bool checked) onToggleTrack;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: Icon(drive.mediaLoaded ? Icons.album : Icons.album_outlined),
        title: Text('${drive.driveLetter} ${drive.name}'),
        subtitle: Text(drive.mediaLoaded ? 'Media loaded' : 'No media loaded'),
        trailing: drive.mediaLoaded
            ? OutlinedButton(
                onPressed: onSelectDrive,
                child: Text(selected ? 'Selected' : 'Select'),
              )
            : null,
        children: [
          if (tracksFuture != null)
            FutureBuilder<List<CdTrack>>(
              future: tracksFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ListTile(
                    leading: const Icon(Icons.error_outline),
                    title: Text('Unable to read tracks: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.data!.isEmpty) {
                  return const ListTile(title: Text('No tracks found.'));
                }
                return Column(
                  children: [
                    for (final track in snapshot.data!)
                      CheckboxListTile(
                        value: selectedTracks.contains(track.number),
                        onChanged: (checked) {
                          if (checked != null) onToggleTrack(track, checked);
                        },
                        secondary: Text('${track.number}'),
                        title: Text(
                          track.duration == null
                              ? 'Track ${track.number}'
                              : 'Track ${track.number} · ${_formatTrackDuration(track.duration!)}',
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

String _formatTrackDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
