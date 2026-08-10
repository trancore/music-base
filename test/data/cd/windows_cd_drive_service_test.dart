import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:music_base/data/cd/windows_cd_drive_service.dart';

void main() {
  test('parses a Windows CD drive query response', () async {
    final service = WindowsCdDriveService(
      processRunner: (executable, arguments) async => ProcessResult(
        1,
        0,
        jsonEncode({
          'DeviceID': 'D:',
          'Drive': 'D:',
          'Name': 'Test CD Drive',
          'MediaLoaded': true,
        }),
        '',
      ),
    );

    final drives = service.parseJson(
      jsonEncode({
        'DeviceID': 'D:',
        'Drive': 'D:',
        'Name': 'Test CD Drive',
        'MediaLoaded': true,
      }),
    );
    expect(drives.single.driveLetter, 'D:');
    expect(drives.single.mediaLoaded, isTrue);

    // The service is guarded on non-Windows hosts; verify the guard is safe.
    if (!Platform.isWindows) {
      expect(() => service.listDrives(), throwsA(isA<Exception>()));
    }
  });
}
