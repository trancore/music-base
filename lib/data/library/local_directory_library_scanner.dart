import 'dart:io';
import 'dart:isolate';

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
  Future<List<LibraryTrack>> scan(
    String rootPath, {
    Map<String, LibraryTrack> cachedTracks = const {},
  }) => Isolate.run(() => _scanOnWorker(rootPath, cachedTracks));

  List<LibraryTrack> _scanOnWorker(
    String rootPath,
    Map<String, LibraryTrack> cachedTracks,
  ) {
    final directory = Directory(rootPath);
    if (!directory.existsSync()) {
      throw LibraryAccessException('The selected directory is not available.');
    }

    try {
      final tracks = <LibraryTrack>[];
      for (final entity in directory.listSync(
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
        final stat = entity.statSync();
        final cached = cachedTracks[entity.path];
        if (cached != null &&
            cached.fileSize == stat.size &&
            cached.modifiedAt == stat.modified &&
            cached.metadataVersion >= 1) {
          tracks.add(
            LibraryTrack(
              cacheId: cached.cacheId,
              sourcePath: cached.sourcePath,
              title: cached.title,
              artist: cached.artist,
              album: cached.album,
              lastSeenAt: DateTime.now(),
              fileSize: cached.fileSize,
              modifiedAt: cached.modifiedAt,
              discNumber: cached.discNumber,
              trackNumber: cached.trackNumber,
              metadataVersion: cached.metadataVersion,
            ),
          );
          continue;
        }
        final metadata = _metadataReader.read(entity, inferredMetadata);
        tracks.add(
          LibraryTrack(
            sourcePath: entity.path,
            title: metadata.title,
            artist: metadata.artist,
            album: metadata.album,
            artwork: metadata.artwork,
            lastSeenAt: DateTime.now(),
            fileSize: stat.size,
            modifiedAt: stat.modified,
            discNumber: metadata.discNumber,
            trackNumber: metadata.trackNumber,
            metadataVersion: metadata.parsedSuccessfully ? 1 : 0,
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
