import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/library_providers.dart';
import '../../app/playback_providers.dart';
import '../../app/playlist_providers.dart';
import '../../domain/library/library_track.dart';

class PlaylistsPage extends ConsumerWidget {
  const PlaylistsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistProvider);
    final tracks = ref.watch(libraryProvider).valueOrNull ?? const [];
    final playback = ref.watch(playbackServiceProvider);
    final notifier = ref.read(playlistProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
        actions: [
          IconButton(
            tooltip: 'Create playlist',
            onPressed: tracks.isEmpty
                ? null
                : () => _createPlaylist(context, notifier, tracks),
            icon: const Icon(Icons.playlist_add),
          ),
        ],
      ),
      body: playlists.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('$error')),
        data: (items) => items.isEmpty
            ? const Center(
                child: Text('No playlists yet. Scan a library first.'),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final playlist = items[index];
                  final playlistTracks = playlist.trackPaths
                      .expand(
                        (path) =>
                            tracks.where((track) => track.sourcePath == path),
                      )
                      .toList(growable: false);
                  return ListTile(
                    leading: const Icon(Icons.queue_music),
                    title: Text(playlist.name),
                    subtitle: Text('${playlistTracks.length} tracks'),
                    onTap: playlistTracks.isEmpty
                        ? null
                        : () => playback.playQueue(playlistTracks),
                    trailing: IconButton(
                      tooltip: 'Delete playlist',
                      onPressed: () => notifier.delete(playlist.id),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: tracks.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _createPlaylist(context, notifier, tracks),
              icon: const Icon(Icons.playlist_add),
              label: const Text('New playlist'),
            ),
    );
  }

  Future<void> _createPlaylist(
    BuildContext context,
    PlaylistNotifier notifier,
    List<LibraryTrack> tracks,
  ) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null) {
      await notifier.create(name, tracks);
    }
  }
}
