import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:music_base/app/smb_providers.dart';
import 'package:music_base/data/library/smb_settings_repository.dart';
import 'package:music_base/domain/library/smb_source.dart';

void main() {
  test('clears the saved SMB source and password', () async {
    final repository = _FakeSmbSettingsRepository();
    final container = ProviderContainer(
      overrides: [smbSettingsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(smbSourceProvider.future);
    await container.read(smbSourceProvider.notifier).clear();

    expect(repository.clearCalls, 1);
    expect(container.read(smbSourceProvider).value, isNull);
  });
}

class _FakeSmbSettingsRepository implements SmbSettingsRepository {
  var clearCalls = 0;

  @override
  Future<SmbSource?> loadSource() async =>
      const SmbSource(host: 'server', share: 'share', username: 'user');

  @override
  Future<String?> loadPassword() async => 'password';

  @override
  Future<void> save(SmbSource source, String password) async {}

  @override
  Future<void> clear() async {
    clearCalls++;
  }
}
