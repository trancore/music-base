import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:music_base/app/app.dart';
import 'package:music_base/app/library_providers.dart';
import 'package:music_base/app/providers.dart';
import 'package:music_base/domain/library/library_repository.dart';
import 'package:music_base/domain/library/library_track.dart';
import 'package:music_base/domain/library/smb_source.dart';

void main() {
  testWidgets('renders the Music Base library shell', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          libraryRepositoryProvider.overrideWithValue(
            const _FakeLibraryRepository(),
          ),
        ],
        child: const MusicBaseApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Music Base'), findsOneWidget);
    expect(find.text('Music library'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
  });
}

class _FakeLibraryRepository implements LibraryRepository {
  const _FakeLibraryRepository();

  @override
  Future<String?> loadSourcePath() async => null;

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
