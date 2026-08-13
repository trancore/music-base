import 'package:flutter_test/flutter_test.dart';
import 'package:music_base/data/library/cached_library_track.dart';
import 'package:music_base/domain/library/library_track.dart';

void main() {
  test('refreshes scan time while preserving cached metadata', () {
    final modifiedAt = DateTime.utc(2026, 1, 2);
    final lastSeenAt = DateTime.utc(2026, 2, 3);
    final cached = LibraryTrack(
      cacheId: 42,
      sourcePath: r'C:\Music\Artist\Album\01 Song.flac',
      title: 'Song',
      artist: 'Artist',
      album: 'Album',
      lastSeenAt: DateTime.utc(2025),
      fileSize: 1024,
      modifiedAt: modifiedAt,
      discNumber: 1,
      trackNumber: 1,
      metadataVersion: 1,
    );

    final refreshed = refreshCachedTrack(cached, lastSeenAt: lastSeenAt);

    expect(refreshed.cacheId, cached.cacheId);
    expect(refreshed.sourcePath, cached.sourcePath);
    expect(refreshed.title, cached.title);
    expect(refreshed.artist, cached.artist);
    expect(refreshed.album, cached.album);
    expect(refreshed.lastSeenAt, lastSeenAt);
    expect(refreshed.fileSize, cached.fileSize);
    expect(refreshed.modifiedAt, modifiedAt);
    expect(refreshed.discNumber, cached.discNumber);
    expect(refreshed.trackNumber, cached.trackNumber);
    expect(refreshed.metadataVersion, cached.metadataVersion);
    expect(refreshed.artwork, isNull);
  });
}
