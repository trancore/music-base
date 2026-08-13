import 'package:flutter_test/flutter_test.dart';
import 'package:music_base/domain/library/library_path_normalizer.dart';

void main() {
  test('normalizes Windows separators, dot segments, and case', () {
    expect(
      normalizeLibraryComparisonPath(r'X:\SampleLibrary\Album\..\Track.FLAC'),
      'x:/samplelibrary/track.flac',
    );
  });

  test('preserves POSIX and SMB path case', () {
    expect(
      normalizeLibraryComparisonPath('/Volumes/Music/Track.FLAC'),
      '/Volumes/Music/Track.FLAC',
    );
    expect(
      normalizeLibraryComparisonPath('smb://server/share/Track.FLAC'),
      'smb://server/share/Track.FLAC',
    );
  });

  test('matches encoded and decoded SMB paths', () {
    const decoded =
        'smb://server/share/Audio/音楽/コレクション/'
        'Example Label/Sample Artist/Étude.flac';
    const encoded =
        'smb://server/share/Audio/%E9%9F%B3%E6%A5%BD/%E3%82%B3%E3%83%AC%E3%82%AF%E3%82%B7%E3%83%A7%E3%83%B3/'
        'Example%20Label/Sample%20Artist/%C3%89tude.flac';

    expect(
      normalizeLibraryComparisonPath(encoded),
      normalizeLibraryComparisonPath(decoded),
    );
  });

  test('joins SMB roots without collapsing the URI scheme', () {
    expect(
      joinLibraryPath(
        'smb://server/share',
        'Audio/サンプル/Collection/Prélude.flac',
      ),
      'smb://server/share/Audio/%E3%82%B5%E3%83%B3%E3%83%97%E3%83%AB/'
      'Collection/Pr%C3%A9lude.flac',
    );
  });
}
