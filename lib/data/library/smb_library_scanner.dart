import 'package:dart_smb2/dart_smb2.dart';
import 'package:path/path.dart' as p;

import '../../domain/library/library_errors.dart';
import '../../domain/library/library_track.dart';
import '../../domain/library/smb_source.dart';

class SmbLibraryScanner {
  const SmbLibraryScanner();

  static const supportedExtensions = {'.flac', '.mp3'};

  Future<List<LibraryTrack>> scan(SmbSource source, String password) async {
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
      await _scanDirectory(pool, _normalize(source.subfolder), source, tracks);
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
  ) async {
    final entries = await pool.listDirectory(directory);
    for (final entry in entries) {
      final remotePath = _join(directory, entry.name);
      if (entry.isDirectory) {
        await _scanDirectory(pool, remotePath, source, tracks);
      } else if (entry.isFile &&
          supportedExtensions.contains(p.extension(entry.name).toLowerCase())) {
        tracks.add(
          LibraryTrack(
            sourcePath: Uri(
              scheme: 'smb',
              host: source.host,
              pathSegments: [source.share, ...remotePath.split('/')],
            ).toString(),
            title: p.basenameWithoutExtension(entry.name),
            lastSeenAt: entry.stat.modified,
          ),
        );
      }
    }
  }

  String _normalize(String path) =>
      path.replaceAll('\\', '/').replaceAll(RegExp(r'^/+|/+$'), '');

  String _join(String directory, String name) =>
      directory.isEmpty ? name : '$directory/$name';
}
