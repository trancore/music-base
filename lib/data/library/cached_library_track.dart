import '../../domain/library/library_track.dart';

/// Reuses parsed metadata while marking a cache entry as present in this scan.
LibraryTrack refreshCachedTrack(
  LibraryTrack cached, {
  required DateTime lastSeenAt,
}) => LibraryTrack(
  cacheId: cached.cacheId,
  sourcePath: cached.sourcePath,
  title: cached.title,
  artist: cached.artist,
  album: cached.album,
  lastSeenAt: lastSeenAt,
  fileSize: cached.fileSize,
  modifiedAt: cached.modifiedAt,
  discNumber: cached.discNumber,
  trackNumber: cached.trackNumber,
  metadataVersion: cached.metadataVersion,
);
