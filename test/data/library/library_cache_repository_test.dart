import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_base/data/database/app_database.dart';
import 'package:music_base/data/library/local_directory_library_scanner.dart';
import 'package:music_base/data/library/shared_preferences_library_repository.dart';
import 'package:music_base/data/library/smb_library_scanner.dart';
import 'package:music_base/app/playlist_import_resolver.dart';
import 'package:music_base/domain/library/library_path_normalizer.dart';
import 'package:music_base/domain/library/library_query.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase database;
  late SharedPreferencesLibraryRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'library.source_path': '/music'});
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = SharedPreferencesLibraryRepository(
      preferences: await SharedPreferences.getInstance(),
      database: database,
      scanner: const LocalDirectoryLibraryScanner(),
      smbScanner: const SmbLibraryScanner(),
    );
  });

  tearDown(() => database.close());

  test(
    'rescanning an existing source path updates instead of inserting',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'library-cache-rescan-',
      );
      addTearDown(() => directory.delete(recursive: true));
      await File('${directory.path}/recording.flac').writeAsBytes(const [0]);

      await repository.scanAndCache(directory.path);
      final first = await database.select(database.libraryTracks).getSingle();
      await repository.scanAndCache(directory.path);
      final second = await database.select(database.libraryTracks).getSingle();

      expect(second.id, first.id);
      expect(second.sourcePath, first.sourcePath);
      expect(await database.select(database.libraryTracks).get(), hasLength(1));
    },
  );

  test('pages deterministically across duplicate sort values', () async {
    for (var index = 0; index < 450; index++) {
      await database
          .into(database.libraryTracks)
          .insert(
            LibraryTracksCompanion.insert(
              sourcePath: '/music/$index.flac',
              sourceKey: const Value('/music'),
              title: const Value('same title'),
              artist: Value(index.isEven ? 'sample artist' : 'other artist'),
            ),
          );
    }

    final first = await repository.queryTracks(const LibraryQuery());
    final second = await repository.queryTracks(
      LibraryQuery(cursor: first.nextCursor),
    );
    final third = await repository.queryTracks(
      LibraryQuery(cursor: second.nextCursor),
    );

    final ids = [
      ...first.items,
      ...second.items,
      ...third.items,
    ].map((track) => track.cacheId).toSet();
    expect(first.totalCount, 450);
    expect(
      [first.items.length, second.items.length, third.items.length],
      [200, 200, 50],
    );
    expect(ids, hasLength(450));
    expect(third.nextCursor, isNull);
  });

  test('uses AND prefix matching for indexed metadata', () async {
    await database
        .into(database.libraryTracks)
        .insert(
          LibraryTracksCompanion.insert(
            sourcePath: '/music/one.flac',
            sourceKey: const Value('/music'),
            title: const Value('sample track'),
            artist: const Value('example artist'),
          ),
        );
    await database
        .into(database.libraryTracks)
        .insert(
          LibraryTracksCompanion.insert(
            sourcePath: '/music/two.flac',
            sourceKey: const Value('/music'),
            title: const Value('sample recording'),
            artist: const Value('other artist'),
          ),
        );

    final result = await repository.queryTracks(
      const LibraryQuery(search: 'samp exam'),
    );

    expect(result.items, hasLength(1));
    expect(result.items.single.sourcePath, '/music/one.flac');
  });

  test('groups albums with counts and keyset pagination', () async {
    for (var index = 0; index < 6; index++) {
      await database
          .into(database.libraryTracks)
          .insert(
            LibraryTracksCompanion.insert(
              sourcePath: '/music/$index.flac',
              sourceKey: const Value('/music'),
              title: Value('track $index'),
              album: Value('album ${index ~/ 2}'),
              artist: const Value('sample artist'),
            ),
          );
    }

    final first = await repository.queryGroups(
      const LibraryGroupQuery(kind: LibraryGroupKind.album, pageSize: 2),
    );
    final second = await repository.queryGroups(
      LibraryGroupQuery(
        kind: LibraryGroupKind.album,
        pageSize: 2,
        cursor: first.nextCursor,
      ),
    );

    expect(first.totalCount, 3);
    expect(first.items.map((item) => item.trackCount), [2, 2]);
    expect(second.items.single.displayName, 'album 2');
    expect(second.nextCursor, isNull);
  });

  test('orders an album by disc and track number before source path', () async {
    for (final entry in [
      (path: 'disc-2-track-1.flac', disc: 2, track: 1),
      (path: 'disc-1-track-10.flac', disc: 1, track: 10),
      (path: 'disc-1-track-2.flac', disc: 1, track: 2),
      (path: 'unknown.flac', disc: null, track: null),
    ]) {
      await database
          .into(database.libraryTracks)
          .insert(
            LibraryTracksCompanion.insert(
              sourcePath: '/music/${entry.path}',
              sourceKey: const Value('/music'),
              album: const Value('sample collection'),
              discNumber: Value(entry.disc),
              trackNumber: Value(entry.track),
            ),
          );
    }

    final result = await repository.queryTracks(
      const LibraryQuery(
        album: 'sample collection',
        sortField: LibrarySortField.albumTrack,
      ),
    );

    expect(result.items.map((track) => track.sourcePath), [
      '/music/disc-1-track-2.flac',
      '/music/disc-1-track-10.flac',
      '/music/disc-2-track-1.flac',
      '/music/unknown.flac',
    ]);
  });

  test('searches artist groups and filters their tracks', () async {
    for (final entry in [
      ('first.flac', 'sample ensemble'),
      ('second.flac', 'sample ensemble'),
      ('third.flac', 'other ensemble'),
    ]) {
      await database
          .into(database.libraryTracks)
          .insert(
            LibraryTracksCompanion.insert(
              sourcePath: '/music/${entry.$1}',
              sourceKey: const Value('/music'),
              title: const Value('recording'),
              artist: Value(entry.$2),
            ),
          );
    }

    final groups = await repository.queryGroups(
      const LibraryGroupQuery(
        kind: LibraryGroupKind.artist,
        search: 'samp ens',
      ),
    );
    final tracks = await repository.queryTracks(
      LibraryQuery(artist: groups.items.single.value),
    );

    expect(groups.items.single.trackCount, 2);
    expect(tracks.items, hasLength(2));
  });

  test('stores large playback order in the database', () async {
    for (var index = 0; index < 3; index++) {
      await database
          .into(database.libraryTracks)
          .insert(
            LibraryTracksCompanion.insert(
              sourcePath: '/music/$index.flac',
              sourceKey: const Value('/music'),
              title: Value('track $index'),
            ),
          );
    }

    final queue = await repository.createPlaybackQueue(const LibraryQuery());
    final second = await repository.loadPlaybackQueueTrack(queue.id, 1);

    expect(queue.length, 3);
    expect(second?.sourcePath, '/music/1.flac');
    await repository.deletePlaybackQueue(queue.id);
    expect(await repository.loadPlaybackQueueTrack(queue.id, 0), isNull);
  });

  test('resolves normalized paths across the full active source', () async {
    await repository.saveSourcePath(r'X:\SampleLibrary');
    for (final entry in [
      (path: r'X:\SampleLibrary\Album\One.flac', source: r'X:\SampleLibrary'),
      (path: r'X:\SampleLibrary\Album\Two.flac', source: r'X:\SampleLibrary'),
      (path: r'X:\OtherSample\Album\One.flac', source: r'X:\OtherSample'),
    ]) {
      await database
          .into(database.libraryTracks)
          .insert(
            LibraryTracksCompanion.insert(
              sourcePath: entry.path,
              comparisonPath: Value(normalizeLibraryComparisonPath(entry.path)),
              sourceKey: Value(entry.source),
            ),
          );
    }

    final result = await repository.resolveTrackPaths([
      'x:/samplelibrary/album/two.flac',
      'X:/SAMPLELIBRARY/ALBUM/ONE.FLAC',
      'x:/samplelibrary/album/two.flac',
      'X:/OtherSample/Album/One.flac',
    ]);

    expect(result.map((track) => track.sourcePath), [
      r'X:\SampleLibrary\Album\Two.flac',
      r'X:\SampleLibrary\Album\One.flac',
      r'X:\SampleLibrary\Album\Two.flac',
    ]);
  });

  test(
    'proposes a verified root mapping and preserves unresolved paths',
    () async {
      await repository.saveSourcePath('/Volumes/Music');
      for (final path in [
        '/Volumes/Music/Album/One.flac',
        '/Volumes/Music/Album/Two.flac',
      ]) {
        await database
            .into(database.libraryTracks)
            .insert(
              LibraryTracksCompanion.insert(
                sourcePath: path,
                comparisonPath: Value(normalizeLibraryComparisonPath(path)),
                sourceKey: const Value('/Volumes/Music'),
              ),
            );
      }

      final preview = await PlaylistImportResolver(repository).resolve(
        name: 'Imported collection',
        paths: const [
          'X:/SampleLibrary/Album/One.flac',
          'X:/SampleLibrary/Album/Two.flac',
          'X:/SampleLibrary/Album/Missing.flac',
        ],
      );
      final mapping = preview.mappingCandidates.first;

      expect(mapping.sourcePrefix, 'X:/SampleLibrary');
      expect(mapping.targetRoot, '/Volumes/Music');
      expect(mapping.resolvedCount, 2);
      expect(preview.resolvedPaths(mapping), [
        '/Volumes/Music/Album/One.flac',
        '/Volumes/Music/Album/Two.flac',
        'X:/SampleLibrary/Album/Missing.flac',
      ]);
      expect(preview.availableCount(mapping), 2);
    },
  );

  test('maps Windows M3U paths to encoded SMB library paths', () async {
    const source = 'smb://files.example.test/music-share';
    await repository.saveSourcePath(source);
    const encodedPaths = [
      'smb://files.example.test/music-share/Audio/'
          '%E9%9F%B3%E6%A5%BD/%E3%82%B3%E3%83%AC%E3%82%AF%E3%82%B7%E3%83%A7%E3%83%B3/'
          'Example%20Label/Sample%20Artist/01-%C3%89tude.flac',
      'smb://files.example.test/music-share/Audio/'
          '%E9%9F%B3%E6%A5%BD/%E3%82%B3%E3%83%AC%E3%82%AF%E3%82%B7%E3%83%A7%E3%83%B3/'
          'Example%20Label/Sample%20Artist/02-Rondo.flac',
    ];
    for (final path in encodedPaths) {
      await database
          .into(database.libraryTracks)
          .insert(
            LibraryTracksCompanion.insert(
              sourcePath: path,
              comparisonPath: Value(normalizeLibraryComparisonPath(path)),
              sourceKey: const Value(source),
            ),
          );
    }

    final preview = await PlaylistImportResolver(repository).resolve(
      name: 'Imported collection',
      paths: const [
        'X:/Audio/音楽/コレクション/Example Label/'
            'Sample Artist/01-Étude.flac',
        'X:/Audio/音楽/コレクション/Example Label/'
            'Sample Artist/02-Rondo.flac',
      ],
    );
    final mapping = preview.mappingCandidates.first;

    expect(mapping.sourcePrefix, 'X:');
    expect(mapping.resolvedCount, 2);
    expect(preview.resolvedPaths(mapping), encodedPaths);
  });
}
