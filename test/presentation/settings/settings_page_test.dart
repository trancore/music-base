import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:music_base/app/library_providers.dart';
import 'package:music_base/app/providers.dart';
import 'package:music_base/app/smb_providers.dart';
import 'package:music_base/data/library/smb_settings_repository.dart';
import 'package:music_base/domain/library/library_repository.dart';
import 'package:music_base/domain/library/library_track.dart';
import 'package:music_base/domain/library/smb_source.dart';
import 'package:music_base/presentation/settings/settings_page.dart';

void main() {
  testWidgets('shows the saved local library source', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          libraryRepositoryProvider.overrideWithValue(
            const _FakeLibraryRepository('/Music'),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: LocalLibrarySourceSection()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Current source'), findsOneWidget);
    expect(find.text('/Music'), findsOneWidget);
    expect(find.text('Choose'), findsOneWidget);
  });

  testWidgets('restores saved SMB source values in the form', (tester) async {
    const source = SmbSource(
      host: '192.168.0.216',
      share: 'file-server',
      subfolder: 'Music',
      username: 'kosuke',
    );
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          smbSettingsRepositoryProvider.overrideWithValue(
            _FakeSmbSettingsRepository(source),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: SmbConnectionForm())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, source.host), findsOneWidget);
    expect(find.widgetWithText(TextField, source.share), findsOneWidget);
    expect(find.widgetWithText(TextField, source.subfolder), findsOneWidget);
    expect(find.widgetWithText(TextField, source.username), findsOneWidget);
  });
}

class _FakeSmbSettingsRepository implements SmbSettingsRepository {
  const _FakeSmbSettingsRepository(this.source);

  final SmbSource source;

  @override
  Future<void> clear() async {}

  @override
  Future<String?> loadPassword() async => 'password';

  @override
  Future<SmbSource?> loadSource() async => source;

  @override
  Future<void> save(SmbSource source, String password) async {}
}

class _FakeLibraryRepository implements LibraryRepository {
  const _FakeLibraryRepository(this.sourcePath);

  final String sourcePath;

  @override
  Future<String?> loadSourcePath() async => sourcePath;

  @override
  Future<void> saveSourcePath(String path) async {}

  @override
  Future<List<LibraryTrack>> loadTracks() async => const [];

  @override
  Future<List<LibraryTrack>> scanAndCache(String path) async => const [];

  @override
  Future<List<LibraryTrack>> scanSmbAndCache(
    SmbSource source,
    String password,
  ) async => const [];
}
