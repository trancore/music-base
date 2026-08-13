part of 'playlists_page.dart';

class _ResolvedPlaylistCard extends ConsumerWidget {
  const _ResolvedPlaylistCard({
    required super.key,
    required this.playlist,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
  });

  final Playlist playlist;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolved = ref.watch(resolvedPlaylistTracksProvider(playlist));
    return resolved.when(
      loading: () => _PlaylistCard(
        playlist: playlist,
        tracks: const [],
        canEdit: canEdit,
        isLoading: true,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
      error: (error, stackTrace) => _PlaylistCard(
        playlist: playlist,
        tracks: const [],
        canEdit: canEdit,
        errorMessage: '$error',
        onEdit: onEdit,
        onDelete: onDelete,
      ),
      data: (tracks) => _PlaylistCard(
        playlist: playlist,
        tracks: tracks,
        canEdit: canEdit,
        onPlay: tracks.isEmpty
            ? null
            : () => _playPlaylist(context, ref, tracks),
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }

  Future<void> _playPlaylist(
    BuildContext context,
    WidgetRef ref,
    List<LibraryTrack> tracks,
  ) async {
    try {
      final playback = ref.read(playbackServiceProvider);
      if (!playlist.isAutomatic) {
        await playback.playQueue(tracks);
        return;
      }
      final repository = ref.read(libraryRepositoryProvider);
      final descriptor = await repository.createPlaybackQueue(
        LibraryQuery(
          sourceKey: await repository.loadSourcePath(),
          search: playlist.query ?? '',
        ),
      );
      if (descriptor.length == 0) return;
      await playback.playLazyQueue(
        LibraryPlaybackQueue(repository, descriptor),
      );
    } on Object catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not play playlist: $error')),
      );
    }
  }
}

class _PlaylistCard extends StatefulWidget {
  const _PlaylistCard({
    required this.playlist,
    required this.tracks,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
    this.onPlay,
    this.isLoading = false,
    this.errorMessage,
  });

  final Playlist playlist;
  final List<LibraryTrack> tracks;
  final bool canEdit;
  final VoidCallback? onPlay;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isLoading;
  final String? errorMessage;

  @override
  State<_PlaylistCard> createState() => _PlaylistCardState();
}

class _PlaylistCardState extends State<_PlaylistCard> {
  bool _expanded = false;

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final missingCount = widget.playlist.isAutomatic
        ? 0
        : widget.playlist.trackPaths.length - widget.tracks.length;
    final subtitle = widget.isLoading
        ? 'Loading tracks…'
        : widget.errorMessage != null
        ? 'Could not load tracks'
        : widget.playlist.isAutomatic
        ? '${widget.tracks.length} tracks · “${widget.playlist.query}”'
        : missingCount > 0
        ? '${widget.tracks.length}/${widget.playlist.trackPaths.length} tracks · $missingCount unavailable'
        : '${widget.tracks.length} tracks';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.queue_music,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(
              widget.playlist.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(subtitle),
            onTap: _toggleExpanded,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Play playlist',
                  onPressed: widget.onPlay,
                  icon: const Icon(Icons.play_arrow),
                ),
                IconButton(
                  tooltip: 'Edit playlist',
                  onPressed: widget.canEdit ? widget.onEdit : null,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete playlist',
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
                IconButton(
                  tooltip: _expanded
                      ? 'Collapse playlist'
                      : 'Show playlist tracks',
                  onPressed: _toggleExpanded,
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            if (widget.errorMessage case final error?)
              Padding(padding: const EdgeInsets.all(18), child: Text(error))
            else if (widget.isLoading)
              const Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(),
              )
            else if (widget.tracks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(18),
                child: Text('No available tracks in this playlist.'),
              )
            else
              for (var index = 0; index < widget.tracks.length; index++)
                _PlaylistTrackTile(index: index, track: widget.tracks[index]),
          ],
        ],
      ),
    );
  }
}

class _PlaylistTrackTile extends StatelessWidget {
  const _PlaylistTrackTile({required this.index, required this.track});

  final int index;
  final LibraryTrack track;

  @override
  Widget build(BuildContext context) {
    final details = [
      track.artist,
      track.album,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' · ');
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: SizedBox(
        width: 28,
        child: Text(
          '${index + 1}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
      title: Text(
        track.title ?? track.sourcePath,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        details.isEmpty ? track.sourcePath : details,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
