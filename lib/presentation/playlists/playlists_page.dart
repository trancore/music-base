import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/library_providers.dart';
import '../../app/playback_providers.dart';
import '../../app/playlist_providers.dart';
import '../../data/playlist/m3u_playlist_parser.dart';
import '../../domain/library/library_track.dart';
import '../../domain/playlist/playlist.dart';
import '../../domain/playlist/playlist_tracks.dart';
import 'auto_playlist_preview.dart';

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
            tooltip: 'Import M3U playlist',
            onPressed: () => _importPlaylist(context, notifier, tracks),
            icon: const Icon(Icons.file_open_outlined),
          ),
          IconButton(
            tooltip: 'Create auto playlist',
            onPressed: () => _createAutomaticPlaylist(context, notifier),
            icon: const Icon(Icons.auto_awesome),
          ),
          IconButton(
            tooltip: 'Create playlist',
            onPressed: tracks.isEmpty
                ? null
                : () => _createPlaylist(context, notifier, tracks),
            icon: const Icon(Icons.playlist_add),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: playlists.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text('$error')),
          data: (items) => items.isEmpty
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
                            'Create an auto playlist or import an M3U file.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final playlist = items[index];
                    final playlistTracks = resolvePlaylistTracks(
                      playlist,
                      tracks,
                    );
                    return _PlaylistCard(
                      key: ValueKey(playlist.id),
                      playlist: playlist,
                      tracks: playlistTracks,
                      canEdit: playlist.isAutomatic || tracks.isNotEmpty,
                      onPlay: playlistTracks.isEmpty
                          ? null
                          : () => playback.playQueue(playlistTracks),
                      onEdit: () => playlist.isAutomatic
                          ? _editAutomaticPlaylist(
                              context,
                              notifier,
                              playlist,
                              tracks,
                            )
                          : _editPlaylist(context, notifier, playlist, tracks),
                      onDelete: () => notifier.delete(playlist.id),
                    );
                  },
                ),
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
    PlaylistNotifier notifier,
  ) async {
    final result = await showDialog<_AutomaticPlaylistEditorResult>(
      context: context,
      builder: (context) => const _AutomaticPlaylistEditorDialog(
        title: 'New auto playlist',
        confirmLabel: 'Create',
      ),
    );
    if (result != null) {
      await notifier.createAutomatic(result.name, result.query);
    }
  }

  Future<void> _editAutomaticPlaylist(
    BuildContext context,
    PlaylistNotifier notifier,
    Playlist playlist,
    List<LibraryTrack> tracks,
  ) async {
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
    PlaylistNotifier notifier,
    List<LibraryTrack> tracks,
  ) async {
    const typeGroup = XTypeGroup(
      label: 'M3U playlists',
      extensions: ['m3u', 'm3u8'],
    );
    final file = await openFile(acceptedTypeGroups: const [typeGroup]);
    if (file == null) return;

    try {
      final imported = const M3uPlaylistParser().parseBytes(
        await file.readAsBytes(),
        sourcePath: file.path,
      );
      if (imported.trackPaths.isEmpty) {
        throw const FormatException('The playlist contains no track paths.');
      }
      await notifier.importPlaylist(imported.name, imported.trackPaths);
      if (!context.mounted) return;
      final available = resolvePlaylistTracks(
        Playlist(id: '', name: imported.name, trackPaths: imported.trackPaths),
        tracks,
      ).length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported ${imported.trackPaths.length} tracks ($available available).',
          ),
        ),
      );
    } on Object catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not import playlist: $error')),
      );
    }
  }

  Future<void> _editPlaylist(
    BuildContext context,
    PlaylistNotifier notifier,
    Playlist playlist,
    List<LibraryTrack> tracks,
  ) async {
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
}

class _PlaylistCard extends StatefulWidget {
  const _PlaylistCard({
    required super.key,
    required this.playlist,
    required this.tracks,
    required this.canEdit,
    required this.onPlay,
    required this.onEdit,
    required this.onDelete,
  });

  final Playlist playlist;
  final List<LibraryTrack> tracks;
  final bool canEdit;
  final VoidCallback? onPlay;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
    final subtitle = widget.playlist.isAutomatic
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
            if (widget.tracks.isEmpty)
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
      for (final track in widget.tracks) track.sourcePath: track,
    };
    _selectedTracks = [
      for (final path in widget.playlist?.trackPaths ?? const <String>[])
        if (tracksByPath[path] != null) tracksByPath[path]!,
    ];
  }

  List<LibraryTrack> get _availableTracks {
    final selectedPaths = _selectedTracks
        .map((track) => track.sourcePath)
        .toSet();
    return _filterTracks(
      widget.tracks.where((track) => !selectedPaths.contains(track.sourcePath)),
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
        .map((track) => track.sourcePath)
        .toSet();
    setState(() {
      for (final track in widget.tracks) {
        if (_availableSelection.contains(track.sourcePath) &&
            selectedPaths.add(track.sourcePath)) {
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
        [
          track.artist,
          track.album,
        ].whereType<String>().where((value) => value.isNotEmpty).join(' · '),
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
            if (widget.playlist != null) ...[
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
