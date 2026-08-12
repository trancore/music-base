import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/library/smb_source.dart';

abstract interface class SmbSettingsRepository {
  Future<SmbSource?> loadSource();

  Future<String?> loadPassword();

  Future<void> save(SmbSource source, String password);

  Future<void> clear();
}

class SharedPreferencesSmbSettingsRepository implements SmbSettingsRepository {
  const SharedPreferencesSmbSettingsRepository({
    required this.preferences,
    required this.secureStorage,
  });

  final SharedPreferences preferences;
  final FlutterSecureStorage secureStorage;

  static const _hostKey = 'smb.host';
  static const _shareKey = 'smb.share';
  static const _subfolderKey = 'smb.subfolder';
  static const _usernameKey = 'smb.username';
  static const _passwordKey = 'smb.password';

  @override
  Future<SmbSource?> loadSource() async {
    final host = preferences.getString(_hostKey);
    final share = preferences.getString(_shareKey);
    final username = preferences.getString(_usernameKey);
    if (host == null || share == null || username == null) return null;
    return SmbSource(
      host: host,
      share: share,
      subfolder: preferences.getString(_subfolderKey) ?? '',
      username: username,
    );
  }

  @override
  Future<String?> loadPassword() => secureStorage.read(key: _passwordKey);

  @override
  Future<void> save(SmbSource source, String password) async {
    await preferences.setString(_hostKey, source.host);
    await preferences.setString(_shareKey, source.share);
    await preferences.setString(_subfolderKey, source.subfolder);
    await preferences.setString(_usernameKey, source.username);
    await secureStorage.write(key: _passwordKey, value: password);
  }

  @override
  Future<void> clear() async {
    await preferences.remove(_hostKey);
    await preferences.remove(_shareKey);
    await preferences.remove(_subfolderKey);
    await preferences.remove(_usernameKey);
    await secureStorage.delete(key: _passwordKey);
  }
}
