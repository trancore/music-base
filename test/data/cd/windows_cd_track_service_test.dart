import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:music_base/data/cd/windows_cd_track_service.dart';
import 'package:music_base/domain/cd/cd_drive_service.dart';

void main() {
  test('parses MCI track lengths from PowerShell JSON', () async {
    final service = WindowsCdTrackService(
      processRunner: (executable, arguments) async => ProcessResult(
        1,
        0,
        jsonEncode([
          {'number': 1, 'length': '01:02:37:00'},
          {'number': 2, 'length': '01:00:00:37'},
        ]),
        '',
      ),
    );

    final tracks = service.parseJson(
      '[{"number":1,"length":"01:02:37:00"},'
      '{"number":2,"length":"01:00:00:37"}]',
    );

    expect(tracks, hasLength(2));
    expect(tracks.first.number, 1);
    expect(tracks.first.duration, const Duration(minutes: 2, seconds: 37));
    expect(tracks[1].duration, const Duration(milliseconds: 493));
    if (!Platform.isWindows) {
      expect(
        () => service.readTracks(
          const CdDrive(
            deviceId: 'D:',
            driveLetter: 'D:',
            name: 'CD',
            mediaLoaded: true,
          ),
        ),
        throwsA(isA<Exception>()),
      );
    }
  });
}
