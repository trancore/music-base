import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/library_providers.dart';
import '../../app/smb_providers.dart';
import '../../domain/library/smb_source.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider).valueOrNull;
    if (settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Appearance', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          DropdownButtonFormField<ThemeMode>(
            initialValue: settings.themeMode,
            decoration: const InputDecoration(labelText: 'Theme'),
            items: const [
              DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
              DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
              DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
            ],
            onChanged: (value) {
              if (value != null) {
                ref.read(appSettingsProvider.notifier).setThemeMode(value);
              }
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: settings.accentColorValue,
            decoration: const InputDecoration(labelText: 'Accent color'),
            items: const [
              DropdownMenuItem(value: 0xFF6750A4, child: Text('Purple')),
              DropdownMenuItem(value: 0xFF006A6A, child: Text('Teal')),
              DropdownMenuItem(value: 0xFF8C5000, child: Text('Amber')),
            ],
            onChanged: (value) {
              if (value != null) {
                ref.read(appSettingsProvider.notifier).setAccentColor(value);
              }
            },
          ),
          const SizedBox(height: 40),
          Text(
            'Local library',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose a local directory to scan and use as the library source.',
          ),
          const SizedBox(height: 16),
          const LocalLibrarySourceSection(),
          const SizedBox(height: 40),
          Text(
            'SMB library',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text('Credentials are stored in the platform secure storage.'),
          const SizedBox(height: 16),
          const SmbConnectionForm(),
        ],
      ),
    );
  }
}

class LocalLibrarySourceSection extends ConsumerWidget {
  const LocalLibrarySourceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryProvider);
    final sourcePath = ref.read(libraryProvider.notifier).sourcePath;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.folder_outlined),
          title: const Text('Current source'),
          subtitle: Text(sourcePath ?? 'No local directory configured.'),
          trailing: FilledButton.icon(
            onPressed: library.isLoading ? null : () => _chooseDirectory(ref),
            icon: const Icon(Icons.folder_open),
            label: const Text('Choose'),
          ),
        ),
        if (library.hasError)
          Text(
            'Library scan failed: ${library.error}',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (library.isLoading) const LinearProgressIndicator(),
      ],
    );
  }

  Future<void> _chooseDirectory(WidgetRef ref) async {
    final path = await getDirectoryPath();
    if (path == null || path.trim().isEmpty) return;
    await ref.read(libraryProvider.notifier).scanDirectory(path);
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
    if (!_initialized && source != null) {
      _setSource(source);
      _initialized = true;
    }

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
                label: const Text('Test connection and save'),
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
      if (!mounted) return;
      setState(() {
        _busy = false;
        _success = true;
        _message = 'Connection succeeded and settings were saved.';
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
