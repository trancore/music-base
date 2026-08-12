import 'dart:io';

import 'package:path/path.dart' as p;

import 'audio_metadata_reader.dart';
import '../../domain/library/library_errors.dart';
import '../../domain/library/library_metadata.dart';
import '../../domain/library/library_scanner.dart';
import '../../domain/library/library_track.dart';

class LocalDirectoryLibraryScanner implements LibraryScanner {
  const LocalDirectoryLibraryScanner({
    this._metadataReader = const PackageAudioMetadataReader(),
  });

  final PackageAudioMetadataReader _metadataReader;

  static const supportedExtensions = {'.flac', '.mp3'};

  @override
  Future<List<LibraryTrack>> scan(String rootPath) async {
    final directory = Directory(rootPath);
    if (!await directory.exists()) {
      throw LibraryAccessException('The selected directory is not available.');
    }

    try {
      final tracks = <LibraryTrack>[];
      await for (final entity in directory.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File ||
            !supportedExtensions.contains(
              p.extension(entity.path).toLowerCase(),
            )) {
          continue;
        }

        final inferredMetadata = inferLibraryMetadata(
          entity.path,
          libraryRoot: rootPath,
        );
        final metadata = _metadataReader.read(entity, inferredMetadata);
        tracks.add(
          LibraryTrack(
            sourcePath: entity.path,
            title: metadata.title,
            artist: metadata.artist,
            album: metadata.album,
            lastSeenAt: DateTime.now(),
          ),
        );
      }
      tracks.sort(
        (a, b) =>
            a.sourcePath.toLowerCase().compareTo(b.sourcePath.toLowerCase()),
      );
      return tracks;
    } on FileSystemException catch (error) {
      throw LibraryAccessException(
        'Unable to scan the selected directory: ${error.message}',
      );
    }
  }
}
