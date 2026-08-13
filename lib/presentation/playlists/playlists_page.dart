import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../app/library_providers.dart';
import '../../app/playback_providers.dart';
import '../../app/playlist_providers.dart';
import '../../app/playlist_import_resolver.dart';
import '../../data/playback/library_playback_queue.dart';
import '../../data/playlist/m3u_playlist_parser.dart';
import '../../data/playlist/musicbee_auto_playlist_parser.dart';
import '../../data/playlist/musicbee_playlist_parser.dart';
import '../../domain/library/library_query.dart';
import '../../domain/library/library_path_normalizer.dart';
import '../../domain/library/library_track.dart';
import '../../domain/playlist/playlist.dart';
import 'auto_playlist_preview.dart';

typedef PlaylistFilePicker = Future<List<XFile>> Function();

final playlistFilePickerProvider = Provider<PlaylistFilePicker>((ref) {
  return () => openFiles(
    acceptedTypeGroups: const [
      XTypeGroup(
        label: 'Playlist files',
        extensions: ['m3u', 'm3u8', 'mbp', 'xautopf'],
      ),
    ],
  );
});

class PlaylistsPage extends ConsumerWidget {
  const PlaylistsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistProvider);
    final folders = ref.watch(playlistFoldersProvider);
    final notifier = ref.read(playlistProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
        actions: [
          IconButton(
            tooltip: 'Create folder',
            onPressed: () => _createFolder(context, notifier),
            icon: const Icon(Icons.create_new_folder_outlined),
          ),
          IconButton(
            tooltip: 'Import playlist files',
            onPressed: () => _importPlaylist(context, ref, notifier),
            icon: const Icon(Icons.file_open_outlined),
          ),
          IconButton(
            tooltip: 'Create auto playlist',
            onPressed: () => _createAutomaticPlaylist(context, ref, notifier),
            icon: const Icon(Icons.auto_awesome),
          ),
          IconButton(
            tooltip: 'Create playlist',
            onPressed: () => _createPlaylist(context, ref, notifier),
            icon: const Icon(Icons.playlist_add),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: playlists.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text('$error')),
          data: (items) => folders.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(child: Text('$error')),
            data: (folderItems) => items.isEmpty && folderItems.isEmpty
                ? Center(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.queue_music_outlined, size: 42),
                            const SizedBox(height: 12),
                            const Text(
                              'No playlists yet',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Create a folder, playlist, or import a playlist file.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : _PlaylistTree(
                    playlists: items,
                    folders: folderItems,
                    onMovePlaylist: notifier.movePlaylist,
                    onEditPlaylist: (playlist) => playlist.isAutomatic
                        ? _editAutomaticPlaylist(
                            context,
                            ref,
                            notifier,
                            playlist,
                          )
                        : _editPlaylist(context, ref, notifier, playlist),
                    onDeletePlaylist: notifier.delete,
                    onCreateFolder: (parentId) =>
                        _createFolder(context, notifier, parentId: parentId),
                    onEditFolder: (folder) =>
                        _editFolder(context, notifier, folder, folderItems),
                    onDeleteFolder: (folder) =>
                        _deleteFolder(context, notifier, folder),
                  ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createPlaylist(context, ref, notifier),
        icon: const Icon(Icons.playlist_add),
        label: const Text('New playlist'),
      ),
    );
  }

  Future<void> _createFolder(
    BuildContext context,
    PlaylistNotifier notifier, {
    String? parentId,
  }) async {
    final name = await _showFolderNameDialog(context, title: 'New folder');
    if (name != null) {
      await notifier.createFolder(name, parentFolderId: parentId);
    }
  }

  Future<void> _editFolder(
    BuildContext context,
    PlaylistNotifier notifier,
    PlaylistFolder folder,
    List<PlaylistFolder> folders,
  ) async {
    final result = await showDialog<_FolderEditorResult>(
      context: context,
      builder: (context) =>
          _FolderEditorDialog(folder: folder, folders: folders),
    );
    if (result != null) {
      await notifier.updateFolder(
        folder.id,
        result.name,
        parentFolderId: result.parentFolderId,
        moveToRoot: result.parentFolderId == null,
      );
    }
  }

  Future<void> _deleteFolder(
    BuildContext context,
    PlaylistNotifier notifier,
    PlaylistFolder folder,
  ) async {
    final deleted = await notifier.deleteFolder(folder.id);
    if (!context.mounted || deleted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Move or delete the folder contents before deleting it.'),
      ),
    );
  }

  Future<String?> _showFolderNameDialog(
    BuildContext context, {
    required String title,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (context) => _FolderNameDialog(title: title),
    );
  }

  Future<void> _createPlaylist(
    BuildContext context,
    WidgetRef ref,
    PlaylistNotifier notifier,
  ) async {
    final tracks = await _loadAllLibraryTracks(ref);
    if (!context.mounted) return;
    final result = await showDialog<_PlaylistEditorResult>(
      context: context,
      builder: (context) => _PlaylistEditorDialog(
        tracks: tracks,
        title: 'New playlist',
        confirmLabel: 'Create',
      ),
    );
    if (result != null) {
      await notifier.create(result.name, result.tracks);
    }
  }

  Future<void> _createAutomaticPlaylist(
    BuildContext context,
    WidgetRef ref,
    PlaylistNotifier notifier,
  ) async {
    final tracks = await _loadAllLibraryTracks(ref);
    if (!context.mounted) return;
    final result = await showDialog<_AutomaticPlaylistEditorResult>(
      context: context,
      builder: (context) => _AutomaticPlaylistEditorDialog(
        title: 'New auto playlist',
        confirmLabel: 'Create',
        tracks: tracks,
      ),
    );
    if (result != null) {
      await notifier.createAutomatic(result.name, result.query);
    }
  }

  Future<void> _editAutomaticPlaylist(
    BuildContext context,
    WidgetRef ref,
    PlaylistNotifier notifier,
    Playlist playlist,
  ) async {
    final tracks = await _loadAllLibraryTracks(ref);
    if (!context.mounted) return;
    final result = await showDialog<_AutomaticPlaylistEditorResult>(
      context: context,
      builder: (context) => _AutomaticPlaylistEditorDialog(
        title: 'Edit auto playlist',
        confirmLabel: 'Save',
        playlist: playlist,
        tracks: tracks,
      ),
    );
    if (result != null) {
      await notifier.updateAutomatic(playlist.id, result.name, result.query);
    }
  }

  Future<void> _importPlaylist(
    BuildContext context,
    WidgetRef ref,
    PlaylistNotifier notifier,
  ) async {
    final files = await ref.read(playlistFilePickerProvider)();
    if (files.isEmpty) return;

    var importedPlaylists = 0;
    var importedTracks = 0;
    var availableTracks = 0;
    var skippedPlaylists = 0;
    final failures = <String>[];
    for (final file in files) {
      if (!context.mounted) return;
      try {
        final result = await _importPlaylistFile(context, ref, notifier, file);
        if (!context.mounted) return;
        if (result == null) {
          skippedPlaylists++;
        } else {
          importedPlaylists++;
          importedTracks += result.trackCount;
          availableTracks += result.availableCount;
        }
      } on Object catch (error) {
        failures.add('${p.basename(file.path)}: $error');
      }
    }

    if (!context.mounted) return;
    final details = <String>[
      '$importedPlaylists imported',
      if (skippedPlaylists > 0) '$skippedPlaylists skipped',
      if (failures.isNotEmpty) '${failures.length} failed',
    ].join(' · ');
    final shownFailures = failures.take(3).join(' | ');
    final remainingFailures = failures.length - 3;
    final failureDetails = failures.isEmpty
        ? ''
        : ' $shownFailures'
              '${remainingFailures > 0 ? ' | +$remainingFailures more' : ''}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$details ($importedTracks tracks, $availableTracks available).'
          '$failureDetails',
        ),
      ),
    );
  }

  Future<_PlaylistFileImportOutcome?> _importPlaylistFile(
    BuildContext context,
    WidgetRef ref,
    PlaylistNotifier notifier,
    XFile file,
  ) async {
    final bytes = await file.readAsBytes();
    final extension = p.extension(file.path).toLowerCase();
    if (extension == '.xautopf') {
      final imported = const MusicBeeAutoPlaylistParser().parseBytes(
        bytes,
        sourcePath: file.path,
      );
      final matches = (await _loadAllLibraryTracks(
        ref,
      )).where((track) => imported.rule.matches(artist: track.artist)).length;
      await notifier.createAutomatic(
        imported.name,
        imported.rule.value,
        autoRule: imported.rule,
      );
      return _PlaylistFileImportOutcome(
        trackCount: matches,
        availableCount: matches,
      );
    }
    final ({String name, List<String> trackPaths}) imported;
    if (extension == '.mbp') {
      final result = const MusicBeePlaylistParser().parseBytes(
        bytes,
        sourcePath: file.path,
      );
      imported = (name: result.name, trackPaths: result.trackPaths);
    } else {
      final result = const M3uPlaylistParser().parseBytes(
        bytes,
        sourcePath: file.path,
      );
      imported = (name: result.name, trackPaths: result.trackPaths);
    }
    if (imported.trackPaths.isEmpty) {
      throw const FormatException('The playlist contains no track paths.');
    }
    final preview = await ref
        .read(playlistImportResolverProvider)
        .resolve(name: imported.name, paths: imported.trackPaths);
    final folders = await ref.read(playlistRepositoryProvider).loadFolders();
    if (!context.mounted) return null;
    final confirmation = await showDialog<_PlaylistImportConfirmationResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _PlaylistImportConfirmationDialog(preview: preview, folders: folders),
    );
    if (!context.mounted || confirmation == null) return null;
    final selectedMapping = confirmation.mapping;
    await notifier.importPlaylist(
      imported.name,
      preview.resolvedPaths(selectedMapping),
      parentFolderId: confirmation.parentFolderId,
    );
    return _PlaylistFileImportOutcome(
      trackCount: imported.trackPaths.length,
      availableCount: preview.availableCount(selectedMapping),
    );
  }

  Future<void> _editPlaylist(
    BuildContext context,
    WidgetRef ref,
    PlaylistNotifier notifier,
    Playlist playlist,
  ) async {
    final tracks = await _loadAllLibraryTracks(ref);
    if (!context.mounted) return;
    final result = await showDialog<_PlaylistEditorResult>(
      context: context,
      builder: (context) => _PlaylistEditorDialog(
        tracks: tracks,
        playlist: playlist,
        title: 'Edit playlist',
        confirmLabel: 'Save',
      ),
    );
    if (result != null) {
      await notifier.updatePlaylist(playlist.id, result.name, result.tracks);
    }
  }

  Future<List<LibraryTrack>> _loadAllLibraryTracks(WidgetRef ref) async {
    final repository = ref.read(libraryRepositoryProvider);
    final sourceKey = await repository.loadSourcePath();
    final tracks = <LibraryTrack>[];
    LibraryCursor? cursor;
    do {
      final page = await repository.queryTracks(
        LibraryQuery(sourceKey: sourceKey, pageSize: 500, cursor: cursor),
      );
      tracks.addAll(page.items);
      cursor = page.nextCursor;
    } while (cursor != null);
    return List.unmodifiable(tracks);
  }
}

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

