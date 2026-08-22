import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../app/app_version.dart';
import '../../app/library_providers.dart';
import '../../app/smb_providers.dart';
import '../../domain/library/smb_source.dart';
import '../../domain/library/library_audio_formats.dart';
import '../../domain/settings/app_locale.dart';
import '../../l10n/generated/app_localizations.dart';

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

    final isCompact = MediaQuery.sizeOf(context).width < 700;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: isCompact ? null : AppBar(title: const Text('Settings')),
      body: Column(
        children: [
          if (isCompact)
            SizedBox(
              height: kToolbarHeight,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Settings',
                    style: Theme.of(context).appBarTheme.titleTextStyle,
                  ),
                ),
              ),
            ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: ListView(
                primary: false,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                children: [
                  _SettingsSection(
                    title: 'Appearance',
                    subtitle: l10n.appearanceSubtitle,
                    child: Column(
                      children: [
                        DropdownButtonFormField<ThemeMode>(
                          initialValue: settings.themeMode,
                          decoration: InputDecoration(
                            labelText: l10n.themeLabel,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: ThemeMode.system,
                              child: Text(l10n.themeSystem),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.light,
                              child: Text(l10n.themeLight),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.dark,
                              child: Text(l10n.themeDark),
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
                          decoration: InputDecoration(
                            labelText: l10n.accentColorLabel,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 0xFF8C7BFF,
                              child: Text(l10n.accentViolet),
                            ),
                            // Keep the previous default available for existing saved settings.
                            DropdownMenuItem(
                              value: 0xFF6750A4,
                              child: Text(l10n.accentPurple),
                            ),
                            DropdownMenuItem(
                              value: 0xFF006A6A,
                              child: Text(l10n.accentTeal),
                            ),
                            DropdownMenuItem(
                              value: 0xFF8C5000,
                              child: Text(l10n.accentAmber),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              ref
                                  .read(appSettingsProvider.notifier)
                                  .setAccentColor(value);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<AppLocale>(
                          initialValue: settings.locale,
                          decoration: InputDecoration(
                            labelText: l10n.languageLabel,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: AppLocale.system,
                              child: Text(l10n.languageSystem),
                            ),
                            DropdownMenuItem(
                              value: AppLocale.english,
                              child: Text(l10n.languageEnglish),
                            ),
                            DropdownMenuItem(
                              value: AppLocale.japanese,
                              child: Text(l10n.languageJapanese),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              ref
                                  .read(appSettingsProvider.notifier)
                                  .setLocale(value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SettingsSection(
                    title: 'Local library',
                    subtitle: l10n.localLibrarySubtitle,
                    child: const LocalLibrarySourceSection(),
                  ),
                  const SizedBox(height: 16),
                  _SettingsSection(
                    title: 'SMB library',
                    subtitle: l10n.smbLibrarySubtitle,
                    child: const SmbConnectionForm(),
                  ),
                  const SizedBox(height: 16),
                  _SettingsSection(
                    title: 'Help',
                    subtitle: l10n.helpSubtitle,
                    child: const DocumentationSection(),
                  ),
                  const SizedBox(height: 16),
                  _SettingsSection(
                    title: 'About',
                    subtitle: l10n.aboutSubtitle,
                    child: const VersionSection(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
