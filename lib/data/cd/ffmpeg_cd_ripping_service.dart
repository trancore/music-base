import 'dart:io';

import '../../domain/cd/cd_drive_service.dart';
import '../../domain/cd/cd_import_plan.dart';
import '../../domain/cd/cd_ripping_service.dart';

typedef FfmpegProcessRunner =
    Future<ProcessResult> Function(String executable, List<String> arguments);

class FfmpegCdRippingService implements CdRippingService {
  FfmpegCdRippingService({
    FfmpegProcessRunner? processRunner,
    this.executable = 'ffmpeg.exe',
  }) : _processRunner = processRunner ?? Process.run;

  final FfmpegProcessRunner _processRunner;
  final String executable;

  @override
  Future<void> ripTrack({
    required CdDrive drive,
    required CdTrack track,
    required String outputPath,
    required CdImportFormat format,
  }) async {
    if (!Platform.isWindows) {
      throw const CdRippingException(
        'CD ripping is only available on Windows.',
      );
    }
    final driveLetter = drive.driveLetter.trim();
    if (!RegExp(r'^[A-Za-z]:$').hasMatch(driveLetter)) {
      throw const CdRippingException('Invalid CD drive letter.');
    }
    if (track.number < 1 || outputPath.trim().isEmpty) {
      throw const CdRippingException(
        'Track number and output path are required.',
      );
    }
    if (File(outputPath).existsSync()) {
      throw CdRippingException('Refusing to overwrite: $outputPath');
    }

    final codecArguments = switch (format) {
      CdImportFormat.flac => ['-c:a', 'flac'],
      CdImportFormat.mp3 => ['-c:a', 'libmp3lame', '-q:a', '2'],
    };
    final result = await _processRunner(executable, [
      '-hide_banner',
      '-loglevel',
      'error',
      '-n',
      '-f',
      'libcdio',
      '-i',
      driveLetter,
      '-map',
      '0:a:${track.number - 1}',
      ...codecArguments,
      outputPath,
    ]);
    if (result.exitCode != 0) {
      throw CdRippingException(
        'ffmpeg failed for track ${track.number}: ${result.stderr}',
      );
    }
  }
}
