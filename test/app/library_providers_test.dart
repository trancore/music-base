import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:music_base/app/library_providers.dart';
import 'package:music_base/app/smb_providers.dart';
import 'package:music_base/data/library/smb_settings_repository.dart';
import 'package:music_base/domain/library/library_repository.dart';
import 'package:music_base/domain/library/library_query.dart';
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
    expect(container.read(libraryProvider).hasError, isFalse);
    expect(container.read(libraryProvider).value, repository.tracks);
    expect(
      container.read(libraryProvider.notifier).refreshWarning,
      contains('Library scan failed'),
    );
    await container.read(libraryProvider.notifier).rescan();

    expect(repository.scannedPaths, [r'D:\Music', r'D:\Music']);
    expect(container.read(libraryProvider).value, repository.tracks);
  });

  test('keeps cached tracks visible while a rescan runs', () async {
    final gate = Completer<void>();
    final repository = _FakeLibraryRepository(
      sourcePath: '/music',
      scanGate: gate,
      tracks: const [LibraryTrack(sourcePath: '/music/cached.flac')],
    );
    final container = ProviderContainer(
      overrides: [libraryRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(libraryProvider.future);
    final scan = container.read(libraryProvider.notifier).rescan();
    await Future<void>.delayed(Duration.zero);

    expect(container.read(libraryProvider.notifier).isRefreshing, isTrue);
    expect(container.read(libraryProvider).isLoading, isFalse);
    expect(container.read(libraryProvider).value, repository.tracks);

    gate.complete();
    await scan;
    expect(container.read(libraryProvider.notifier).isRefreshing, isFalse);
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

  test('passes the selected album to the first page query', () async {
    final repository = _FakeLibraryRepository(
      sourcePath: '/music',
      tracks: const [LibraryTrack(sourcePath: '/music/recording.flac')],
    );
    final container = ProviderContainer(
      overrides: [libraryRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(libraryProvider.future);
    await container
        .read(libraryProvider.notifier)
        .setGroup(
          const LibraryGroup(
            kind: LibraryGroupKind.album,
            value: 'selected collection',
            trackCount: 1,
          ),
        );

    expect(repository.queries.last.album, 'selected collection');
    expect(repository.queries.last.artist, isNull);
  });

  test('passes the selected artist to the first page query', () async {
    final repository = _FakeLibraryRepository(
      sourcePath: '/music',
      tracks: const [LibraryTrack(sourcePath: '/music/recording.flac')],
    );
    final container = ProviderContainer(
      overrides: [libraryRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(libraryProvider.future);
    await container
        .read(libraryProvider.notifier)
        .setGroup(
          const LibraryGroup(
            kind: LibraryGroupKind.artist,
            value: 'selected performer',
            trackCount: 1,
          ),
        );

    expect(repository.queries.last.artist, 'selected performer');
    expect(repository.queries.last.album, isNull);
  });

  test('ignores a stale search response that finishes last', () async {
    final firstGate = Completer<void>();
    final repository = _FakeLibraryRepository(
      sourcePath: '/music',
      queryGates: {'first': firstGate},
      queryTracksBySearch: {
        'first': const [
          LibraryTrack(sourcePath: '/music/first.flac', title: 'first'),
        ],
        'second': const [
          LibraryTrack(sourcePath: '/music/second.flac', title: 'second'),
        ],
      },
    );
    final container = ProviderContainer(
      overrides: [libraryRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(libraryProvider.future);
    final first = container
        .read(libraryProvider.notifier)
        .setQuery(search: 'first');
    await Future<void>.delayed(Duration.zero);
    await container.read(libraryProvider.notifier).setQuery(search: 'second');
    firstGate.complete();
    await first;

    expect(container.read(libraryProvider).value?.single.title, 'second');
    expect(container.read(libraryProvider.notifier).query.search, 'second');
  });

  test('manual SMB scan supersedes an in-flight background refresh', () async {
    final backgroundGate = Completer<void>();
    final repository = _FakeLibraryRepository(
      sourcePath: 'smb://server/share',
      scanGate: backgroundGate,
      tracks: const [],
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
    final background = container
        .read(libraryProvider.notifier)
        .refreshInBackground();
    await Future<void>.delayed(Duration.zero);
    expect(container.read(libraryProvider.notifier).isRefreshing, isTrue);

    final manual = container.read(libraryProvider.notifier).scanSmb();
    await Future<void>.delayed(Duration.zero);
    expect(repository.smbScanCount, 2);

    backgroundGate.complete();
    await manual;
    await background;
    expect(container.read(libraryProvider.notifier).isRefreshing, isFalse);
    expect(
      container.read(libraryProvider.notifier).activeSourcePath,
      'smb://server/share',
    );
  });

  test('manual SMB scan runs when cached tracks already exist', () async {
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
    await container.read(libraryProvider.notifier).refreshInBackground();
    expect(repository.smbScanCount, 0);

    await container.read(libraryProvider.notifier).scanSmb();
    expect(repository.smbScanCount, 1);
  });

  test('keeps SMB active when background refresh fails', () async {
    final repository = _FakeLibraryRepository(
      sourcePath: 'smb://server/share',
      failuresRemaining: 1,
      lastLocalSourcePath: '/music',
      tracks: const [],
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
    await container.read(libraryProvider.notifier).refreshInBackground();

    final notifier = container.read(libraryProvider.notifier);
    expect(notifier.activeSourcePath, 'smb://server/share');
    expect(notifier.refreshWarning, contains('SMB library refresh failed'));
    expect(repository.fallbackLocalScanCount, 0);
    expect(container.read(libraryProvider).value, isEmpty);
  });

  test('reports missing SMB configuration when scan is requested', () async {
    final repository = _FakeLibraryRepository(
      sourcePath: 'smb://server/share',
      tracks: const [LibraryTrack(sourcePath: r'\\server\share\Song.flac')],
    );
    final container = ProviderContainer(
      overrides: [
        libraryRepositoryProvider.overrideWithValue(repository),
        smbSourceProvider.overrideWith(_UnconfiguredSmbSourceNotifier.new),
        smbSettingsRepositoryProvider.overrideWithValue(
          const _FakeSmbSettingsRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(libraryProvider.future);
    await container.read(libraryProvider.notifier).scanSmb();

    expect(
      container.read(libraryProvider.notifier).refreshWarning,
      'SMB library is not configured.',
    );
    expect(repository.smbScanCount, 0);
  });

  test('skips automatic SMB background refresh when cache exists', () async {
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
    await container.read(libraryProvider.notifier).refreshInBackground();

    expect(repository.smbScanCount, 0);
    expect(container.read(libraryProvider.notifier).isRefreshing, isFalse);
  });

  test('refreshes SMB in the background when the cache is empty', () async {
    final repository = _FakeLibraryRepository(
      sourcePath: 'smb://server/share',
      tracks: const [],
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
    await container.read(libraryProvider.notifier).refreshInBackground();

    expect(repository.smbScanCount, 1);
    expect(container.read(libraryProvider.notifier).isRefreshing, isFalse);
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

class _UnconfiguredSmbSourceNotifier extends SmbSourceNotifier {
  @override
  Future<SmbSource?> build() async => null;
}

class _FakeLibraryRepository implements LibraryRepository {
  _FakeLibraryRepository({
    required this.sourcePath,
    this.failuresRemaining = 0,
    this.tracks = const [],
    this.scanGate,
    this.queryGates = const {},
    this.queryTracksBySearch = const {},
    this.lastLocalSourcePath,
  });

  final String sourcePath;
  int failuresRemaining;
  final List<LibraryTrack> tracks;
  final Completer<void>? scanGate;
  final Map<String, Completer<void>> queryGates;
  final Map<String, List<LibraryTrack>> queryTracksBySearch;
  final String? lastLocalSourcePath;
  final scannedPaths = <String>[];
  final queries = <LibraryQuery>[];
  var smbScanCount = 0;
  var fallbackLocalScanCount = 0;
  var savedSourcePath = '';

  @override
  Future<String?> loadSourcePath() async => sourcePath;

  @override
  Future<void> saveSourcePath(String path) async {
    savedSourcePath = path;
  }

  @override
  Future<List<LibraryTrack>> loadTracks() async => const [];

  @override
  Future<List<LibraryTrack>> scanAndCache(String path) async {
    scannedPaths.add(path);
    await scanGate?.future;
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
    if (scanGate != null && smbScanCount == 1) {
      await scanGate!.future;
    }
    if (failuresRemaining > 0) {
      failuresRemaining--;
      throw StateError('temporary scan failure');
    }
    return tracks;
  }

  @override
  Future<String?> loadLastLocalSourcePath() async => lastLocalSourcePath;

  @override
  Future<LibraryPage> queryTracks(LibraryQuery query) async {
    queries.add(query);
    await queryGates[query.search]?.future;
    final result = queryTracksBySearch[query.search] ?? tracks;
    return LibraryPage(items: result, totalCount: result.length);
  }

  @override
  Future<LibraryGroupPage> queryGroups(LibraryGroupQuery query) async =>
      const LibraryGroupPage(items: [], totalCount: 0);

  @override
  Future<List<LibraryTrack>> resolveTrackPaths(Iterable<String> paths) async =>
      tracks.where((track) => paths.contains(track.sourcePath)).toList();

  @override
  Future<LibraryPlaybackQueueDescriptor> createPlaybackQueue(
    LibraryQuery query,
  ) async => const LibraryPlaybackQueueDescriptor(id: 'test', length: 0);

  @override
  Future<LibraryTrack?> loadPlaybackQueueTrack(
    String queueId,
    int index,
  ) async => null;

  @override
  Future<void> deletePlaybackQueue(String queueId) async {}

  @override
  Future<LibraryTrack?> loadTrackById(int id) async => null;

  @override
  Future<List<int>?> loadArtwork(int trackId) async => null;

  @override
  Future<List<LibraryTrack>> scanFallbackLocal(String path) async {
    fallbackLocalScanCount++;
    return scanAndCache(path);
  }
}
