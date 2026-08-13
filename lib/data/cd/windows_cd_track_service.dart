import 'dart:convert';
import 'dart:io';

import '../../domain/cd/cd_drive_service.dart';
import '../../domain/cd/cd_import_plan.dart';
import '../../domain/cd/cd_track_service.dart';

typedef CdProcessRunner =
    Future<ProcessResult> Function(String executable, List<String> arguments);

class WindowsCdTrackService implements CdTrackService {
  WindowsCdTrackService({CdProcessRunner? processRunner})
    : _processRunner = processRunner ?? Process.run;

  static const _outputPrefix = 'MUSIC_BASE_TRACKS_JSON:';

  final CdProcessRunner _processRunner;

  @override
  Future<List<CdTrack>> readTracks(CdDrive drive) async {
    if (!Platform.isWindows) {
      throw const CdTrackException(
        'CD track reading is only available on Windows.',
      );
    }
    final driveLetter = drive.driveLetter.trim();
    if (!RegExp(r'^[A-Za-z]:$').hasMatch(driveLetter)) {
      throw const CdTrackException('Invalid CD drive letter.');
    }
    final result = await _processRunner('powershell.exe', [
      '-NoProfile',
      '-NonInteractive',
      '-Command',
      _scriptFor(driveLetter),
    ]);
    if (result.exitCode != 0) {
      throw CdTrackException('Unable to read CD tracks: ${result.stderr}');
    }
    return parseJson(result.stdout.toString());
  }

  List<CdTrack> parseJson(String output) {
    final payloads = output
        .split(RegExp(r'\r?\n'))
        .where((line) => line.startsWith(_outputPrefix))
        .map((line) => line.substring(_outputPrefix.length).trim())
        .toList(growable: false);
    if (payloads.length != 1 || payloads.single.isEmpty) {
      throw const CdTrackException(
        'Unable to read CD tracks because Windows returned an invalid response.',
      );
    }

    try {
      final decoded = jsonDecode(payloads.single);
      if (decoded is! List) {
        throw const FormatException('Expected a JSON array.');
      }
      return decoded
          .whereType<Map>()
          .map(_parseTrack)
          .whereType<CdTrack>()
          .toList(growable: false);
    } on FormatException {
      throw const CdTrackException(
        'Unable to read CD tracks because Windows returned an invalid response.',
      );
    }
  }

  CdTrack? _parseTrack(Map entry) {
    final number = entry['number'];
    if (number is! num || number < 1) return null;
    final rawLength = entry['length'];
    return CdTrack(
      number: number.toInt(),
      duration: rawLength is String ? _parseTmsf(rawLength) : null,
    );
  }

  Duration? _parseTmsf(String value) {
    final parts = value.split(':').map(int.tryParse).toList();
    if (parts.length < 3 || parts.any((part) => part == null)) return null;
    final seconds = parts[parts.length - 3]! * 60 + parts[parts.length - 2]!;
    final frames = parts.last!;
    return Duration(milliseconds: seconds * 1000 + frames * 1000 ~/ 75);
  }

  String _scriptFor(String driveLetter) =>
      r'''
$ErrorActionPreference = 'Stop'
Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class MusicBaseMci {
  [DllImport("winmm.dll", CharSet = CharSet.Unicode)]
  public static extern int mciSendString(string command, StringBuilder result, int length, IntPtr callback);
}
"@
function Invoke-Mci([string]$command) {
  $result = New-Object System.Text.StringBuilder 256
  $error = [MusicBaseMci]::mciSendString($command, $result, $result.Capacity, [IntPtr]::Zero)
  if ($error -ne 0) { throw "MCI command failed: $command ($error)" }
  return $result.ToString()
}
try {
  Invoke-Mci "open DRIVE type cdaudio alias musicbase_cd" | Out-Null
  Invoke-Mci "set musicbase_cd time format tmsf" | Out-Null
  $count = [int](Invoke-Mci "status musicbase_cd number of tracks")
  $tracks = @()
  for ($index = 1; $index -le $count; $index++) {
    $tracks += [pscustomobject]@{
      number = $index
      length = (Invoke-Mci "status musicbase_cd length track $index")
    }
  }
  $json = ConvertTo-Json -InputObject @($tracks) -Compress
  [Console]::Out.WriteLine('OUTPUT_PREFIX' + $json)
} finally {
  try { Invoke-Mci "close musicbase_cd" | Out-Null } catch {}
}
'''
          .replaceAll('DRIVE', driveLetter)
          .replaceAll('OUTPUT_PREFIX', _outputPrefix);
}
