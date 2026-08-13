part of 'playlists_page.dart';

class _PlaylistTree extends StatelessWidget {
  const _PlaylistTree({
    required this.playlists,
    required this.folders,
    required this.onMovePlaylist,
    required this.onEditPlaylist,
    required this.onDeletePlaylist,
    required this.onCreateFolder,
    required this.onEditFolder,
    required this.onDeleteFolder,
  });

  final List<Playlist> playlists;
  final List<PlaylistFolder> folders;
  final Future<void> Function(String, String?, {int? targetIndex})
  onMovePlaylist;
  final ValueChanged<Playlist> onEditPlaylist;
  final ValueChanged<String> onDeletePlaylist;
  final ValueChanged<String?> onCreateFolder;
  final ValueChanged<PlaylistFolder> onEditFolder;
  final ValueChanged<PlaylistFolder> onDeleteFolder;

  @override
  Widget build(BuildContext context) =>
      ListView(children: _children(context, null, 0));

  List<Widget> _children(
    BuildContext context,
    String? parentFolderId,
    int depth,
  ) {
    final childFolders =
        folders
            .where((folder) => folder.parentFolderId == parentFolderId)
            .toList()
          ..sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
    final childPlaylists =
        playlists
            .where((playlist) => playlist.parentFolderId == parentFolderId)
            .toList()
          ..sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
    return [
      for (final folder in childFolders)
        Padding(
          padding: EdgeInsets.only(left: depth * 18.0, bottom: 8),
          child: DragTarget<Playlist>(
            onWillAcceptWithDetails: (_) => true,
            onAcceptWithDetails: (details) =>
                onMovePlaylist(details.data.id, folder.id),
            builder: (context, candidates, rejects) => Card(
              color: candidates.isEmpty
                  ? null
                  : Theme.of(context).colorScheme.primaryContainer,
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                initiallyExpanded: true,
                leading: const Icon(Icons.folder_outlined),
                title: Text(
                  folder.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Create subfolder',
                      onPressed: () => onCreateFolder(folder.id),
                      icon: const Icon(Icons.create_new_folder_outlined),
                    ),
                    IconButton(
                      tooltip: 'Edit folder',
                      onPressed: () => onEditFolder(folder),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Delete folder',
                      onPressed: () => onDeleteFolder(folder),
                      icon: const Icon(Icons.delete_outline),
                    ),
                    const Icon(Icons.expand_more),
                  ],
                ),
                children: _children(context, folder.id, depth + 1),
              ),
            ),
          ),
        ),
      for (var index = 0; index < childPlaylists.length; index++) ...[
        _PlaylistDropLine(
          depth: depth,
          onAccept: (playlist) =>
              onMovePlaylist(playlist.id, parentFolderId, targetIndex: index),
        ),
        Padding(
          padding: EdgeInsets.only(left: depth * 18.0),
          child: Draggable<Playlist>(
            data: childPlaylists[index],
            feedback: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 360,
                child: ListTile(
                  leading: const Icon(Icons.queue_music),
                  title: Text(childPlaylists[index].name),
                ),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.35,
              child: _playlistCard(childPlaylists[index]),
            ),
            child: _playlistCard(childPlaylists[index]),
          ),
        ),
      ],
      _PlaylistDropLine(
        depth: depth,
        showRootLabel:
            parentFolderId == null &&
            (childFolders.isNotEmpty || childPlaylists.isNotEmpty),
        onAccept: (playlist) => onMovePlaylist(
          playlist.id,
          parentFolderId,
          targetIndex: childPlaylists.length,
        ),
      ),
    ];
  }

  Widget _playlistCard(Playlist playlist) => _ResolvedPlaylistCard(
    key: ValueKey(playlist.id),
    playlist: playlist,
    canEdit: true,
    onEdit: () => onEditPlaylist(playlist),
    onDelete: () => onDeletePlaylist(playlist.id),
  );
}

class _PlaylistDropLine extends StatelessWidget {
  const _PlaylistDropLine({
    required this.depth,
    required this.onAccept,
    this.showRootLabel = false,
  });

  final int depth;
  final ValueChanged<Playlist> onAccept;
  final bool showRootLabel;

  @override
  Widget build(BuildContext context) => DragTarget<Playlist>(
    onWillAcceptWithDetails: (_) => true,
    onAcceptWithDetails: (details) => onAccept(details.data),
    builder: (context, candidates, rejects) => AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      margin: EdgeInsets.only(left: depth * 18.0),
      height: candidates.isEmpty ? 8 : 34,
      decoration: BoxDecoration(
        color: candidates.isEmpty
            ? Colors.transparent
            : Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: candidates.isEmpty || !showRootLabel
          ? null
          : const Text('Move to root'),
    ),
  );
}
