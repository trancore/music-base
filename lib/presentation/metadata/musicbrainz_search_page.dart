import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/musicbrainz_providers.dart';
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
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

String _formatLength(int milliseconds) {
  final duration = Duration(milliseconds: milliseconds);
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
