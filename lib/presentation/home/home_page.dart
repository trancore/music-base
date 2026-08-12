import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/library_providers.dart';
import '../../app/playback_providers.dart';
import '../../app/smb_providers.dart';
import '../../domain/library/library_track.dart';
import '../../domain/playback/playback_service.dart';
import '../playback/playback_visualizer.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryProvider);
    final tracks = library.valueOrNull ?? const <LibraryTrack>[];
    final visibleTracks = ref.watch(visibleLibraryTracksProvider);
    final searchQuery = ref.watch(librarySearchQueryProvider);
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
          if (visibleTracks.isNotEmpty) ...[
            FilledButton.icon(
              onPressed: () => playback.playQueue(visibleTracks),
              icon: const Icon(Icons.playlist_play),
              label: const Text('Play library'),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            decoration: InputDecoration(
              labelText: 'Search library',
              hintText: 'Title, artist, album, or file path',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: searchQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () =>
                          ref.read(librarySearchQueryProvider.notifier).state =
                              '',
                      icon: const Icon(Icons.clear),
                    ),
            ),
            onChanged: (query) {
              ref.read(librarySearchQueryProvider.notifier).state = query;
            },
          ),
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
          else if (tracks.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.music_off),
                title: Text('No FLAC or MP3 files found'),
                subtitle: Text(
                  'Choose a directory containing your music files.',
                ),
              ),
            )
          else if (visibleTracks.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.search_off),
                title: Text('No matching tracks found'),
                subtitle: Text(
                  'Choose a directory or adjust the search query.',
                ),
              ),
            )
          else
            ...visibleTracks.map(
              (track) => _TrackTile(
                track: track,
                isCurrent:
                    snapshot.currentTrack?.sourcePath == track.sourcePath,
                isPlaying: snapshot.isPlaying,
                onPlay: () async {
                  if (snapshot.currentTrack?.sourcePath == track.sourcePath &&
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
          if (snapshot.queue.isNotEmpty) ...[
            const SizedBox(height: 16),
            _QueuePanel(playback: playback, snapshot: snapshot),
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
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final metadata = [
      track.artist,
      track.album,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' · ');

    return ListTile(
      leading: track.artwork == null
          ? Icon(isCurrent ? Icons.graphic_eq : Icons.music_note)
          : Image.memory(
              track.artwork!,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(isCurrent ? Icons.graphic_eq : Icons.music_note),
            ),
      title: Text(track.title ?? track.sourcePath),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (metadata.isNotEmpty) Text(metadata),
          Text(track.sourcePath, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
      trailing: IconButton(
        tooltip: isCurrent && isPlaying ? 'Pause' : 'Play',
        onPressed: onPlay,
        icon: Icon(isCurrent && isPlaying ? Icons.pause : Icons.play_arrow),
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
            const SizedBox(height: 8),
            const Text('Playback visualizer'),
            const SizedBox(height: 4),
            PlaybackVisualizer(snapshot: snapshot),
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
                IconButton(
                  tooltip: 'Previous',
                  onPressed: playback.skipPrevious,
                  icon: const Icon(Icons.skip_previous),
                ),
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
                IconButton(
                  tooltip: 'Next',
                  onPressed: playback.skipNext,
                  icon: const Icon(Icons.skip_next),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  tooltip: 'Shuffle',
                  onPressed: playback.toggleShuffle,
                  color: snapshot.shuffleEnabled
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  icon: const Icon(Icons.shuffle),
                ),
                IconButton(
                  tooltip: 'Repeat',
                  onPressed: playback.toggleRepeat,
                  color: snapshot.repeatEnabled
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  icon: const Icon(Icons.repeat),
                ),
                IconButton(
                  tooltip: snapshot.isMuted ? 'Unmute' : 'Mute',
                  onPressed: playback.toggleMute,
                  icon: Icon(
                    snapshot.isMuted ? Icons.volume_off : Icons.volume_up,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: snapshot.volume,
                    onChanged: snapshot.isMuted ? null : playback.setVolume,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QueuePanel extends StatelessWidget {
  const _QueuePanel({required this.playback, required this.snapshot});

  final PlaybackService playback;
  final PlaybackSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.queue_music),
        title: const Text('Playback queue'),
        subtitle: Text('${snapshot.queue.length} tracks'),
        children: [
          for (var index = 0; index < snapshot.queue.length; index++)
            ListTile(
              selected: index == snapshot.currentIndex,
              leading: Icon(
                index == snapshot.currentIndex
                    ? Icons.play_arrow
                    : Icons.music_note_outlined,
              ),
              title: Text(
                snapshot.queue[index].title ?? snapshot.queue[index].sourcePath,
              ),
              subtitle: Text(
                snapshot.queue[index].artist ??
                    snapshot.queue[index].sourcePath,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () =>
                  playback.playQueue(snapshot.queue, initialIndex: index),
            ),
        ],
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '${duration.inHours > 0 ? '${duration.inHours}:' : ''}$minutes:$seconds';
}
