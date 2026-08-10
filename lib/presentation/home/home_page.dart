import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/library_providers.dart';
import '../../app/playback_providers.dart';
import '../../app/smb_providers.dart';
import '../../domain/library/library_track.dart';
import '../../domain/playback/playback_service.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryProvider);
    final sourcePath = ref.read(libraryProvider.notifier).sourcePath;
    final playback = ref.watch(playbackServiceProvider);
    final snapshot = playback.snapshot;
    final smbSource = ref.watch(smbSourceProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Music Base')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Music library',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'The Windows foundation is ready for library and playback services.',
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Library source'),
              subtitle: Text(sourcePath ?? 'No local directory configured.'),
              trailing: FilledButton.icon(
                onPressed: library.isLoading
                    ? null
                    : () async {
                        final selectedPath = await getDirectoryPath();
                        if (selectedPath != null && context.mounted) {
                          await ref
                              .read(libraryProvider.notifier)
                              .scanDirectory(selectedPath);
                        }
                      },
                icon: const Icon(Icons.folder_open),
                label: const Text('Choose'),
              ),
            ),
          ),
          if (smbSource != null) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.cloud_outlined),
                title: const Text('SMB library'),
                subtitle: Text('${smbSource.host}/${smbSource.share}'),
                trailing: FilledButton.icon(
                  onPressed: library.isLoading
                      ? null
                      : () => ref.read(libraryProvider.notifier).scanSmb(),
                  icon: const Icon(Icons.sync),
                  label: const Text('Scan'),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (library.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (library.hasError)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: ListTile(
                leading: const Icon(Icons.error_outline),
                title: const Text('Library scan failed'),
                subtitle: Text(library.error.toString()),
              ),
            )
          else if (library.value!.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.music_off),
                title: Text('No FLAC or MP3 files found'),
                subtitle: Text(
                  'Choose a directory containing your music files.',
                ),
              ),
            )
          else
            ...library.value!.map(
              (track) => _TrackTile(
                track: track,
                isCurrent:
                    snapshot.currentTrack?.sourcePath == track.sourcePath,
                isPlaying: snapshot.isPlaying,
                onPlay: track.isRemote
                    ? null
                    : () async {
                        if (snapshot.currentTrack?.sourcePath ==
                                track.sourcePath &&
                            snapshot.isPlaying) {
                          await playback.pause();
                        } else if (snapshot.currentTrack?.sourcePath ==
                            track.sourcePath) {
                          await playback.resume();
                        } else {
                          await playback.playTrack(track);
                        }
                      },
              ),
            ),
          if (snapshot.currentTrack != null) ...[
            const SizedBox(height: 24),
            _PlaybackControls(playback: playback, snapshot: snapshot),
          ],
        ],
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  const _TrackTile({
    required this.track,
    required this.isCurrent,
    required this.isPlaying,
    required this.onPlay,
  });

  final LibraryTrack track;
  final bool isCurrent;
  final bool isPlaying;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(isCurrent ? Icons.graphic_eq : Icons.music_note),
      title: Text(track.title ?? track.sourcePath),
      subtitle: Text(track.sourcePath),
      trailing: IconButton(
        tooltip: track.isRemote
            ? 'SMB direct playback is not available yet'
            : isCurrent && isPlaying
            ? 'Pause'
            : 'Play',
        onPressed: onPlay,
        icon: Icon(
          track.isRemote
              ? Icons.cloud_off
              : isCurrent && isPlaying
              ? Icons.pause
              : Icons.play_arrow,
        ),
      ),
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls({required this.playback, required this.snapshot});

  final PlaybackService playback;
  final PlaybackSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final duration = snapshot.duration;
    final position = snapshot.position > duration
        ? duration
        : snapshot.position;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              snapshot.currentTrack?.title ?? 'Playing',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (snapshot.errorMessage case final message?)
              Text(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            Slider(
              value: duration.inMilliseconds == 0
                  ? 0
                  : position.inMilliseconds.toDouble(),
              max: duration.inMilliseconds == 0
                  ? 1
                  : duration.inMilliseconds.toDouble(),
              onChanged: duration.inMilliseconds == 0
                  ? null
                  : (value) =>
                        playback.seek(Duration(milliseconds: value.round())),
            ),
            Row(
              children: [
                Text(_formatDuration(position)),
                const Spacer(),
                IconButton(
                  tooltip: snapshot.isPlaying ? 'Pause' : 'Play',
                  onPressed: snapshot.isPlaying
                      ? playback.pause
                      : playback.resume,
                  icon: Icon(
                    snapshot.isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                ),
                IconButton(
                  tooltip: 'Stop',
                  onPressed: playback.stop,
                  icon: const Icon(Icons.stop),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '${duration.inHours > 0 ? '${duration.inHours}:' : ''}$minutes:$seconds';
}
