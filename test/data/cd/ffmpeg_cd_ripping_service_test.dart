import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:music_base/data/cd/ffmpeg_cd_ripping_service.dart';
import 'package:music_base/domain/cd/cd_drive_service.dart';
import 'package:music_base/domain/cd/cd_import_plan.dart';
import 'package:music_base/domain/cd/cd_ripping_service.dart';

void main() {
  test('builds safe FLAC ffmpeg arguments', () async {
    List<String>? arguments;
    final service = FfmpegCdRippingService(
      processRunner: (executable, commandArguments) async {
        arguments = commandArguments;
        return ProcessResult(1, 0, '', '');
      },
      isWindows: true,
    );

    await service.ripTrack(
      drive: const CdDrive(
        deviceId: 'D:',
        driveLetter: 'D:',
        name: 'CD',
        mediaLoaded: true,
      ),
      track: const CdTrack(number: 1),
      outputPath: r'D:\Music\01.flac',
      format: CdImportFormat.flac,
      title: 'Song',
      artist: 'Artist',
      album: 'Album',
      releaseDate: '2020',
    );

    expect(arguments, isNotNull);
    expect(arguments, containsAll(['flac', '-n', '-metadata', 'title=Song']));
    expect(arguments, contains('artist=Artist'));
    expect(arguments, contains('album=Album'));
    expect(arguments, contains('date=2020'));
  });

  test('rejects a request cancelled before ffmpeg starts', () async {
    final token = CdRippingCancellationToken()..cancel();
    var started = false;
    final service = FfmpegCdRippingService(
      isWindows: true,
      processRunner: (executable, arguments) async {
        started = true;
        return ProcessResult(1, 0, '', '');
      },
    );

    await expectLater(
      service.ripTrack(
        drive: const CdDrive(
          deviceId: 'D:',
          driveLetter: 'D:',
          name: 'CD',
          mediaLoaded: true,
        ),
        track: const CdTrack(number: 1),
        outputPath: r'D:\Music\01.flac',
        format: CdImportFormat.flac,
        cancellationToken: token,
      ),
      throwsA(isA<CdRippingException>()),
    );
    expect(started, isFalse);
  });
}
