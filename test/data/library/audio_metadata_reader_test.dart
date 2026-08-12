import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:music_base/data/library/audio_metadata_reader.dart';
import 'package:music_base/domain/library/library_metadata.dart';

void main() {
  test(
    'falls back to inferred metadata when a file has no readable tags',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'music-base-tags-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = await File(
        '${directory.path}/01 - Song.flac',
      ).writeAsString('');
      const fallback = LibraryMetadata(
        title: 'Song',
        artist: 'Artist',
        album: 'Album',
      );

      final metadata = const PackageAudioMetadataReader().read(file, fallback);

      expect(metadata.title, 'Song');
      expect(metadata.artist, 'Artist');
      expect(metadata.album, 'Album');
    },
  );
}
