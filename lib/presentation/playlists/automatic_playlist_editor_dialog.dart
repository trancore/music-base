part of 'playlists_page.dart';

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
