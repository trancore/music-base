import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/library/local_directory_access_service.dart';
import '../database/app_database.dart';

/// Persists the selected library source and restores platform access to it.
class LibrarySourceStore {
  const LibrarySourceStore({
    required this.preferences,
    required this.database,
    required this.directoryAccess,
  });

  static const _sourcePathKey = 'library.source_path';
  static const _lastLocalSourcePathKey = 'library.last_local_source_path';

  final SharedPreferences preferences;
  final AppDatabase database;
  final LocalDirectoryAccessService directoryAccess;

  String? get currentSourcePath => preferences.getString(_sourcePathKey);

  Future<String?> loadSourcePath() async {
    final path = currentSourcePath;
    if (path != null && !path.startsWith('smb://')) {
      await directoryAccess.prepareAccess(path);
    }
    if (path != null) {
      await database.customUpdate(
        'UPDATE library_tracks SET source_key = ? WHERE source_key = ?',
        variables: [Variable.withString(path), Variable.withString('')],
        updates: {database.libraryTracks},
      );
    }
    return path;
  }

  String? loadLastLocalSourcePath() =>
      preferences.getString(_lastLocalSourcePathKey);

  Future<void> saveSourcePath(String path) async {
    await preferences.setString(_sourcePathKey, path);
    if (!path.startsWith('smb://')) {
      await preferences.setString(_lastLocalSourcePathKey, path);
      await directoryAccess.saveAccess(path);
    }
  }
}
