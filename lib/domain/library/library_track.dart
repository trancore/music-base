import 'dart:typed_data';

class LibraryTrack {
  const LibraryTrack({
    required this.sourcePath,
    this.title,
    this.artist,
    this.album,
    this.artwork,
    this.lastSeenAt,
  });

  final String sourcePath;
  final String? title;
  final String? artist;
  final String? album;
  final Uint8List? artwork;
  final DateTime? lastSeenAt;

  bool get isRemote => sourcePath.startsWith('smb://');
}
