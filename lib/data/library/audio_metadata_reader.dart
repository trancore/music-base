import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';

import '../../domain/library/library_metadata.dart';

class PackageAudioMetadataReader {
  const PackageAudioMetadataReader();

  LibraryMetadata read(File file, LibraryMetadata fallback) {
    try {
      final metadata = readMetadata(file, getImage: false);
      return LibraryMetadata(
        title: _value(metadata.title) ?? fallback.title,
        artist: _value(metadata.artist) ?? fallback.artist,
        album: _value(metadata.album) ?? fallback.album,
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
