import 'dart:typed_data';

class LibraryTrack {
  const LibraryTrack({
    required this.sourcePath,
    this.cacheId,
    this.title,
    this.artist,
    this.album,
    this.artwork,
    this.lastSeenAt,
    this.fileSize,
    this.modifiedAt,
    this.discNumber,
    this.trackNumber,
    this.metadataVersion = 0,
  });

  final int? cacheId;
  final String sourcePath;
  final String? title;
  final String? artist;
  final String? album;
  final Uint8List? artwork;
  final DateTime? lastSeenAt;
  final int? fileSize;
  final DateTime? modifiedAt;
  final int? discNumber;
  final int? trackNumber;
  final int metadataVersion;

  bool get isRemote => sourcePath.startsWith('smb://');
}
