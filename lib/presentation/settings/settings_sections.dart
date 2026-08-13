part of 'settings_page.dart';

class DocumentationSection extends ConsumerWidget {
  const DocumentationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.help_outline),
        title: const Text('User guide (GitHub Pages)'),
        subtitle: const Text(userGuideUrl),
        trailing: const Icon(Icons.open_in_new),
        onTap: () => _openGuide(context, ref),
      ),
      TextButton.icon(
        onPressed: () => _copyGuideUrl(context),
        icon: const Icon(Icons.copy),
        label: const Text('Copy link'),
      ),
    ],
  );

  Future<void> _openGuide(BuildContext context, WidgetRef ref) async {
    var opened = false;
    try {
      opened = await ref.read(externalUrlLauncherProvider)(
        Uri.parse(userGuideUrl),
      );
    } on Object {
      opened = false;
    }
    if (!context.mounted || opened) return;
    await Clipboard.setData(const ClipboardData(text: userGuideUrl));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open the user guide. The link was copied.'),
      ),
    );
  }

  Future<void> _copyGuideUrl(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: userGuideUrl));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('User guide link copied.')));
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 18),
          child,
        ],
      ),
    ),
  );
}

class LocalLibrarySourceSection extends ConsumerWidget {
  const LocalLibrarySourceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(libraryProvider);
    final notifier = ref.read(libraryProvider.notifier);
    final sourcePath = notifier.sourcePath;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.folder_outlined),
          title: const Text('Current source'),
          subtitle: Text(sourcePath ?? 'No local directory configured.'),
          trailing: FilledButton.icon(
            onPressed: notifier.isRefreshing
                ? null
                : () => _chooseDirectory(ref),
            icon: const Icon(Icons.folder_open),
            label: const Text('Choose'),
          ),
        ),
        if (notifier.refreshWarning case final warning?)
          Text(
            warning,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (notifier.isRefreshing) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          const Text(
            'Scanning in the background. Cached music remains available.',
          ),
        ],
      ],
    );
  }

  Future<void> _chooseDirectory(WidgetRef ref) async {
    final path = await getDirectoryPath();
    if (path == null || path.trim().isEmpty) return;
    await ref.read(libraryProvider.notifier).selectDirectory(path);
  }
}

class SmbConnectionForm extends ConsumerStatefulWidget {
  const SmbConnectionForm({super.key});

  @override
  ConsumerState<SmbConnectionForm> createState() => _SmbConnectionFormState();
}

class _SmbConnectionFormState extends ConsumerState<SmbConnectionForm> {
  final _hostController = TextEditingController();
  final _shareController = TextEditingController();
  final _subfolderController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _initialized = false;
  bool _busy = false;
  String? _message;
  bool _success = false;

  @override
  void dispose() {
    _hostController.dispose();
    _shareController.dispose();
    _subfolderController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sourceState = ref.watch(smbSourceProvider);
    final source = sourceState.valueOrNull;
    _restoreSourceIfNeeded(source);

    return Column(
      children: [
        TextField(
          controller: _hostController,
          decoration: const InputDecoration(labelText: 'Host'),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _shareController,
          decoration: const InputDecoration(labelText: 'Share'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _subfolderController,
          decoration: const InputDecoration(labelText: 'Subfolder (optional)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _usernameController,
          decoration: const InputDecoration(labelText: 'Username'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: _busy ? null : _testAndSave,
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.network_check),
                label: const Text('Connect, save, and scan'),
              ),
              if (source != null)
                OutlinedButton.icon(
                  onPressed: _busy ? null : _scanLibrary,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Scan library'),
                ),
              if (source != null)
                OutlinedButton.icon(
                  onPressed: _busy ? null : _clearSettings,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear saved SMB settings'),
                ),
            ],
          ),
        ),
        if (_message != null) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _message!,
              style: TextStyle(
                color: _success
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _restoreSourceIfNeeded(SmbSource? source) {
    if (_initialized || source == null) return;
    _setSource(source);
    _initialized = true;
  }

  Future<void> _testAndSave() async {
    final source = SmbSource(
      host: _hostController.text.trim(),
      share: _shareController.text.trim(),
      subfolder: _subfolderController.text.trim(),
      username: _usernameController.text.trim(),
    );
    final password = _passwordController.text.isNotEmpty
        ? _passwordController.text
        : await ref.read(smbSettingsRepositoryProvider).loadPassword() ?? '';

    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await ref.read(smbServiceProvider).testConnection(source, password);
      await ref.read(smbSourceProvider.notifier).save(source, password);
      await ref.read(libraryProvider.notifier).scanSmb();
      if (!mounted) return;
      final libraryNotifier = ref.read(libraryProvider.notifier);
      final scanError = libraryNotifier.refreshWarning;
      setState(() {
        _busy = false;
        _success = scanError == null;
        _message = scanError != null
            ? 'Connection succeeded, but $scanError'
            : 'Connection succeeded. Found '
                  '${libraryNotifier.totalCount} FLAC/MP3 files.';
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _success = false;
        _message = error.toString();
      });
    }
  }

  void _setSource(SmbSource source) {
    _hostController.text = source.host;
    _shareController.text = source.share;
    _subfolderController.text = source.subfolder;
    _usernameController.text = source.username;
  }

  Future<void> _scanLibrary() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    await ref.read(libraryProvider.notifier).scanSmb();
    if (!mounted) return;
    final libraryNotifier = ref.read(libraryProvider.notifier);
    final scanError = libraryNotifier.refreshWarning;
    setState(() {
      _busy = false;
      _success = scanError == null;
      _message =
          scanError ?? 'Found ${libraryNotifier.totalCount} FLAC/MP3 files.';
    });
  }

  Future<void> _clearSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear SMB settings?'),
        content: const Text(
          'The saved SMB source and password will be removed from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(smbSourceProvider.notifier).clear();
    if (!mounted) return;
    _hostController.clear();
    _shareController.clear();
    _subfolderController.clear();
    _usernameController.clear();
    _passwordController.clear();
    setState(() {
      _initialized = true;
      _success = true;
      _message = 'Saved SMB settings were cleared.';
    });
  }
}
