part of 'playlists_page.dart';

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
