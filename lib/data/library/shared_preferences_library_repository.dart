import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/library/library_repository.dart';
import '../../domain/library/library_query.dart';
import '../../domain/library/library_path_normalizer.dart';
import '../../domain/library/local_directory_access_service.dart';
import '../../domain/library/library_scanner.dart';
import '../../domain/library/library_track.dart' as domain;
import '../../domain/library/smb_source.dart';
import '../database/app_database.dart' as db;
import 'smb_library_scanner.dart';

class SharedPreferencesLibraryRepository implements LibraryRepository {
  const SharedPreferencesLibraryRepository({
    required this._preferences,
    required this._database,
    required this._scanner,
    required this._smbScanner,
    this.directoryAccess = const _NoopDirectoryAccessService(),
  });

  static const _sourcePathKey = 'library.source_path';
  static const _lastLocalSourcePathKey = 'library.last_local_source_path';

  final SharedPreferences _preferences;
  final db.AppDatabase _database;
  final LibraryScanner _scanner;
  final SmbLibraryScanner _smbScanner;
  final LocalDirectoryAccessService directoryAccess;

  @override
  Future<String?> loadSourcePath() async {
    final path = _preferences.getString(_sourcePathKey);
    if (path != null && !path.startsWith('smb://')) {
      await directoryAccess.prepareAccess(path);
    }
    if (path != null) {
      await _database.customUpdate(
        'UPDATE library_tracks SET source_key = ? WHERE source_key = ?',
        variables: [Variable.withString(path), Variable.withString('')],
        updates: {_database.libraryTracks},
      );
    }
    return path;
  }

  @override
  Future<String?> loadLastLocalSourcePath() async =>
      _preferences.getString(_lastLocalSourcePathKey);

  @override
  Future<void> saveSourcePath(String path) async {
    await _preferences.setString(_sourcePathKey, path);
    if (!path.startsWith('smb://')) {
      await _preferences.setString(_lastLocalSourcePathKey, path);
      await directoryAccess.saveAccess(path);
    }
  }

