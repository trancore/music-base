import 'package:path/path.dart' as p;

import '../metadata/musicbrainz_release.dart';

enum CdImportFormat {
  flac('.flac'),
  mp3('.mp3');

  const CdImportFormat(this.extension);

  final String extension;
}

class CdTrack {
  const CdTrack({required this.number, this.duration});

  final int number;
  final Duration? duration;
}

class CdImportTrack {
  const CdImportTrack({
    required this.sourceTrackNumber,
    required this.title,
    required this.targetPath,
    required this.discNumber,
    this.artist,
    this.album,
    this.releaseDate,
  });

  final int sourceTrackNumber;
  final String title;
  final String targetPath;
  final int discNumber;
  final String? artist;
  final String? album;
  final String? releaseDate;
}

class CdImportPlan {
  const CdImportPlan({
    required this.format,
    required this.outputDirectory,
    required this.tracks,
  });

  final CdImportFormat format;
  final String outputDirectory;
  final List<CdImportTrack> tracks;
}

class CdImportPlanningException implements Exception {
  const CdImportPlanningException(this.message);

  final String message;

  @override
  String toString() => 'CdImportPlanningException: $message';
}

class CdImportPlanner {
  const CdImportPlanner();

  CdImportPlan create({
    required MusicBrainzRelease release,
    required List<CdTrack> cdTracks,
    required String outputDirectory,
    required CdImportFormat format,
    int? cdTrackCount,
    Set<String> existingPaths = const {},
  }) {
    final releaseTrackCount = release.media.fold<int>(
      0,
      (count, medium) => count + medium.tracks.length,
    );
    if (cdTrackCount != null && cdTrackCount != releaseTrackCount) {
      throw CdImportPlanningException(
        'The CD has $cdTrackCount tracks, but the release has '
        '$releaseTrackCount metadata tracks.',
      );
    }
    final metadataTracks = release.media
        .expand((medium) => medium.tracks)
        .where((track) => track.title.isNotEmpty)
        .toList(growable: false);
    if (metadataTracks.isEmpty) {
      throw const CdImportPlanningException(
        'The release does not contain any metadata tracks.',
      );
    }
    if (cdTracks.any(
      (track) => track.number < 1 || track.number > metadataTracks.length,
    )) {
      throw CdImportPlanningException(
        'The release has ${metadataTracks.length} metadata tracks, but a '
        'selected CD track is outside that range.',
      );
    }
    if (outputDirectory.trim().isEmpty) {
      throw const CdImportPlanningException('An output directory is required.');
    }

    final artist = _safeSegment(release.artist ?? 'Unknown Artist');
    final album = _safeSegment(release.title);
    final tracks = <CdImportTrack>[];
    for (final cdTrack in cdTracks) {
      final metadataIndex = cdTrack.number - 1;
      final metadataTrack = metadataTracks[metadataIndex];
      final discNumber = _discNumber(release, metadataIndex);
      final fileName =
          '${cdTrack.number.toString().padLeft(2, '0')} - '
          '${_safeSegment(metadataTrack.title)}${format.extension}';
      final targetPath = p.join(outputDirectory, artist, album, fileName);
      if (existingPaths.contains(targetPath)) {
        throw CdImportPlanningException('Refusing to overwrite: $targetPath');
      }
      tracks.add(
        CdImportTrack(
          sourceTrackNumber: cdTrack.number,
          title: metadataTrack.title,
          targetPath: targetPath,
          discNumber: discNumber,
          artist: release.artist,
          album: release.title,
          releaseDate: release.releaseDate,
        ),
      );
    }
    return CdImportPlan(
      format: format,
      outputDirectory: outputDirectory,
      tracks: List.unmodifiable(tracks),
    );
  }

  int _discNumber(MusicBrainzRelease release, int trackIndex) {
    var offset = 0;
    for (final medium in release.media) {
      if (trackIndex < offset + medium.tracks.length) return medium.position;
      offset += medium.tracks.length;
    }
    return 1;
  }

  String _safeSegment(String value) {
    final sanitized = value
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .replaceAll(RegExp(r'[. ]+$'), '');
    return sanitized.isEmpty ? 'Unknown' : sanitized;
  }
}
