import 'dart:io';
import 'dart:convert';

import '../../domain/cd/cd_drive_service.dart';
import '../../domain/cd/cd_import_plan.dart';
import '../../domain/cd/cd_ripping_service.dart';

typedef FfmpegProcessRunner =
    Future<ProcessResult> Function(String executable, List<String> arguments);
typedef FfmpegProcessStarter =
    Future<Process> Function(String executable, List<String> arguments);

class FfmpegCdRippingService implements CdRippingService {
  FfmpegCdRippingService({
    FfmpegProcessRunner? processRunner,
    FfmpegProcessStarter? processStarter,
    this.executable = 'ffmpeg.exe',
  }) : _processStarter = processStarter ?? Process.start {
    _processRunner = processRunner;
  }

  late final FfmpegProcessRunner? _processRunner;
  final FfmpegProcessStarter _processStarter;
  final String executable;

  @override
  Future<void> ripTrack({
    required CdDrive drive,
    required CdTrack track,
    required String outputPath,
    required CdImportFormat format,
    String? title,
    String? artist,
    String? album,
    String? releaseDate,
    CdRippingCancellationToken? cancellationToken,
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
    if (cancellationToken?.isCancelled ?? false) {
      throw const CdRippingException('Ripping cancelled.');
    }

    final codecArguments = switch (format) {
      CdImportFormat.flac => ['-c:a', 'flac'],
      CdImportFormat.mp3 => ['-c:a', 'libmp3lame', '-q:a', '2'],
    };
    final metadataArguments = <String>[];
    for (final metadata in {
      'title': title,
      'artist': artist,
      'album': album,
      'date': releaseDate,
    }.entries) {
      if (metadata.value case final value? when value.trim().isNotEmpty) {
        metadataArguments.addAll(['-metadata', '${metadata.key}=$value']);
      }
    }
    final arguments = [
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
      ...metadataArguments,
      outputPath,
    ];
    final runner = _processRunner;
    final result = runner != null
        ? await runner(executable, arguments)
        : await _runCancellableProcess(
            executable,
            arguments,
            cancellationToken,
          );
    if (result.exitCode != 0) {
      throw CdRippingException(
        'ffmpeg failed for track ${track.number}: ${result.stderr}',
      );
    }
  }

  Future<ProcessResult> _runCancellableProcess(
    String executable,
    List<String> arguments,
    CdRippingCancellationToken? cancellationToken,
  ) async {
    final process = await _processStarter(executable, arguments);
    final stdoutFuture = process.stdout.transform(utf8.decoder).join();
    final stderrFuture = process.stderr.transform(utf8.decoder).join();
    final exitCodeFuture = process.exitCode;
    int? exitCode;
    while (exitCode == null) {
      if (cancellationToken?.isCancelled ?? false) {
        process.kill();
        await exitCodeFuture;
        await Future.wait([stdoutFuture, stderrFuture]);
        throw const CdRippingException('Ripping cancelled.');
      }
      final completed = await Future.any<Object?>([
        exitCodeFuture,
        Future<Object?>.delayed(const Duration(milliseconds: 50)),
      ]);
      if (completed is int) exitCode = completed;
    }
    return ProcessResult(
      process.pid,
      exitCode,
      await stdoutFuture,
      await stderrFuture,
    );
  }
}
