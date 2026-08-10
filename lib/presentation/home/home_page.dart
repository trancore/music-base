import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/library_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryProvider);
    final sourcePath = ref.read(libraryProvider.notifier).sourcePath;

    return Scaffold(
      appBar: AppBar(title: const Text('Music Base')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Music library',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'The Windows foundation is ready for library and playback services.',
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Library source'),
              subtitle: Text(sourcePath ?? 'No local directory configured.'),
              trailing: FilledButton.icon(
                onPressed: library.isLoading
                    ? null
                    : () async {
                        final selectedPath = await getDirectoryPath();
                        if (selectedPath != null && context.mounted) {
                          await ref
                              .read(libraryProvider.notifier)
                              .scanDirectory(selectedPath);
                        }
                      },
                icon: const Icon(Icons.folder_open),
                label: const Text('Choose'),
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (library.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (library.hasError)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: ListTile(
                leading: const Icon(Icons.error_outline),
                title: const Text('Library scan failed'),
                subtitle: Text(library.error.toString()),
              ),
            )
          else if (library.value!.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.music_off),
                title: Text('No FLAC or MP3 files found'),
                subtitle: Text(
                  'Choose a directory containing your music files.',
                ),
              ),
            )
          else
            ...library.value!.map(
              (track) => ListTile(
                leading: const Icon(Icons.music_note),
                title: Text(track.title ?? track.sourcePath),
                subtitle: Text(track.sourcePath),
              ),
            ),
        ],
      ),
    );
  }
}
