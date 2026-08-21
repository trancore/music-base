import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Keep [kAppVersion] in sync with the `version` field in `pubspec.yaml`.
const kAppVersion = '1.2.0';
const kAppName = 'music_base';

class AppVersionInfo {
  const AppVersionInfo({
    required this.appName,
    required this.version,
    required this.buildNumber,
  });

  final String appName;
  final String version;
  final String buildNumber;

  String get label {
    if (buildNumber.isEmpty || buildNumber == '0') return version;
    return '$version ($buildNumber)';
  }
}

const _currentVersion = AppVersionInfo(
  appName: kAppName,
  version: kAppVersion,
  buildNumber: '',
);

final appVersionInfoProvider = Provider<AppVersionInfo>(
  (ref) => _currentVersion,
);
