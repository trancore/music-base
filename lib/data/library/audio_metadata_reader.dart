import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';

import '../../domain/library/library_metadata.dart';

class PackageAudioMetadataReader {
  const PackageAudioMetadataReader();

  static const maxArtworkBytes = 2 * 1024 * 1024;

  LibraryMetadata read(File file, LibraryMetadata fallback) {
    try {
      final metadata = readMetadata(file, getImage: true);
      final artwork = metadata.pictures
          .where((picture) => picture.bytes.length <= maxArtworkBytes)
          .map((picture) => picture.bytes)
          .firstOrNull;
      return LibraryMetadata(
        title: _value(metadata.title) ?? fallback.title,
        artist: _value(metadata.artist) ?? fallback.artist,
        album: _value(metadata.album) ?? fallback.album,
        artwork: artwork ?? fallback.artwork,
      );
    } on Object {
      return fallback;
    }
  }
}

String? _value(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
