import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../app/library_providers.dart';
import '../../app/smb_providers.dart';
import '../../domain/library/smb_source.dart';

part 'settings_sections.dart';

const userGuideUrl = 'https://trancore.github.io/music-base/ja/user-guide/';

final externalUrlLauncherProvider = Provider<Future<bool> Function(Uri)>((ref) {
  return launchUrl;
});

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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _SettingsSection(
            title: 'Appearance',
            subtitle: 'Tune the workspace to your setup.',
            child: Column(
              children: [
                DropdownButtonFormField<ThemeMode>(
                  initialValue: settings.themeMode,
                  decoration: const InputDecoration(labelText: 'Theme'),
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('System'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Light'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Dark'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      ref
                          .read(appSettingsProvider.notifier)
                          .setThemeMode(value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: settings.accentColorValue,
                  decoration: const InputDecoration(labelText: 'Accent color'),
                  items: const [
                    DropdownMenuItem(value: 0xFF8C7BFF, child: Text('Violet')),
                    // Keep the previous default available for existing saved settings.
                    DropdownMenuItem(value: 0xFF6750A4, child: Text('Purple')),
                    DropdownMenuItem(value: 0xFF006A6A, child: Text('Teal')),
                    DropdownMenuItem(value: 0xFF8C5000, child: Text('Amber')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      ref
                          .read(appSettingsProvider.notifier)
                          .setAccentColor(value);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Local library',
            subtitle:
                'Choose a local directory to scan and use as the library source.',
            child: const LocalLibrarySourceSection(),
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'SMB library',
            subtitle: 'Credentials are stored in platform secure storage.',
            child: const SmbConnectionForm(),
          ),
          const SizedBox(height: 16),
          const _SettingsSection(
            title: 'Help',
            subtitle: 'Learn how to set up and use the application.',
            child: DocumentationSection(),
          ),
        ],
      ),
    );
  }
}
