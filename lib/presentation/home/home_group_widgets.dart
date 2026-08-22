part of 'home_page.dart';

class _LibraryGroupGrid extends StatelessWidget {
  const _LibraryGroupGrid({
    required this.groups,
    required this.totalCount,
    required this.isLoading,
    required this.error,
    required this.availableHeight,
    required this.expandToFill,
    required this.listMode,
    required this.onNearEnd,
    required this.onOpen,
    required this.onPlay,
  });

  final List<LibraryGroup> groups;
  final int totalCount;
  final bool isLoading;
  final Object? error;
  final double availableHeight;
  final bool expandToFill;
  final bool listMode;
  final VoidCallback onNearEnd;
  final ValueChanged<LibraryGroup> onOpen;
  final ValueChanged<LibraryGroup> onPlay;

  @override
  Widget build(BuildContext context) {
    if (isLoading && groups.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null && groups.isEmpty) {
      return Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: ListTile(
          leading: const Icon(Icons.error_outline),
          title: const Text('Could not load library groups'),
          subtitle: Text('$error'),
        ),
      );
    }
    if (groups.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.search_off),
          title: Text('No matching items'),
          subtitle: Text('Try a different search term.'),
        ),
      );
    }
    final groupsView = listMode
        ? ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              if (index >= groups.length - 20) onNearEnd();
              final group = groups[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
                  leading: SizedBox(
                    width: 56,
                    height: 56,
                    child: _GroupArtwork(trackId: group.artworkTrackId),
                  ),
                  title: Text(
                    group.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('${group.trackCount} songs'),
                  trailing: IconButton(
                    tooltip: 'Play',
                    onPressed: () => onPlay(group),
                    icon: const Icon(Icons.play_arrow),
                  ),
                  onTap: () => onOpen(group),
                ),
              );
            },
          )
        : GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 240,
              mainAxisExtent: 250,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              if (index >= groups.length - 20) onNearEnd();
              final group = groups[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onOpen(group),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _GroupArtwork(trackId: group.artworkTrackId),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    group.displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${group.trackCount} songs',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Play',
                              onPressed: () => onPlay(group),
                              icon: const Icon(Icons.play_arrow),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '$totalCount ${groups.first.kind == LibraryGroupKind.album ? 'albums' : 'artists'}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (expandToFill)
          Expanded(child: groupsView)
        else
          SizedBox(height: availableHeight, child: groupsView),
      ],
    );
  }
}

class _GroupArtwork extends ConsumerWidget {
  const _GroupArtwork({required this.trackId});

  final int? trackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bytes = trackId == null
        ? const AsyncData<List<int>?>(null)
        : ref.watch(libraryArtworkProvider(trackId!));
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: bytes.when(
        skipLoadingOnReload: true,
        loading: () =>
            const Center(child: Icon(Icons.album_outlined, size: 52)),
        error: (_, _) =>
            const Center(child: Icon(Icons.album_outlined, size: 52)),
        data: (artwork) => artwork == null || artwork.isEmpty
            ? const Center(child: Icon(Icons.album_outlined, size: 52))
            : RepaintBoundary(
                child: Image.memory(
                  Uint8List.fromList(artwork),
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  cacheWidth: 480,
                  cacheHeight: 360,
                  errorBuilder: (_, _, _) => const Icon(Icons.album_outlined),
                ),
              ),
      ),
    );
  }
}

class _CompactTrackList extends StatelessWidget {
  const _CompactTrackList({
    required this.tracks,
    required this.currentPath,
    required this.onPlay,
    required this.onNearEnd,
  });

  final List<LibraryTrack> tracks;
  final String? currentPath;
  final ValueChanged<LibraryTrack> onPlay;
  final VoidCallback onNearEnd;

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: EdgeInsets.zero,
    itemCount: tracks.length,
    itemBuilder: (context, index) {
      if (index >= tracks.length - 40) onNearEnd();
      final track = tracks[index];
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          leading: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: currentPath == track.sourcePath
                    ? [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.tertiary,
                      ]
                    : [
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                        Theme.of(context).colorScheme.surfaceContainer,
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: track.cacheId != null || track.artwork != null
                ? _CachedArtwork(track: track, size: 52, radius: 14)
                : Icon(
                    currentPath == track.sourcePath
                        ? Icons.equalizer
                        : Icons.music_note,
                    color: currentPath == track.sourcePath
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
          ),
          title: Text(
            track.title ?? track.sourcePath,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            [
              if (_trackNumberLabel(track) case final number?) '#$number',
              if (track.artist case final artist? when artist.trim().isNotEmpty)
                artist,
              if (track.album case final album? when album.trim().isNotEmpty)
                album,
            ].join('  •  '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton.filledTonal(
            tooltip: 'Play',
            onPressed: () => onPlay(track),
            icon: const Icon(Icons.play_arrow),
          ),
          onTap: () => onPlay(track),
        ),
      );
    },
  );
}
