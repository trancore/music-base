import 'dart:typed_data';

import 'package:path/path.dart' as p;

class LibraryMetadata {
  const LibraryMetadata({
    required this.title,
    this.artist,
    this.album,
    this.artwork,
  });

  final String title;
  final String? artist;
  final String? album;
  final Uint8List? artwork;
}

LibraryMetadata inferLibraryMetadata(String sourcePath, {String? libraryRoot}) {
  final pathSegments = _pathSegments(sourcePath, libraryRoot: libraryRoot);
  final fileName = pathSegments.isEmpty
      ? p.basename(sourcePath)
      : pathSegments.last;
  final title = _trackTitle(p.basenameWithoutExtension(fileName));

  String? album;
  String? artist;
  if (pathSegments.length >= 2) {
    album = _nonEmpty(pathSegments[pathSegments.length - 2]);
  }
  if (pathSegments.length >= 3) {
    artist = _nonEmpty(pathSegments[pathSegments.length - 3]);
  }

  return LibraryMetadata(title: title, artist: artist, album: album);
}

List<String> _pathSegments(String sourcePath, {String? libraryRoot}) {
  if (sourcePath.startsWith('smb://')) {
    final uri = Uri.tryParse(sourcePath);
    if (uri != null) return uri.pathSegments;
  }
  if (libraryRoot != null) {
    final relativePath = p.relative(sourcePath, from: libraryRoot);
    return p.split(relativePath);
  }
  return p.split(sourcePath.replaceAll('\\', p.separator));
}

String _trackTitle(String fileName) {
  final match = RegExp(
    r'^\s*\d{1,3}\s*[-._ ]\s*(.+?)\s*$',
  ).firstMatch(fileName);
  return match?.group(1) ?? fileName;
}

String? _nonEmpty(String value) => value.trim().isEmpty ? null : value.trim();
