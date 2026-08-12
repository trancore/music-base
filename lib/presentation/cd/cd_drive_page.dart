import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/cd_providers.dart';
import '../../domain/cd/cd_drive_service.dart';
import '../../domain/cd/cd_import_plan.dart';

class CdDrivePage extends ConsumerStatefulWidget {
  const CdDrivePage({super.key});

  @override
  ConsumerState<CdDrivePage> createState() => _CdDrivePageState();
}

class _CdDrivePageState extends ConsumerState<CdDrivePage> {
  Timer? _pollTimer;
  bool _loading = false;
  String? _error;
  String? _statusMessage;
  List<CdDrive> _drives = const [];
  final Map<String, Future<List<CdTrack>>> _trackRequests = {};

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CD import'),
        actions: [
          IconButton(
            tooltip: 'Refresh drives',
            onPressed: _loading ? null : _refresh,
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
            'Insert a CD and refresh to check whether Windows detects it.',
          ),
          const SizedBox(height: 24),
          if (_loading) const LinearProgressIndicator(),
          if (_error case final message?) ...[
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: ListTile(
                leading: const Icon(Icons.error_outline),
                title: const Text('CD drive detection failed'),
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
            ..._drives.map((drive) {
              final tracksFuture = drive.mediaLoaded
                  ? (_trackRequests[drive.deviceId] ??= ref
                        .read(cdTrackServiceProvider)
                        .readTracks(drive))
                  : null;
              return _CdDriveCard(drive, tracksFuture: tracksFuture);
            }),
        ],
      ),
    );
  }

  Future<void> _refresh({bool silent = false}) async {
    if (_loading) return;
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

class _CdDriveCard extends StatelessWidget {
  const _CdDriveCard(this.drive, {required this.tracksFuture});

  final CdDrive drive;
  final Future<List<CdTrack>>? tracksFuture;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: Icon(drive.mediaLoaded ? Icons.album : Icons.album_outlined),
        title: Text('${drive.driveLetter} ${drive.name}'),
        subtitle: Text(drive.mediaLoaded ? 'Media loaded' : 'No media loaded'),
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
                      ListTile(
                        dense: true,
                        leading: Text('${track.number}'),
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
