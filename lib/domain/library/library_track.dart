class LibraryTrack {
  const LibraryTrack({
    required this.sourcePath,
    this.title,
    this.artist,
    this.album,
    this.lastSeenAt,
  });

  final String sourcePath;
  final String? title;
  final String? artist;
  final String? album;
  final DateTime? lastSeenAt;

  bool get isRemote => sourcePath.startsWith('smb://');
}
