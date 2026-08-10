import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/library/local_directory_library_scanner.dart';
import '../data/library/shared_preferences_library_repository.dart';
import '../data/library/smb_library_scanner.dart';
import '../domain/library/library_repository.dart';
import '../domain/library/library_track.dart';
import 'providers.dart';
import 'smb_providers.dart';

final libraryScannerProvider = Provider(
  (ref) => const LocalDirectoryLibraryScanner(),
);

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return SharedPreferencesLibraryRepository(
    preferences: ref.watch(sharedPreferencesProvider),
    database: ref.watch(appDatabaseProvider),
    scanner: ref.watch(libraryScannerProvider),
    smbScanner: ref.watch(smbLibraryScannerProvider),
  );
});

final smbLibraryScannerProvider = Provider((ref) => const SmbLibraryScanner());

final libraryProvider =
    AsyncNotifierProvider<LibraryNotifier, List<LibraryTrack>>(
      LibraryNotifier.new,
    );

class LibraryNotifier extends AsyncNotifier<List<LibraryTrack>> {
  late final LibraryRepository _repository;

  String? sourcePath;

  @override
  Future<List<LibraryTrack>> build() async {
    _repository = ref.watch(libraryRepositoryProvider);
    sourcePath = await _repository.loadSourcePath();
    return _repository.loadTracks();
  }

  Future<void> chooseDirectory() async {
    // The UI supplies the platform picker result through scanDirectory.
  }

  Future<void> scanDirectory(String path) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      sourcePath = path;
      return _repository.scanAndCache(path);
    });
  }

  Future<void> scanSmb() async {
    final source = await ref.read(smbSourceProvider.future);
    if (source == null) return;
    final password =
        await ref.read(smbSettingsRepositoryProvider).loadPassword() ?? '';
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      sourcePath = 'smb://${source.host}/${source.share}';
      return _repository.scanSmbAndCache(source, password);
    });
  }
}
