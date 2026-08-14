import 'package:flutter_test/flutter_test.dart';

import 'package:music_base/data/playback/smb_playback_cache.dart';
import 'package:music_base/domain/library/library_track.dart';

void main() {
  group('SmbPlaybackCache', () {
    const cache = SmbPlaybackCache();

    test('cacheKeyFor is stable for the same track metadata', () {
      const track = LibraryTrack(
        sourcePath: 'smb://server/share/Album/song.flac',
        fileSize: 42_000_000,
      );

      expect(cache.cacheKeyFor(track), cache.cacheKeyFor(track));
    });

    test('cacheKeyFor changes when file size or modified time changes', () {
      const baseTrack = LibraryTrack(
        sourcePath: 'smb://server/share/Album/song.flac',
        fileSize: 42_000_000,
        modifiedAt: null,
      );
      const resizedTrack = LibraryTrack(
        sourcePath: 'smb://server/share/Album/song.flac',
        fileSize: 43_000_000,
        modifiedAt: null,
      );
      const updatedTrack = LibraryTrack(
        sourcePath: 'smb://server/share/Album/song.flac',
        fileSize: 42_000_000,
        modifiedAt: null,
      );

      expect(
        cache.cacheKeyFor(baseTrack),
        isNot(cache.cacheKeyFor(resizedTrack)),
      );
      expect(
        cache.cacheKeyFor(baseTrack),
        isNot(
          cache.cacheKeyFor(
            updatedTrack.copyWith(modifiedAt: DateTime.utc(2026, 1, 2)),
          ),
        ),
      );
    });
  });
}

extension on LibraryTrack {
  LibraryTrack copyWith({
    String? sourcePath,
    int? fileSize,
    DateTime? modifiedAt,
  }) {
    return LibraryTrack(
      sourcePath: sourcePath ?? this.sourcePath,
      fileSize: fileSize ?? this.fileSize,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }
}
