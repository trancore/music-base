part of 'playlists_page.dart';

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
