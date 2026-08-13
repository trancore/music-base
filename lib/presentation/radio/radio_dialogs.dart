part of 'radio_page.dart';

class _RadioBrowserSearchDialog extends ConsumerStatefulWidget {
  const _RadioBrowserSearchDialog();

  @override
  ConsumerState<_RadioBrowserSearchDialog> createState() =>
      _RadioBrowserSearchDialogState();
}

class _RadioBrowserSearchDialogState
    extends ConsumerState<_RadioBrowserSearchDialog> {
  final _queryController = TextEditingController();
  List<RadioBrowserStation> _stations = const [];
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      title: Row(
        children: [
          Icon(Icons.travel_explore, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Find a station',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 620,
        height: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search Radio Browser by station name, genre, or country.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Search stations',
                      hintText: 'BBC, jazz...',
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _busy ? null : _search,
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_busy) const LinearProgressIndicator(minHeight: 2),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            if (_stations.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '${_stations.length} stations found',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Expanded(
              child: _stations.isEmpty && !_busy
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.radio_outlined,
                            size: 40,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Search to discover internet radio stations.',
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 8),
                      itemCount: _stations.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final station = _stations[index];
                        final metadata = [
                          if (station.tags case final tags?
                              when tags.trim().isNotEmpty)
                            tags,
                          if (station.codec case final codec?
                              when codec.trim().isNotEmpty)
                            codec,
                          if (station.bitrate case final bitrate?)
                            '$bitrate kbps',
                        ].join('  •  ');
                        return Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.fromLTRB(
                              16,
                              8,
                              8,
                              8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.14),
                              foregroundColor: theme.colorScheme.primary,
                              child: const Icon(Icons.radio, size: 20),
                            ),
                            title: Text(
                              station.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: metadata.isEmpty
                                ? null
                                : Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      metadata,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                            trailing: IconButton.filledTonal(
                              tooltip: 'Add station',
                              onPressed: () =>
                                  Navigator.of(context).pop(station),
                              icon: const Icon(Icons.add),
                            ),
                            onTap: () => Navigator.of(context).pop(station),
                          ),
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
          child: const Text('Close'),
        ),
      ],
    );
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      setState(() => _error = 'Enter a station name or search term.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _stations = const [];
    });
    try {
      final stations = await ref
          .read(radioBrowserServiceProvider)
          .search(query);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _stations = stations;
        if (stations.isEmpty) _error = 'No reachable stations found.';
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Radio Browser search failed: $error';
      });
    }
  }
}

class _StationDialog extends StatefulWidget {
  const _StationDialog({this.station});

  final InternetRadioStation? station;

  @override
  State<_StationDialog> createState() => _StationDialogState();
}

class _StationDialogState extends State<_StationDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _urlController;
  late final TextEditingController _genreController;
  late final TextEditingController _descriptionController;
  String? _urlError;

  @override
  void initState() {
    super.initState();
    final station = widget.station;
    _nameController = TextEditingController(text: station?.name);
    _urlController = TextEditingController(text: station?.streamUrl);
    _genreController = TextEditingController(text: station?.genre);
    _descriptionController = TextEditingController(text: station?.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _genreController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.station == null ? 'Add radio station' : 'Edit radio station',
    ),
    content: SizedBox(
      width: 520,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Station name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: 'Audio stream URL',
                hintText: 'https://u1.happyhardcore.com/',
                helperText:
                    'Use the direct audio URL, not the station web page.',
                errorText: _urlError,
              ),
              onChanged: (_) {
                if (_urlError != null) setState(() => _urlError = null);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _genreController,
              decoration: const InputDecoration(labelText: 'Genre (optional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Test and save')),
    ],
  );

  void _save() {
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();
    if (name.isEmpty) return;
    final error = validateRadioStationUrl(url);
    if (error != null) {
      setState(() => _urlError = error);
      return;
    }
    Navigator.of(context).pop(
      InternetRadioStation(
        id:
            widget.station?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        streamUrl: url,
        genre: _genreController.text.trim().isEmpty
            ? null
            : _genreController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      ),
    );
  }
}
