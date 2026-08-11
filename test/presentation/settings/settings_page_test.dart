import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:music_base/app/library_providers.dart';
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
