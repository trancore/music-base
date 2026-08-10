import 'dart:convert';
import 'dart:io';

import '../../domain/cd/cd_drive_service.dart';

typedef ProcessRunner =
    Future<ProcessResult> Function(String executable, List<String> arguments);

class WindowsCdDriveService implements CdDriveService {
  WindowsCdDriveService({ProcessRunner? processRunner})
    : _processRunner = processRunner ?? Process.run;

  final ProcessRunner _processRunner;

  @override
  Future<List<CdDrive>> listDrives() async {
    if (!Platform.isWindows) {
      throw const CdDriveException(
        'CD drive detection is only available on Windows.',
      );
    }
    final result = await _processRunner('powershell.exe', [
      '-NoProfile',
      '-NonInteractive',
      '-Command',
      'Get-CimInstance Win32_CDROMDrive | '
          'Select-Object DeviceID,Drive,Name,MediaLoaded | '
          'ConvertTo-Json -Compress',
    ]);
    if (result.exitCode != 0) {
      throw CdDriveException(
        'Unable to query Windows CD drives: ${result.stderr}',
      );
    }
    final output = result.stdout.toString().trim();
    if (output.isEmpty) return const [];
    return parseJson(output);
  }

  List<CdDrive> parseJson(String output) {
    final decoded = jsonDecode(output);
    final entries = decoded is List ? decoded : [decoded];
    return entries
        .whereType<Map>()
        .map(_parseDrive)
        .whereType<CdDrive>()
        .toList(growable: false);
  }

  CdDrive? _parseDrive(Map entry) {
    final deviceId = entry['DeviceID'];
    final drive = entry['Drive'];
    final name = entry['Name'];
    if (deviceId is! String || drive is! String || name is! String) {
      return null;
    }
    final mediaLoaded = entry['MediaLoaded'];
    return CdDrive(
      deviceId: deviceId,
      driveLetter: drive,
      name: name,
      mediaLoaded: mediaLoaded == true || mediaLoaded == 'True',
    );
  }
}
