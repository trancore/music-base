import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/library/dart_smb2_service.dart';
import '../data/library/smb_settings_repository.dart';
import '../domain/library/smb_service.dart';
import '../domain/library/smb_source.dart';
import 'providers.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    mOptions: MacOsOptions(usesDataProtectionKeychain: false),
  );
});

final smbSettingsRepositoryProvider = Provider<SmbSettingsRepository>((ref) {
  return SharedPreferencesSmbSettingsRepository(
    preferences: ref.watch(sharedPreferencesProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});

final smbServiceProvider = Provider<SmbService>(
  (ref) => const DartSmb2Service(),
);

final smbSourceProvider = AsyncNotifierProvider<SmbSourceNotifier, SmbSource?>(
  SmbSourceNotifier.new,
);

class SmbSourceNotifier extends AsyncNotifier<SmbSource?> {
  late final SmbSettingsRepository _repository;

  @override
  Future<SmbSource?> build() {
    _repository = ref.watch(smbSettingsRepositoryProvider);
    return _repository.loadSource();
  }

  Future<void> save(SmbSource source, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.save(source, password);
      return source;
    });
  }

  Future<void> clear() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.clear();
      return null;
    });
  }
}
