import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:music_base/data/library/local_directory_library_scanner.dart';

void main() {
  test(
    'finds FLAC and MP3 files recursively and ignores other files',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'music_base_scanner_test_',
      );
      addTearDown(() => root.delete(recursive: true));

      await Directory('${root.path}/album').create();
      await File('${root.path}/album/01 - Intro.flac').writeAsString('');
      await File('${root.path}/album/02 - Song.MP3').writeAsString('');
      await File('${root.path}/album/cover.jpg').writeAsString('');

      final tracks = await const LocalDirectoryLibraryScanner().scan(root.path);

      expect(tracks, hasLength(2));
      expect(tracks.map((track) => track.title), ['01 - Intro', '02 - Song']);
    },
  );

  test('reports an unavailable directory', () async {
    final missing = '${Directory.systemTemp.path}/music_base_missing';

    expect(
      () => const LocalDirectoryLibraryScanner().scan(missing),
      throwsA(isA<Exception>()),
    );
  });
}
