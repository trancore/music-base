import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/library/library_repository.dart';
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
  });

  static const _sourcePathKey = 'library.source_path';

  final SharedPreferences _preferences;
  final db.AppDatabase _database;
  final LibraryScanner _scanner;
  final SmbLibraryScanner _smbScanner;

  @override
  Future<String?> loadSourcePath() async =>
      _preferences.getString(_sourcePathKey);

  @override
  Future<void> saveSourcePath(String path) async {
    await _preferences.setString(_sourcePathKey, path);
  }

  @override
  Future<List<domain.LibraryTrack>> loadTracks() async {
    final rows = await _database.select(_database.libraryTracks).get();
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<List<domain.LibraryTrack>> scanAndCache(String path) async {
    final tracks = await _scanner.scan(path);
    return _replaceCache(path, tracks);
  }

  @override
  Future<List<domain.LibraryTrack>> scanSmbAndCache(
    SmbSource source,
    String password,
  ) async {
    final tracks = await _smbScanner.scan(source, password);
    return _replaceCache('smb://${source.host}/${source.share}', tracks);
  }

  Future<List<domain.LibraryTrack>> _replaceCache(
    String sourcePath,
    List<domain.LibraryTrack> tracks,
  ) async {
    await _database.transaction(() async {
      await _database.delete(_database.libraryTracks).go();
      for (final track in tracks) {
        await _database
            .into(_database.libraryTracks)
            .insert(
              db.LibraryTracksCompanion.insert(
                sourcePath: track.sourcePath,
                title: Value(track.title),
                artist: Value(track.artist),
                album: Value(track.album),
                lastSeenAt: Value(track.lastSeenAt),
              ),
            );
      }
    });
    await saveSourcePath(sourcePath);
    return tracks;
  }

  domain.LibraryTrack _toDomain(db.LibraryTrack row) {
    return domain.LibraryTrack(
      sourcePath: row.sourcePath,
      title: row.title,
      artist: row.artist,
      album: row.album,
      lastSeenAt: row.lastSeenAt,
    );
  }
}
