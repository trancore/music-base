import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../domain/library/library_path_normalizer.dart';

part 'app_database.g.dart';

class LibraryArtworks extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get contentHash => text().unique()();

  BlobColumn get bytes => blob()();
}

class LibraryTracks extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get sourcePath => text().unique()();

  TextColumn get comparisonPath => text().withDefault(const Constant(''))();

  TextColumn get sourceKey => text().withDefault(const Constant(''))();

  TextColumn get title => text().nullable()();

  TextColumn get artist => text().nullable()();

  TextColumn get album => text().nullable()();

  BlobColumn get artwork => blob().nullable()();

  IntColumn get artworkId =>
      integer().nullable().references(LibraryArtworks, #id)();

  DateTimeColumn get lastSeenAt => dateTime().nullable()();

  IntColumn get fileSize => integer().nullable()();

  DateTimeColumn get modifiedAt => dateTime().nullable()();

  IntColumn get scanGeneration => integer().withDefault(const Constant(0))();

  IntColumn get discNumber => integer().nullable()();

  IntColumn get trackNumber => integer().nullable()();

  IntColumn get metadataVersion => integer().withDefault(const Constant(0))();
}

class PlaybackQueueEntries extends Table {
  TextColumn get queueId => text()();

  IntColumn get position => integer()();

  IntColumn get trackId => integer().references(LibraryTracks, #id)();

  @override
  Set<Column<Object>> get primaryKey => {queueId, position};
}

@DriftDatabase(tables: [LibraryTracks, LibraryArtworks, PlaybackQueueEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'music_base'));

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) => m.createAll(),
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(libraryTracks, libraryTracks.artwork);
      }
      if (from < 3) {
        await m.createTable(libraryArtworks);
        await m.addColumn(libraryTracks, libraryTracks.sourceKey);
        await m.addColumn(libraryTracks, libraryTracks.artworkId);
        await m.addColumn(libraryTracks, libraryTracks.fileSize);
        await m.addColumn(libraryTracks, libraryTracks.modifiedAt);
        await m.addColumn(libraryTracks, libraryTracks.scanGeneration);
      }
      if (from < 4) {
        await m.createTable(playbackQueueEntries);
      }
      if (from < 5) {
        await m.addColumn(libraryTracks, libraryTracks.discNumber);
        await m.addColumn(libraryTracks, libraryTracks.trackNumber);
        await m.addColumn(libraryTracks, libraryTracks.metadataVersion);
      }
      if (from < 6) {
        final columns = await customSelect(
          'PRAGMA table_info(library_tracks)',
        ).get();
        final hasComparisonPath = columns.any(
          (row) => row.read<String>('name') == 'comparison_path',
        );
        if (!hasComparisonPath) {
          await m.addColumn(libraryTracks, libraryTracks.comparisonPath);
        }
      }
      if (from < 7) {
        final rows = await customSelect(
          'SELECT id, source_path FROM library_tracks',
          readsFrom: {libraryTracks},
        ).get();
        for (final row in rows) {
          await customUpdate(
            'UPDATE library_tracks SET comparison_path = ? WHERE id = ?',
            variables: [
              Variable.withString(
                normalizeLibraryComparisonPath(row.read<String>('source_path')),
              ),
              Variable.withInt(row.read<int>('id')),
            ],
            updates: {libraryTracks},
          );
        }
      }
    },
    beforeOpen: (details) async {
      await delete(playbackQueueEntries).go();
      await customStatement(
        'CREATE INDEX IF NOT EXISTS library_tracks_source_comparison_path '
        'ON library_tracks(source_key, comparison_path)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS library_tracks_source_title '
        'ON library_tracks(source_key, title, id)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS library_tracks_source_artist '
        'ON library_tracks(source_key, artist, id)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS library_tracks_source_album '
        'ON library_tracks(source_key, album, id)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS library_tracks_album_order '
        'ON library_tracks(source_key, album, disc_number, track_number, id)',
      );
      await customStatement(
        'CREATE VIRTUAL TABLE IF NOT EXISTS library_tracks_fts USING fts5('
        'title, artist, album, source_path, content=library_tracks, content_rowid=id, '
        "tokenize='unicode61 remove_diacritics 2')",
      );
      await customStatement('''
        CREATE TRIGGER IF NOT EXISTS library_tracks_ai AFTER INSERT ON library_tracks BEGIN
          INSERT INTO library_tracks_fts(rowid,title,artist,album,source_path)
          VALUES(new.id,new.title,new.artist,new.album,new.source_path);
        END
      ''');
      await customStatement('''
        CREATE TRIGGER IF NOT EXISTS library_tracks_ad AFTER DELETE ON library_tracks BEGIN
          INSERT INTO library_tracks_fts(library_tracks_fts,rowid,title,artist,album,source_path)
          VALUES('delete',old.id,old.title,old.artist,old.album,old.source_path);
        END
      ''');
      await customStatement('''
        CREATE TRIGGER IF NOT EXISTS library_tracks_au AFTER UPDATE ON library_tracks BEGIN
          INSERT INTO library_tracks_fts(library_tracks_fts,rowid,title,artist,album,source_path)
          VALUES('delete',old.id,old.title,old.artist,old.album,old.source_path);
          INSERT INTO library_tracks_fts(rowid,title,artist,album,source_path)
          VALUES(new.id,new.title,new.artist,new.album,new.source_path);
        END
      ''');
      if (details.wasCreated || details.hadUpgrade) {
        await customStatement(
          "INSERT INTO library_tracks_fts(library_tracks_fts) VALUES('rebuild')",
        );
      }
    },
  );
}
