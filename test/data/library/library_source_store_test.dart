import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_base/data/database/app_database.dart';
import 'package:music_base/data/library/library_source_store.dart';
import 'package:music_base/domain/library/local_directory_access_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase database;
  late SharedPreferences preferences;
  late _RecordingDirectoryAccess directoryAccess;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    database = AppDatabase.forTesting(NativeDatabase.memory());
    directoryAccess = _RecordingDirectoryAccess();
  });

  tearDown(() => database.close());

  test('saves a local source and persists platform access', () async {
    final store = LibrarySourceStore(
      preferences: preferences,
      database: database,
      directoryAccess: directoryAccess,
    );

    await store.saveSourcePath('/music');

    expect(store.currentSourcePath, '/music');
    expect(store.loadLastLocalSourcePath(), '/music');
    expect(directoryAccess.savedPaths, ['/music']);
  });

  test('saves an SMB source without replacing the local fallback', () async {
    await preferences.setString('library.last_local_source_path', '/music');
    final store = LibrarySourceStore(
      preferences: preferences,
      database: database,
      directoryAccess: directoryAccess,
    );

    await store.saveSourcePath('smb://server/share');

    expect(store.currentSourcePath, 'smb://server/share');
    expect(store.loadLastLocalSourcePath(), '/music');
    expect(directoryAccess.savedPaths, isEmpty);
  });
}

class _RecordingDirectoryAccess implements LocalDirectoryAccessService {
  final savedPaths = <String>[];

  @override
  Future<void> prepareAccess(String path) async {}

  @override
  Future<void> saveAccess(String path) async => savedPaths.add(path);
}
