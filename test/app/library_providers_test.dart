import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:music_base/app/library_providers.dart';
import 'package:music_base/app/smb_providers.dart';
import 'package:music_base/data/library/smb_settings_repository.dart';
import 'package:music_base/domain/library/library_repository.dart';
import 'package:music_base/domain/library/library_track.dart';
import 'package:music_base/domain/library/smb_source.dart';

void main() {
  test('rescans the configured local source after a failed scan', () async {
    final repository = _FakeLibraryRepository(
      sourcePath: r'D:\Music',
      failuresRemaining: 1,
      tracks: const [LibraryTrack(sourcePath: r'D:\Music\Song.flac')],
    );
    final container = ProviderContainer(
      overrides: [libraryRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(libraryProvider.future);
    await container.read(libraryProvider.notifier).scanDirectory(r'D:\Music');
    expect(container.read(libraryProvider).hasError, isTrue);
    await container.read(libraryProvider.notifier).rescan();

    expect(repository.scannedPaths, [r'D:\Music', r'D:\Music']);
    expect(container.read(libraryProvider).value, repository.tracks);
  });

  test('rescans the configured SMB source through the SMB scanner', () async {
    final repository = _FakeLibraryRepository(
      sourcePath: 'smb://server/share',
      tracks: const [LibraryTrack(sourcePath: r'\\server\share\Song.flac')],
    );
    final container = ProviderContainer(
      overrides: [
        libraryRepositoryProvider.overrideWithValue(repository),
        smbSourceProvider.overrideWith(_FakeSmbSourceNotifier.new),
        smbSettingsRepositoryProvider.overrideWithValue(
          const _FakeSmbSettingsRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(libraryProvider.future);
    await container.read(libraryProvider.notifier).rescan();

    expect(repository.smbScanCount, 1);
    expect(container.read(libraryProvider).value, repository.tracks);
  });
}

class _FakeSmbSettingsRepository implements SmbSettingsRepository {
  const _FakeSmbSettingsRepository();

  @override
  Future<SmbSource?> loadSource() async => null;

  @override
  Future<String?> loadPassword() async => '';

  @override
  Future<void> save(SmbSource source, String password) async {}

  @override
  Future<void> clear() async {}
}

class _FakeSmbSourceNotifier extends SmbSourceNotifier {
  @override
  Future<SmbSource?> build() async =>
      const SmbSource(host: 'server', share: 'share', username: 'user');
}

class _FakeLibraryRepository implements LibraryRepository {
  _FakeLibraryRepository({
    required this.sourcePath,
    this.failuresRemaining = 0,
    this.tracks = const [],
  });

  final String sourcePath;
  int failuresRemaining;
  final List<LibraryTrack> tracks;
  final scannedPaths = <String>[];
  var smbScanCount = 0;

  @override
  Future<String?> loadSourcePath() async => sourcePath;

  @override
  Future<void> saveSourcePath(String path) async {}

  @override
  Future<List<LibraryTrack>> loadTracks() async => const [];

  @override
  Future<List<LibraryTrack>> scanAndCache(String path) async {
    scannedPaths.add(path);
    if (failuresRemaining > 0) {
      failuresRemaining--;
      throw StateError('temporary scan failure');
    }
    return tracks;
  }

  @override
  Future<List<LibraryTrack>> scanSmbAndCache(
    SmbSource source,
    String password,
  ) async {
    smbScanCount++;
    return tracks;
  }
}
