import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/musicbrainz_providers.dart';
import '../../domain/cd/cd_import_plan.dart';
import '../../domain/metadata/musicbrainz_release.dart';

class MusicBrainzSearchPage extends ConsumerStatefulWidget {
  const MusicBrainzSearchPage({super.key});

  @override
  ConsumerState<MusicBrainzSearchPage> createState() =>
      _MusicBrainzSearchPageState();
}

class _MusicBrainzSearchPageState extends ConsumerState<MusicBrainzSearchPage> {
  final _artistController = TextEditingController();
  final _albumController = TextEditingController();
  bool _loading = false;
  String? _error;
  List<MusicBrainzRelease> _results = const [];

  @override
  void dispose() {
    _artistController.dispose();
    _albumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MusicBrainz')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Find album metadata',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Search MusicBrainz for album candidates before importing a CD.',
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _artistController,
            decoration: const InputDecoration(labelText: 'Artist (optional)'),
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _albumController,
            decoration: const InputDecoration(labelText: 'Album'),
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: _loading ? null : _search,
              icon: _loading
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: const Text('Search'),
            ),
          ),
          if (_error case final message?) ...[
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: ListTile(
                leading: const Icon(Icons.error_outline),
                title: const Text('MusicBrainz search failed'),
                subtitle: Text(message),
              ),
            ),
          ],
          if (!_loading && _error == null && _results.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              '${_results.length} release candidates',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ..._results.map(
              (release) => _ReleaseCandidateTile(
                release,
                onTap: () => _showReleaseDetails(release),
              ),
            ),
          ] else if (!_loading && _error == null && _searched) ...[
            const SizedBox(height: 24),
            const Text('No matching releases found.'),
          ],
        ],
      ),
    );
  }

  bool _searched = false;

  Future<void> _search() async {
    final artist = _artistController.text.trim();
    final album = _albumController.text.trim();
    if (artist.isEmpty && album.isEmpty) {
      setState(() {
        _error = 'Enter an artist or album name.';
        _searched = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _searched = false;
    });
    try {
      final results = await ref
          .read(musicBrainzServiceProvider)
          .searchReleases(artist: artist, album: album);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _results = results;
        _searched = true;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
        _searched = true;
      });
    }
  }

  Future<void> _showReleaseDetails(MusicBrainzRelease release) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _ReleaseDetailsDialog(
        release: release,
        loadRelease: () =>
            ref.read(musicBrainzServiceProvider).getRelease(release.id),
      ),
    );
  }
}

class _ReleaseCandidateTile extends StatelessWidget {
  const _ReleaseCandidateTile(this.release, {required this.onTap});

  final MusicBrainzRelease release;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final details = [
      ?release.artist,
      ?release.releaseDate,
      ?release.country,
      if (release.trackCount case final count?) '$count tracks',
    ].join(' · ');
    return Card(
      child: ListTile(
        leading: const Icon(Icons.album_outlined),
        title: Text(release.title),
        subtitle: Text(details.isEmpty ? release.id : details),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _ReleaseDetailsDialog extends StatelessWidget {
  const _ReleaseDetailsDialog({
    required this.release,
    required this.loadRelease,
  });

  final MusicBrainzRelease release;
  final Future<MusicBrainzRelease> Function() loadRelease;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(release.title),
      content: SizedBox(
        width: 560,
        child: FutureBuilder<MusicBrainzRelease>(
          future: loadRelease(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Unable to load track list: ${snapshot.error}');
            }
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final detailedRelease = snapshot.data!;
            return ListView(
              shrinkWrap: true,
              children: [
                for (final medium in detailedRelease.media) ...[
                  ListTile(
                    dense: true,
                    title: Text(
                      'Disc ${medium.position}${medium.format == null ? '' : ' · ${medium.format}'}',
                    ),
                  ),
                  for (final track in medium.tracks)
                    ListTile(
                      dense: true,
                      leading: SizedBox(
                        width: 32,
                        child: Text('${track.number ?? track.position}'),
                      ),
                      title: Text(track.title),
                      subtitle: track.lengthMilliseconds == null
                          ? null
                          : Text(_formatLength(track.lengthMilliseconds!)),
                    ),
                ],
              ],
            );
          },
        ),
      ),
      actions: [
        if (release.media.expand((medium) => medium.tracks).isNotEmpty)
          FilledButton.icon(
            onPressed: () => _showImportPlan(context, release),
            icon: const Icon(Icons.album),
            label: const Text('Prepare CD import'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

Future<void> _showImportPlan(
  BuildContext context,
  MusicBrainzRelease release,
) async {
  await showDialog<void>(
    context: context,
    builder: (context) => _CdImportPlanDialog(release: release),
  );
}

class _CdImportPlanDialog extends StatefulWidget {
  const _CdImportPlanDialog({required this.release});

  final MusicBrainzRelease release;

  @override
  State<_CdImportPlanDialog> createState() => _CdImportPlanDialogState();
}

class _CdImportPlanDialogState extends State<_CdImportPlanDialog> {
  final _outputController = TextEditingController();
  CdImportFormat _format = CdImportFormat.flac;
  CdImportPlan? _plan;
  String? _error;

  @override
  void dispose() {
    _outputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Prepare CD import'),
      content: SizedBox(
        width: 560,
        child: ListView(
          shrinkWrap: true,
          children: [
            const Text(
              'Preview an import plan using the selected release track list. '
              'The CD drive and encoder are not accessed yet.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _outputController,
              decoration: const InputDecoration(
                labelText: 'Output directory',
                hintText: r'D:\Music',
              ),
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
              onChanged: (value) {
                if (value != null) setState(() => _format = value);
              },
            ),
            if (_error case final message?) ...[
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (_plan case final plan?) ...[
              const SizedBox(height: 16),
              Text('${plan.tracks.length} tracks planned.'),
              for (final track in plan.tracks)
                ListTile(
                  dense: true,
                  title: Text(track.title),
                  subtitle: Text(track.targetPath),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: _createPlan,
          child: const Text('Create preview'),
        ),
      ],
    );
  }

  void _createPlan() {
    final metadataTracks = widget.release.media.expand(
      (medium) => medium.tracks,
    );
    try {
      final plan = const CdImportPlanner().create(
        release: widget.release,
        cdTracks: [
          for (var index = 0; index < metadataTracks.length; index++)
            CdTrack(number: index + 1),
        ],
        outputDirectory: _outputController.text,
        format: _format,
      );
      setState(() {
        _plan = plan;
        _error = null;
      });
    } on CdImportPlanningException catch (error) {
      setState(() {
        _plan = null;
        _error = error.message;
      });
    }
  }
}

String _formatLength(int milliseconds) {
  final duration = Duration(milliseconds: milliseconds);
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
