import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:music_base/data/cd/windows_cd_track_service.dart';
import 'package:music_base/domain/cd/cd_drive_service.dart';
import 'package:music_base/domain/cd/cd_track_service.dart';

void main() {
  final service = WindowsCdTrackService(
    processRunner: (executable, arguments) async =>
        ProcessResult(1, 0, jsonEncode(const []), ''),
  );

  test('parses framed MCI track JSON while ignoring other output', () {
    final tracks = service.parseJson(
      'PowerShell diagnostic output\r\n'
      'MUSIC_BASE_TRACKS_JSON:'
      '[{"number":1,"length":"01:02:37:00"},'
      '{"number":2,"length":"01:00:00:37"}]\r\n'
      'Additional output',
    );

    expect(tracks, hasLength(2));
    expect(tracks.first.number, 1);
    expect(tracks.first.duration, const Duration(minutes: 2, seconds: 37));
    expect(tracks[1].duration, const Duration(milliseconds: 493));
  });

  test('parses empty, single-track, and multi-track arrays', () {
    const prefix = 'MUSIC_BASE_TRACKS_JSON:';

    expect(service.parseJson('$prefix[]'), isEmpty);
    expect(
      service.parseJson('$prefix[{"number":1,"length":"03:04:05"}]'),
      hasLength(1),
    );
    expect(
      service.parseJson(
        '$prefix[{"number":1,"length":"03:04:05"},'
        '{"number":2,"length":"06:07:08"}]',
      ),
      hasLength(2),
    );
  });

  test('rejects missing, duplicate, and malformed framed responses', () {
    final invalidResponse = isA<CdTrackException>().having(
      (error) => error.message,
      'message',
      contains('invalid response'),
    );

    expect(() => service.parseJson('[]'), throwsA(invalidResponse));
    expect(
      () => service.parseJson(
        'MUSIC_BASE_TRACKS_JSON:[]\nMUSIC_BASE_TRACKS_JSON:[]',
      ),
      throwsA(invalidResponse),
    );
    expect(
      () => service.parseJson('MUSIC_BASE_TRACKS_JSON:not-json'),
      throwsA(invalidResponse),
    );
  });

  test('rejects CD track reading outside Windows', () async {
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
