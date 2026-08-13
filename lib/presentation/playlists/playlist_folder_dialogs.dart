part of 'playlists_page.dart';

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