class _FolderEditorResult {
  const _FolderEditorResult({required this.name, this.parentFolderId});

  final String name;
  final String? parentFolderId;
}

class _FolderNameDialog extends StatefulWidget {
  const _FolderNameDialog({required this.title});

  final String title;

  @override
  State<_FolderNameDialog> createState() => _FolderNameDialogState();
}

class _FolderNameDialogState extends State<_FolderNameDialog> {
  final _controller = TextEditingController();

  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: _controller,
      autofocus: true,
      decoration: const InputDecoration(labelText: 'Folder name'),
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) => _submit(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _controller.text.trim().isEmpty ? null : _submit,
        child: const Text('Create'),
      ),
    ],
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _FolderEditorDialog extends StatefulWidget {
  const _FolderEditorDialog({required this.folder, required this.folders});

  final PlaylistFolder folder;
  final List<PlaylistFolder> folders;

  @override
  State<_FolderEditorDialog> createState() => _FolderEditorDialogState();
}

class _FolderEditorDialogState extends State<_FolderEditorDialog> {
  late final TextEditingController _controller;
  String? _parentFolderId;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.folder.name);
    _parentFolderId = widget.folder.parentFolderId;
  }

  @override
  Widget build(BuildContext context) {
    final excluded = _descendants(widget.folder.id);
    return AlertDialog(
      title: const Text('Edit folder'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Folder name'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: _parentFolderId,
              decoration: const InputDecoration(labelText: 'Parent folder'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Root')),
                for (final folder in widget.folders)
                  if (folder.id != widget.folder.id &&
                      !excluded.contains(folder.id))
                    DropdownMenuItem(
                      value: folder.id,
                      child: Text(folder.name),
                    ),
              ],
              onChanged: (value) => setState(() => _parentFolderId = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _controller.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(
                  _FolderEditorResult(
                    name: _controller.text.trim(),
                    parentFolderId: _parentFolderId,
                  ),
                ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  Set<String> _descendants(String id) {
    final result = <String>{};
    void collect(String parent) {
      for (final child in widget.folders.where(
        (folder) => folder.parentFolderId == parent,
      )) {
        if (result.add(child.id)) collect(child.id);
      }
    }

    collect(id);
    return result;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

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

class _PlaylistImportConfirmationDialog extends StatefulWidget {
  const _PlaylistImportConfirmationDialog({
    required this.preview,
    required this.folders,
  });

  final PlaylistImportPreview preview;
  final List<PlaylistFolder> folders;

  @override
  State<_PlaylistImportConfirmationDialog> createState() =>
      _PlaylistImportConfirmationDialogState();
}

class _PlaylistImportConfirmationResult {
  const _PlaylistImportConfirmationResult(this.mapping, this.parentFolderId);

  final PlaylistRootMappingCandidate? mapping;
  final String? parentFolderId;
}

class _PlaylistFileImportOutcome {
  const _PlaylistFileImportOutcome({
    required this.trackCount,
    required this.availableCount,
  });

  final int trackCount;
  final int availableCount;
}

class _PlaylistImportConfirmationDialogState
    extends State<_PlaylistImportConfirmationDialog> {
  PlaylistRootMappingCandidate? _mapping;
  String? _parentFolderId;

  @override
  void initState() {
    super.initState();
    _mapping = widget.preview.mappingCandidates.firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final available = widget.preview.availableCount(_mapping);
    final unavailable = widget.preview.originalPaths.length - available;
    return AlertDialog(
      title: const Text('Import playlist file'),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.preview.name),
            const SizedBox(height: 16),
            Text('${widget.preview.originalPaths.length} tracks found'),
            Text('${widget.preview.exactPaths.length} exact path matches'),
            if (widget.preview.mappingCandidates.isNotEmpty) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<PlaylistRootMappingCandidate>(
                initialValue: _mapping,
                decoration: const InputDecoration(
                  labelText: 'Path root mapping',
                ),
                items: [
                  for (final candidate in widget.preview.mappingCandidates)
                    DropdownMenuItem(
                      value: candidate,
                      child: Text(
                        '${candidate.sourcePrefix} → ${candidate.targetRoot} '
                        '(${candidate.resolvedCount} matches)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) => setState(() => _mapping = value),
              ),
            ] else if (widget.preview.exactPaths.length <
                widget.preview.originalPaths.length) ...[
              const SizedBox(height: 16),
              const Text('No compatible path root mapping was found.'),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: _parentFolderId,
              decoration: const InputDecoration(labelText: 'Destination'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Root')),
                for (final folder in widget.folders)
                  DropdownMenuItem(value: folder.id, child: Text(folder.name)),
              ],
              onChanged: (value) => setState(() => _parentFolderId = value),
            ),
            const SizedBox(height: 16),
            Text('$available available · $unavailable unavailable'),
            if (unavailable > 0)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Unavailable paths will be preserved and may become '
                  'available after changing or rescanning the library.',
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Skip'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(
            context,
          ).pop(_PlaylistImportConfirmationResult(_mapping, _parentFolderId)),
          child: const Text('Import'),
        ),
      ],
    );
  }
}

class _PlaylistEditorResult {
  const _PlaylistEditorResult({required this.name, required this.tracks});

  final String name;
  final List<LibraryTrack> tracks;
}

class _PlaylistEditorDialog extends StatefulWidget {
  const _PlaylistEditorDialog({
    required this.tracks,
    required this.title,
    required this.confirmLabel,
    this.playlist,
  });

  final List<LibraryTrack> tracks;
  final Playlist? playlist;
  final String title;
  final String confirmLabel;

  @override
  State<_PlaylistEditorDialog> createState() => _PlaylistEditorDialogState();
}

class _PlaylistEditorDialogState extends State<_PlaylistEditorDialog> {
  final _controller = TextEditingController();
  late final List<LibraryTrack> _selectedTracks;
  final Set<String> _availableSelection = <String>{};
  final Set<String> _playlistSelection = <String>{};
  String _filterQuery = '';

  @override
  void initState() {
    super.initState();
    _controller.text = widget.playlist?.name ?? '';
    final tracksByPath = {
      for (final track in widget.tracks)
        normalizeLibraryComparisonPath(track.sourcePath): track,
    };
    _selectedTracks = [
      for (final path in widget.playlist?.trackPaths ?? const <String>[])
        tracksByPath[normalizeLibraryComparisonPath(path)] ??
            LibraryTrack(sourcePath: path, title: 'Unavailable track'),
    ];
  }

  List<LibraryTrack> get _availableTracks {
    final selectedPaths = _selectedTracks
        .map((track) => normalizeLibraryComparisonPath(track.sourcePath))
        .toSet();
    return _filterTracks(
      widget.tracks.where(
        (track) => !selectedPaths.contains(
          normalizeLibraryComparisonPath(track.sourcePath),
        ),
      ),
    );
  }

  List<LibraryTrack> get _visibleSelectedTracks =>
      _filterTracks(_selectedTracks);

  List<LibraryTrack> _filterTracks(Iterable<LibraryTrack> tracks) {
    final query = _filterQuery.trim().toLowerCase();
    if (query.isEmpty) return tracks.toList(growable: false);
    return tracks
        .where(
          (track) => [track.title, track.artist, track.album, track.sourcePath]
              .whereType<String>()
              .any((value) => value.toLowerCase().contains(query)),
        )
        .toList(growable: false);
  }

  void _toggleAvailable(String path) {
    setState(() {
      if (!_availableSelection.add(path)) _availableSelection.remove(path);
    });
  }

  void _togglePlaylist(String path) {
    setState(() {
      if (!_playlistSelection.add(path)) _playlistSelection.remove(path);
    });
  }

  void _addSelected() {
    if (_availableSelection.isEmpty) return;
    final selectedPaths = _selectedTracks
        .map((track) => normalizeLibraryComparisonPath(track.sourcePath))
        .toSet();
    setState(() {
      for (final track in widget.tracks) {
        if (_availableSelection.contains(track.sourcePath) &&
            selectedPaths.add(
              normalizeLibraryComparisonPath(track.sourcePath),
            )) {
          _selectedTracks.add(track);
        }
      }
      _availableSelection.clear();
    });
  }

  void _removeSelected() {
    if (_playlistSelection.isEmpty) return;
    setState(() {
      _selectedTracks.removeWhere(
        (track) => _playlistSelection.contains(track.sourcePath),
      );
      _playlistSelection.clear();
    });
  }

  void _reorderPlaylist(int oldIndex, int newIndex) {
    setState(() {
      final track = _selectedTracks.removeAt(oldIndex);
      _selectedTracks.insert(newIndex, track);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSave =
        _controller.text.trim().isNotEmpty && _selectedTracks.isNotEmpty;
    final editorHeight = (MediaQuery.sizeOf(context).height * 0.62).clamp(
      320.0,
      560.0,
    );
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 920,
        height: editorHeight,
        child: Column(
          children: [
            TextField(
              controller: _controller,
              autofocus: widget.playlist == null,
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Filter tracks',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _filterQuery = value),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 620;
                  final available = _TrackSelectionPane(
                    title: 'Available tracks',
                    tracks: _availableTracks,
                    selectedPaths: _availableSelection,
                    actionIcon: Icons.add,
                    actionLabel: 'Add selected',
                    onToggle: _toggleAvailable,
                    onAction: _addSelected,
                    emptyMessage: _filterQuery.trim().isEmpty
                        ? 'All library tracks are selected.'
                        : 'No matching tracks.',
                  );
                  final selected = _TrackSelectionPane(
                    title: 'Playlist tracks (${_selectedTracks.length})',
                    tracks: _visibleSelectedTracks,
                    selectedPaths: _playlistSelection,
                    actionIcon: Icons.remove,
                    actionLabel: 'Remove selected',
                    onToggle: _togglePlaylist,
                    onAction: _removeSelected,
                    reorderable: _filterQuery.trim().isEmpty,
                    onReorder: _reorderPlaylist,
                    emptyMessage: _filterQuery.trim().isEmpty
                        ? 'No tracks selected.'
                        : 'No matching tracks.',
                  );
                  if (compact) {
                    return Column(
                      children: [
                        Expanded(child: available),
                        const SizedBox(height: 12),
                        Expanded(child: selected),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: available),
                      const SizedBox(width: 12),
                      Expanded(child: selected),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: canSave
              ? () => Navigator.of(context).pop(
                  _PlaylistEditorResult(
                    name: _controller.text,
                    tracks: List.unmodifiable(_selectedTracks),
                  ),
                )
              : null,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

class _TrackSelectionPane extends StatelessWidget {
  const _TrackSelectionPane({
    required this.title,
    required this.tracks,
    required this.selectedPaths,
    required this.actionIcon,
    required this.actionLabel,
    required this.onToggle,
    required this.onAction,
    required this.emptyMessage,
    this.reorderable = false,
    this.onReorder,
  });

  final String title;
  final List<LibraryTrack> tracks;
  final Set<String> selectedPaths;
  final IconData actionIcon;
  final String actionLabel;
  final ValueChanged<String> onToggle;
  final VoidCallback onAction;
  final String emptyMessage;
  final bool reorderable;
  final void Function(int oldIndex, int newIndex)? onReorder;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (selectedPaths.isNotEmpty)
                  TextButton.icon(
                    onPressed: onAction,
                    icon: Icon(actionIcon, size: 18),
                    label: Text('$actionLabel (${selectedPaths.length})'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: tracks.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        emptyMessage,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  )
                : reorderable
                ? ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    itemCount: tracks.length,
                    onReorderItem: onReorder!,
                    itemBuilder: (context, index) => _trackTile(
                      context,
                      tracks[index],
                      reorderable: true,
                      reorderIndex: index,
                    ),
                  )
                : ListView.builder(
                    itemCount: tracks.length,
                    itemBuilder: (context, index) =>
                        _trackTile(context, tracks[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _trackTile(
    BuildContext context,
    LibraryTrack track, {
    bool reorderable = false,
    int? reorderIndex,
  }) {
    return ListTile(
      key: ValueKey(track.sourcePath),
      dense: true,
      leading: Checkbox(
        value: selectedPaths.contains(track.sourcePath),
        onChanged: (_) => onToggle(track.sourcePath),
      ),
      title: Text(
        track.title ?? track.sourcePath,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        ([track.artist, track.album]
                    .whereType<String>()
                    .where((value) => value.isNotEmpty)
                    .join(' · '))
                .isEmpty
            ? track.sourcePath
            : [track.artist, track.album]
                  .whereType<String>()
                  .where((value) => value.isNotEmpty)
                  .join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => onToggle(track.sourcePath),
      trailing: reorderable
          ? ReorderableDragStartListener(
              index: reorderIndex!,
              child: const Icon(Icons.drag_handle),
            )
          : const Icon(Icons.music_note_outlined),
    );
  }
}

class _AutomaticPlaylistEditorResult {
  const _AutomaticPlaylistEditorResult({
    required this.name,
    required this.query,
  });

  final String name;
  final String query;
}

class _AutomaticPlaylistEditorDialog extends StatefulWidget {
  const _AutomaticPlaylistEditorDialog({
    required this.title,
    required this.confirmLabel,
    this.playlist,
    this.tracks = const [],
  });

  final String title;
  final String confirmLabel;
  final Playlist? playlist;
  final List<LibraryTrack> tracks;

  @override
  State<_AutomaticPlaylistEditorDialog> createState() =>
      _AutomaticPlaylistEditorDialogState();
}

class _AutomaticPlaylistEditorDialogState
    extends State<_AutomaticPlaylistEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _queryController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.playlist?.name);
    _queryController = TextEditingController(text: widget.playlist?.query);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _nameController.text.trim().isNotEmpty &&
      _queryController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Playlist name'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _queryController,
              decoration: const InputDecoration(
                labelText: 'Match text',
                helperText: 'Matches title, artist, album, or source path.',
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
            if (widget.tracks.isNotEmpty) ...[
              const SizedBox(height: 20),
              AutoPlaylistPreview(
                tracks: widget.tracks,
                query: _queryController.text,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isValid ? _submit : null,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }

  void _submit() {
    if (!_isValid) return;
    Navigator.of(context).pop(
      _AutomaticPlaylistEditorResult(
        name: _nameController.text.trim(),
        query: _queryController.text.trim(),
      ),
    );
  }
}
