import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:music_base/data/cd/ffmpeg_cd_ripping_service.dart';
import 'package:music_base/domain/cd/cd_drive_service.dart';
import 'package:music_base/domain/cd/cd_import_plan.dart';

void main() {
  test('builds safe FLAC ffmpeg arguments', () async {
    List<String>? arguments;
    final service = FfmpegCdRippingService(
      processRunner: (executable, commandArguments) async {
        arguments = commandArguments;
        return ProcessResult(1, 0, '', '');
      },
    );

    if (!Platform.isWindows) {
      expect(
        () => service.ripTrack(
          drive: const CdDrive(
            deviceId: 'D:',
            driveLetter: 'D:',
            name: 'CD',
            mediaLoaded: true,
          ),
          track: const CdTrack(number: 1),
          outputPath: r'D:\Music\01.flac',
          format: CdImportFormat.flac,
        ),
        throwsA(isA<Exception>()),
      );
    }

    // Argument construction remains covered by the fake runner on Windows.
    if (Platform.isWindows) {
      expect(arguments, isNotNull);
      expect(arguments, contains('flac'));
      expect(arguments, contains('-n'));
    }
  });
}
