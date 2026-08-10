import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/cd_providers.dart';
import '../../domain/cd/cd_drive_service.dart';

class CdDrivePage extends ConsumerStatefulWidget {
  const CdDrivePage({super.key});

  @override
  ConsumerState<CdDrivePage> createState() => _CdDrivePageState();
}

class _CdDrivePageState extends ConsumerState<CdDrivePage> {
  bool _loading = false;
  String? _error;
  List<CdDrive> _drives = const [];

  @override
  void initState() {
    super.initState();
    _refresh();
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
          ] else if (!_loading && _drives.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.album_outlined),
                title: Text('No CD drives detected'),
                subtitle: Text('Connect a CD drive and refresh this page.'),
              ),
            )
          else
            ..._drives.map(
              (drive) => Card(
                child: ListTile(
                  leading: Icon(
                    drive.mediaLoaded ? Icons.album : Icons.album_outlined,
                  ),
                  title: Text('${drive.driveLetter} ${drive.name}'),
                  subtitle: Text(
                    drive.mediaLoaded ? 'Media loaded' : 'No media loaded',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final drives = await ref.read(cdDriveServiceProvider).listDrives();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _drives = drives;
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
