import 'dart:typed_data';

import 'package:dart_smb2/dart_smb2.dart';
import 'package:path/path.dart' as p;

import '../../domain/library/library_errors.dart';
import '../../domain/library/library_metadata.dart';
import '../../domain/library/library_track.dart';
import '../../domain/library/smb_source.dart';
import 'cached_library_track.dart';
import 'smb_flac_metadata_reader.dart';

class SmbLibraryScanner {
  const SmbLibraryScanner({
    this.flacMetadataReader = const SmbFlacMetadataReader(),
  });

  final SmbFlacMetadataReader flacMetadataReader;

  static const supportedExtensions = {'.flac', '.mp3'};

  Future<List<LibraryTrack>> scan(
    SmbSource source,
    String password, {
    Map<String, LibraryTrack> cachedTracks = const {},
  }) async {
    Smb2Pool? pool;
    try {
      pool = await Smb2Pool.connect(
        host: source.host,
        share: source.share,
        user: source.username,
        password: password,
        workers: 1,
        timeoutSeconds: 30,
      );
      final tracks = <LibraryTrack>[];
      await _scanDirectory(
        pool,
        _normalize(source.subfolder),
        source,
        tracks,
        cachedTracks,
      );
      tracks.sort(
        (a, b) =>
            a.sourcePath.toLowerCase().compareTo(b.sourcePath.toLowerCase()),
      );
      return tracks;
    } on Smb2Exception catch (error) {
      throw LibraryAccessException('SMB scan failed: ${error.message}');
    } on Exception catch (error) {
      throw LibraryAccessException('SMB scan failed: $error');
    } finally {
      await pool?.disconnect();
    }
  }

  Future<void> _scanDirectory(
    Smb2Pool pool,
    String directory,
    SmbSource source,
    List<LibraryTrack> tracks,
    Map<String, LibraryTrack> cachedTracks,
  ) async {
    final entries = await pool.listDirectory(directory);
    final artwork = await _readFolderArtwork(pool, directory, entries);
    for (final entry in entries) {
      final remotePath = _join(directory, entry.name);
      if (entry.isDirectory) {
        await _scanDirectory(pool, remotePath, source, tracks, cachedTracks);
      } else if (entry.isFile &&
          supportedExtensions.contains(p.extension(entry.name).toLowerCase())) {
        final sourcePath = Uri(
          scheme: 'smb',
          host: source.host,
          pathSegments: [source.share, ...remotePath.split('/')],
        ).toString();
        final metadata = inferLibraryMetadata(sourcePath);
        final cached = cachedTracks[sourcePath];
        if (cached != null &&
            cached.fileSize == entry.size &&
            cached.modifiedAt == entry.stat.modified &&
            cached.metadataVersion >= 1) {
          _record(
            tracks,
            refreshCachedTrack(cached, lastSeenAt: DateTime.now()),
          );
          continue;
        }
        final resolvedMetadata =
            p.extension(entry.name).toLowerCase() == '.flac'
            ? await flacMetadataReader.read(
                (offset, length) => pool.readFileRange(
                  remotePath,
                  offset: offset,
                  length: length,
                ),
                metadata,
                folderArtwork: artwork,
              )
            : metadata;
        _record(
          tracks,
          LibraryTrack(
            sourcePath: sourcePath,
            title: resolvedMetadata.title,
            artist: resolvedMetadata.artist,
            album: resolvedMetadata.album,
            artwork: resolvedMetadata.artwork ?? artwork,
            lastSeenAt: DateTime.now(),
            fileSize: entry.size,
            modifiedAt: entry.stat.modified,
            discNumber: resolvedMetadata.discNumber,
            trackNumber: resolvedMetadata.trackNumber,
            metadataVersion: resolvedMetadata.parsedSuccessfully ? 1 : 0,
          ),
        );
      }
    }
  }

  void _record(List<LibraryTrack> tracks, LibraryTrack track) {
    tracks.add(track);
  }

  String _normalize(String path) =>
      path.replaceAll('\\', '/').replaceAll(RegExp(r'^/+|/+$'), '');

  String _join(String directory, String name) =>
      directory.isEmpty ? name : '$directory/$name';

  Future<Uint8List?> _readFolderArtwork(
    Smb2Pool pool,
    String directory,
    List<Smb2DirEntry> entries,
  ) async {
    const names = {'cover.jpg', 'cover.jpeg', 'cover.png', 'folder.jpg'};
    for (final entry in entries) {
      if (!entry.isFile || !names.contains(entry.name.toLowerCase())) continue;
      if (entry.size <= 0 || entry.size > 2 * 1024 * 1024) continue;
      try {
        return await pool.readFileRange(
          _join(directory, entry.name),
          length: entry.size,
        );
      } on Object {
        // Artwork is optional; a broken cover must not hide the music files.
      }
    }
    return null;
  }
}