  @override
  Future<List<domain.LibraryTrack>> loadTracks() async {
    final source = _preferences.getString(_sourcePathKey);
    final query = _database.select(_database.libraryTracks);
    if (source != null) query.where((row) => row.sourceKey.equals(source));
    final rows = await query.get();
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<LibraryPage> queryTracks(LibraryQuery query) async {
    final source =
        query.sourceKey ?? _preferences.getString(_sourcePathKey) ?? '';
    final sortExpression = switch (query.sortField) {
      LibrarySortField.title => 'LOWER(COALESCE(t.title, t.source_path))',
      LibrarySortField.artist => "LOWER(COALESCE(t.artist, ''))",
      LibrarySortField.album => "LOWER(COALESCE(t.album, ''))",
      LibrarySortField.sourcePath => 'LOWER(t.source_path)',
      LibrarySortField.albumTrack =>
        "printf('%010d:%010d:%s', "
            'COALESCE(t.disc_number, 2147483647), '
            'COALESCE(t.track_number, 2147483647), LOWER(t.source_path))',
    };
    final direction = query.ascending ? 'ASC' : 'DESC';
    final comparison = query.ascending ? '>' : '<';
    final search = _ftsQuery(query.search);
    final from = search == null
        ? 'library_tracks t'
        : 'library_tracks t JOIN library_tracks_fts f ON f.rowid = t.id';
    final where = <String>['t.source_key = ?'];
    final variables = <Variable<Object>>[Variable.withString(source)];
    if (search != null) {
      where.add('library_tracks_fts MATCH ?');
      variables.add(Variable.withString(search));
    }
    _addGroupFilters(query, where, variables);
    if (query.cursor case final cursor?) {
      where.add(
        '($sortExpression $comparison ? OR '
        '($sortExpression = ? AND t.id $comparison ?))',
      );
      variables
        ..add(Variable.withString(cursor.sortValue))
        ..add(Variable.withString(cursor.sortValue))
        ..add(Variable.withInt(cursor.id));
    }
    final limit = query.pageSize.clamp(1, 500);
    variables.add(Variable.withInt(limit));
    final rows = await _database
        .customSelect(
          'SELECT t.* FROM $from WHERE ${where.join(' AND ')} '
          'ORDER BY $sortExpression $direction, t.id $direction LIMIT ?',
          variables: variables,
          readsFrom: {_database.libraryTracks},
        )
        .get();
    final countVariables = <Variable<Object>>[Variable.withString(source)];
    final countWhere = <String>['t.source_key = ?'];
    if (search != null) {
      countWhere.add('library_tracks_fts MATCH ?');
      countVariables.add(Variable.withString(search));
    }
    _addGroupFilters(query, countWhere, countVariables);
    final countRow = await _database
        .customSelect(
          'SELECT COUNT(*) AS count FROM $from WHERE ${countWhere.join(' AND ')}',
          variables: countVariables,
          readsFrom: {_database.libraryTracks},
        )
        .getSingle();
    final items = rows.map(_rowToDomain).toList(growable: false);
    final last = rows.lastOrNull;
    return LibraryPage(
      items: items,
      totalCount: countRow.read<int>('count'),
      nextCursor: items.length < limit || last == null
          ? null
          : LibraryCursor(
              sortValue: _sortValue(last, query.sortField),
              id: last.read<int>('id'),
            ),
    );
  }

  @override
  Future<LibraryGroupPage> queryGroups(LibraryGroupQuery query) async {
    final source =
        query.sourceKey ?? _preferences.getString(_sourcePathKey) ?? '';
    final field = switch (query.kind) {
      LibraryGroupKind.album => 'album',
      LibraryGroupKind.artist => 'artist',
    };
    final valueExpression = "COALESCE(NULLIF(TRIM(t.$field), ''), '')";
    final sortExpression = 'LOWER($valueExpression)';
    final search = _ftsQuery(query.search, column: field);
    final from = search == null
        ? 'library_tracks t'
        : 'library_tracks t JOIN library_tracks_fts f ON f.rowid = t.id';
    final where = <String>['t.source_key = ?'];
    final variables = <Variable<Object>>[Variable.withString(source)];
    if (search != null) {
      where.add('library_tracks_fts MATCH ?');
      variables.add(Variable.withString(search));
    }
    if (query.cursor case final cursor?) {
      where.add(
        '($sortExpression > ? OR '
        '($sortExpression = ? AND $valueExpression > ?))',
      );
      variables
        ..add(Variable.withString(cursor.sortValue))
        ..add(Variable.withString(cursor.sortValue))
        ..add(Variable.withString(cursor.groupValue));
    }
    final limit = query.pageSize.clamp(1, 200);
    variables.add(Variable.withInt(limit));
    final rows = await _database
        .customSelect(
          'SELECT $valueExpression AS group_value, '
          'COUNT(*) AS track_count, '
          'COALESCE(MIN(CASE WHEN t.artwork_id IS NOT NULL OR '
          't.artwork IS NOT NULL THEN t.id END), MIN(t.id)) AS artwork_track_id '
          'FROM $from WHERE ${where.join(' AND ')} '
          'GROUP BY $valueExpression '
          'ORDER BY $sortExpression ASC, $valueExpression ASC LIMIT ?',
          variables: variables,
          readsFrom: {_database.libraryTracks},
        )
        .get();

    final countVariables = <Variable<Object>>[Variable.withString(source)];
    final countWhere = <String>['t.source_key = ?'];
    if (search != null) {
      countWhere.add('library_tracks_fts MATCH ?');
      countVariables.add(Variable.withString(search));
    }
    final countRow = await _database
        .customSelect(
          'SELECT COUNT(*) AS count FROM ('
          'SELECT 1 FROM $from WHERE ${countWhere.join(' AND ')} '
          'GROUP BY $valueExpression)',
          variables: countVariables,
          readsFrom: {_database.libraryTracks},
        )
        .getSingle();
    final items = rows
        .map(
          (row) => LibraryGroup(
            kind: query.kind,
            value: row.read<String>('group_value'),
            trackCount: row.read<int>('track_count'),
            artworkTrackId: row.readNullable<int>('artwork_track_id'),
          ),
        )
        .toList(growable: false);
    final last = items.lastOrNull;
    return LibraryGroupPage(
      items: items,
      totalCount: countRow.read<int>('count'),
      nextCursor: items.length < limit || last == null
          ? null
          : LibraryGroupCursor(
              sortValue: last.value.toLowerCase(),
              groupValue: last.value,
            ),
    );
  }

  @override
  Future<List<domain.LibraryTrack>> resolveTrackPaths(
    Iterable<String> paths,
  ) async {
    final requested = paths.toList(growable: false);
    if (requested.isEmpty) return const [];
    final source = _preferences.getString(_sourcePathKey) ?? '';
    final comparisonPaths = requested
        .map(normalizeLibraryComparisonPath)
        .toList(growable: false);
    final rows = <db.LibraryTrack>[];
    // Keep each IN clause comfortably below SQLite's host-parameter limit.
    for (var start = 0; start < requested.length; start += 400) {
      final end = math.min(start + 400, requested.length);
      rows.addAll(
        await (_database.select(_database.libraryTracks)..where(
              (row) =>
                  row.sourceKey.equals(source) &
                  row.comparisonPath.isIn(comparisonPaths.sublist(start, end)),
            ))
            .get(),
      );
    }
    final byPath = {for (final row in rows) row.comparisonPath: _toDomain(row)};
    return comparisonPaths
        .map((path) => byPath[path])
        .whereType<domain.LibraryTrack>()
        .toList();
  }

  @override
  Future<LibraryPlaybackQueueDescriptor> createPlaybackQueue(
    LibraryQuery query,
  ) async {
    final queueId = DateTime.now().microsecondsSinceEpoch.toString();
    var position = 0;
    LibraryCursor? cursor;
    do {
      final page = await queryTracks(
        LibraryQuery(
          sourceKey: query.sourceKey,
          search: query.search,
          sortField: query.sortField,
          ascending: query.ascending,
          pageSize: 500,
          cursor: cursor,
          album: query.album,
          artist: query.artist,
        ),
      );
      await _database.batch((batch) {
        for (final track in page.items) {
          final trackId = track.cacheId;
          if (trackId == null) continue;
          batch.insert(
            _database.playbackQueueEntries,
            db.PlaybackQueueEntriesCompanion.insert(
              queueId: queueId,
              position: position++,
              trackId: trackId,
            ),
          );
        }
      });
      cursor = page.nextCursor;
    } while (cursor != null);
    return LibraryPlaybackQueueDescriptor(id: queueId, length: position);
  }

  @override
  Future<domain.LibraryTrack?> loadPlaybackQueueTrack(
    String queueId,
    int index,
  ) async {
    final entry =
        await (_database.select(_database.playbackQueueEntries)..where(
              (row) => row.queueId.equals(queueId) & row.position.equals(index),
            ))
            .getSingleOrNull();
    return entry == null ? null : loadTrackById(entry.trackId);
  }

  @override
  Future<void> deletePlaybackQueue(String queueId) async {
    await (_database.delete(
      _database.playbackQueueEntries,
    )..where((row) => row.queueId.equals(queueId))).go();
  }

  @override
  Future<domain.LibraryTrack?> loadTrackById(int id) async {
    final row = await (_database.select(
      _database.libraryTracks,
    )..where((track) => track.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<List<int>?> loadArtwork(int trackId) async {
    final row = await (_database.select(
      _database.libraryTracks,
    )..where((track) => track.id.equals(trackId))).getSingleOrNull();
    if (row == null) return null;
    if (row.artworkId case final artworkId?) {
      final artwork = await (_database.select(
        _database.libraryArtworks,
      )..where((entry) => entry.id.equals(artworkId))).getSingleOrNull();
      return artwork?.bytes;
    }
    return row.artwork;
  }

  @override
  Future<List<domain.LibraryTrack>> scanAndCache(String path) async {
    await directoryAccess.prepareAccess(path);
    final cached = await _cachedTracks(path);
    final tracks = await _scanner.scan(path, cachedTracks: cached);
    return _replaceCache(path, tracks);
  }

  @override
  Future<List<domain.LibraryTrack>> scanFallbackLocal(String path) async {
    await directoryAccess.prepareAccess(path);
    final cached = await _cachedTracks(path);
    final tracks = await _scanner.scan(path, cachedTracks: cached);
    return _replaceCache(path, tracks, persistSource: false);
  }

  @override
  Future<List<domain.LibraryTrack>> scanSmbAndCache(
    SmbSource source,
    String password,
  ) async {
    final sourcePath = 'smb://${source.host}/${source.share}';
    final cached = await _cachedTracks(sourcePath);
    final tracks = await _smbScanner.scan(
      source,
      password,
      cachedTracks: cached,
    );
    return _replaceCache(sourcePath, tracks);
  }

  Future<List<domain.LibraryTrack>> _replaceCache(
    String sourcePath,
    List<domain.LibraryTrack> tracks, {
    bool persistSource = true,
  }) async {
    final generation = DateTime.now().microsecondsSinceEpoch;
    await _database.transaction(() async {
      await _upsertCacheBatch(sourcePath, tracks, generation);
      await _finishCacheGeneration(sourcePath, generation);
    });
    if (persistSource) await saveSourcePath(sourcePath);
    return tracks;
  }

  Future<void> _upsertCacheBatch(
    String sourcePath,
    List<domain.LibraryTrack> tracks,
    int generation,
  ) async {
    for (final track in tracks) {
      final artworkId = track.cacheId == null
          ? await _storeArtwork(track.artwork)
          : null;
      final companion = db.LibraryTracksCompanion.insert(
        sourcePath: track.sourcePath,
        comparisonPath: Value(normalizeLibraryComparisonPath(track.sourcePath)),
        sourceKey: Value(sourcePath),
        title: Value(track.title),
        artist: Value(track.artist),
        album: Value(track.album),
        artworkId: track.cacheId == null
            ? Value(artworkId)
            : const Value.absent(),
        lastSeenAt: Value(track.lastSeenAt),
        fileSize: Value(track.fileSize),
        modifiedAt: Value(track.modifiedAt),
        scanGeneration: Value(generation),
        discNumber: Value(track.discNumber),
        trackNumber: Value(track.trackNumber),
        metadataVersion: Value(track.metadataVersion),
      );
      await _database
          .into(_database.libraryTracks)
          .insert(
            companion,
            onConflict: DoUpdate(
              (_) => companion,
              target: [_database.libraryTracks.sourcePath],
            ),
          );
    }
  }

  Future<void> _finishCacheGeneration(String sourcePath, int generation) async {
    await (_database.delete(_database.libraryTracks)..where(
          (row) =>
              row.sourceKey.equals(sourcePath) &
              row.scanGeneration.isSmallerThanValue(generation),
        ))
        .go();
    await _database.customStatement(
      'DELETE FROM library_artworks WHERE id NOT IN '
      '(SELECT artwork_id FROM library_tracks WHERE artwork_id IS NOT NULL)',
    );
  }

  domain.LibraryTrack _toDomain(db.LibraryTrack row) {
    return domain.LibraryTrack(
      cacheId: row.id,
      sourcePath: row.sourcePath,
      title: row.title,
      artist: row.artist,
      album: row.album,
      artwork: row.artwork,
      lastSeenAt: row.lastSeenAt,
      fileSize: row.fileSize,
      modifiedAt: row.modifiedAt,
      discNumber: row.discNumber,
      trackNumber: row.trackNumber,
      metadataVersion: row.metadataVersion,
    );
  }

  domain.LibraryTrack _rowToDomain(QueryRow row) => domain.LibraryTrack(
    cacheId: row.read<int>('id'),
    sourcePath: row.read<String>('source_path'),
    title: row.readNullable<String>('title'),
    artist: row.readNullable<String>('artist'),
    album: row.readNullable<String>('album'),
    lastSeenAt: _dateTime(row, 'last_seen_at'),
    fileSize: row.readNullable<int>('file_size'),
    modifiedAt: _dateTime(row, 'modified_at'),
    discNumber: row.readNullable<int>('disc_number'),
    trackNumber: row.readNullable<int>('track_number'),
    metadataVersion: row.read<int>('metadata_version'),
  );

  Future<int?> _storeArtwork(Uint8List? bytes) async {
    if (bytes == null || bytes.isEmpty) return null;
    final hash = sha256.convert(bytes).toString();
    await _database
        .into(_database.libraryArtworks)
        .insert(
          db.LibraryArtworksCompanion.insert(contentHash: hash, bytes: bytes),
          mode: InsertMode.insertOrIgnore,
        );
    final row = await (_database.select(
      _database.libraryArtworks,
    )..where((entry) => entry.contentHash.equals(hash))).getSingle();
    return row.id;
  }

  Future<Map<String, domain.LibraryTrack>> _cachedTracks(String source) async {
    await _migrateLegacyArtwork();
    final rows = await (_database.select(
      _database.libraryTracks,
    )..where((row) => row.sourceKey.equals(source))).get();
    return {for (final row in rows) row.sourcePath: _toDomain(row)};
  }

  Future<void> _migrateLegacyArtwork() async {
    while (true) {
      final rows =
          await (_database.select(_database.libraryTracks)
                ..where(
                  (row) => row.artwork.isNotNull() & row.artworkId.isNull(),
                )
                ..limit(50))
              .get();
      if (rows.isEmpty) return;
      await _database.transaction(() async {
        for (final row in rows) {
          final artworkId = await _storeArtwork(row.artwork);
          await (_database.update(
            _database.libraryTracks,
          )..where((track) => track.id.equals(row.id))).write(
            db.LibraryTracksCompanion(
              artwork: const Value(null),
              artworkId: Value(artworkId),
            ),
          );
        }
      });
    }
  }

  void _addGroupFilters(
    LibraryQuery query,
    List<String> where,
    List<Variable<Object>> variables,
  ) {
    for (final filter in [
      (field: 'album', value: query.album),
      (field: 'artist', value: query.artist),
    ]) {
      if (filter.value == null) continue;
      if (filter.value!.isEmpty) {
        where.add("NULLIF(TRIM(t.${filter.field}), '') IS NULL");
      } else {
        where.add("TRIM(t.${filter.field}) = ?");
        variables.add(Variable.withString(filter.value!));
      }
    }
  }

  String? _ftsQuery(String value, {String? column}) {
    final tokens = RegExp(r'[\p{L}\p{N}_]+', unicode: true)
        .allMatches(value.toLowerCase())
        .map((match) => match.group(0))
        .whereType<String>()
        .where((token) => token.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return null;
    final expression = tokens
        .map((token) => '"${token.replaceAll('"', '""')}"*')
        .join(' AND ');
    return column == null ? expression : '$column : ($expression)';
  }

  String _sortValue(QueryRow row, LibrarySortField field) => switch (field) {
    LibrarySortField.title =>
      (row.readNullable<String>('title') ?? row.read<String>('source_path'))
          .toLowerCase(),
    LibrarySortField.artist =>
      (row.readNullable<String>('artist') ?? '').toLowerCase(),
    LibrarySortField.album =>
      (row.readNullable<String>('album') ?? '').toLowerCase(),
    LibrarySortField.sourcePath =>
      row.read<String>('source_path').toLowerCase(),
    LibrarySortField.albumTrack =>
      '${(row.readNullable<int>('disc_number') ?? 2147483647).toString().padLeft(10, '0')}:'
          '${(row.readNullable<int>('track_number') ?? 2147483647).toString().padLeft(10, '0')}:'
          '${row.read<String>('source_path').toLowerCase()}',
  };

  DateTime? _dateTime(QueryRow row, String key) {
    final value = row.data[key];
    return switch (value) {
      int milliseconds => DateTime.fromMillisecondsSinceEpoch(milliseconds),
      String text => DateTime.tryParse(text),
      DateTime date => date,
      _ => null,
    };
  }
}

class _NoopDirectoryAccessService implements LocalDirectoryAccessService {
  const _NoopDirectoryAccessService();

  @override
  Future<void> prepareAccess(String path) async {}

  @override
  Future<void> saveAccess(String path) async {}
}
