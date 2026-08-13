import 'dart:convert';
import 'dart:typed_data';

import '../../domain/library/library_metadata.dart';

typedef SmbRangeReader = Future<Uint8List> Function(int offset, int length);

class SmbFlacMetadataReader {
  const SmbFlacMetadataReader();

  static const maxArtworkBytes = 2 * 1024 * 1024;
  static const _maxCommentBlockBytes = 1024 * 1024;
  static const _maxPictureOverheadBytes = 64 * 1024;

  Future<LibraryMetadata> read(
    SmbRangeReader readRange,
    LibraryMetadata fallback, {
    Uint8List? folderArtwork,
  }) async {
    var title = fallback.title;
    var artist = fallback.artist;
    var album = fallback.album;
    var discNumber = fallback.discNumber;
    var trackNumber = fallback.trackNumber;
    var parsedSuccessfully = false;
    Uint8List? embeddedArtwork;
    try {
      final signature = await readRange(0, 4);
      if (signature.length != 4 || ascii.decode(signature) != 'fLaC') {
        return _result(fallback, folderArtwork: folderArtwork);
      }
      var offset = 4;
      for (var blockIndex = 0; blockIndex < 128; blockIndex++) {
        final header = await readRange(offset, 4);
        if (header.length != 4) break;
        final isLast = header[0] & 0x80 != 0;
        final type = header[0] & 0x7f;
        final length = (header[1] << 16) | (header[2] << 8) | header[3];
        offset += 4;
        if (type == 4 && length <= _maxCommentBlockBytes) {
          final comments = _vorbisComments(await readRange(offset, length));
          title = _value(comments['TITLE']) ?? title;
          artist = _value(comments['ARTIST']) ?? artist;
          album = _value(comments['ALBUM']) ?? album;
          discNumber =
              _number(comments['DISCNUMBER'] ?? comments['DISC']) ?? discNumber;
          trackNumber = _number(comments['TRACKNUMBER']) ?? trackNumber;
        } else if (type == 6 &&
            embeddedArtwork == null &&
            length <= maxArtworkBytes + _maxPictureOverheadBytes) {
          embeddedArtwork = _picture(await readRange(offset, length));
        }
        offset += length;
        if (isLast) break;
      }
      parsedSuccessfully = true;
    } on Object {
      // Metadata is optional. Keep path-derived values and folder artwork.
    }
    return LibraryMetadata(
      title: title,
      artist: artist,
      album: album,
      artwork: embeddedArtwork ?? folderArtwork ?? fallback.artwork,
      discNumber: discNumber,
      trackNumber: trackNumber,
      parsedSuccessfully: parsedSuccessfully,
    );
  }

  LibraryMetadata _result(
    LibraryMetadata fallback, {
    Uint8List? folderArtwork,
  }) => LibraryMetadata(
    title: fallback.title,
    artist: fallback.artist,
    album: fallback.album,
    artwork: folderArtwork ?? fallback.artwork,
    discNumber: fallback.discNumber,
    trackNumber: fallback.trackNumber,
    parsedSuccessfully: false,
  );

  Map<String, String> _vorbisComments(Uint8List bytes) {
    final result = <String, String>{};
    final data = ByteData.sublistView(bytes);
    var offset = 0;
    int readUint32() {
      if (offset + 4 > bytes.length) throw const FormatException();
      final value = data.getUint32(offset, Endian.little);
      offset += 4;
      return value;
    }

    void skip(int length) {
      if (length < 0 || offset + length > bytes.length) {
        throw const FormatException();
      }
      offset += length;
    }

    skip(readUint32()); // Vendor string.
    final count = readUint32().clamp(0, 10000);
    for (var index = 0; index < count; index++) {
      final length = readUint32();
      if (length < 0 || offset + length > bytes.length) {
        throw const FormatException();
      }
      final comment = utf8.decode(
        bytes.sublist(offset, offset + length),
        allowMalformed: true,
      );
      offset += length;
      final separator = comment.indexOf('=');
      if (separator <= 0) continue;
      result.putIfAbsent(
        comment.substring(0, separator).toUpperCase(),
        () => comment.substring(separator + 1),
      );
    }
    return result;
  }

  Uint8List? _picture(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    var offset = 0;
    int readUint32() {
      if (offset + 4 > bytes.length) throw const FormatException();
      final value = data.getUint32(offset, Endian.big);
      offset += 4;
      return value;
    }

    void skip(int length) {
      if (length < 0 || offset + length > bytes.length) {
        throw const FormatException();
      }
      offset += length;
    }

    readUint32(); // Picture type.
    skip(readUint32()); // MIME type.
    skip(readUint32()); // Description.
    skip(16); // Width, height, depth, and indexed color count.
    final imageLength = readUint32();
    if (imageLength <= 0 ||
        imageLength > maxArtworkBytes ||
        offset + imageLength > bytes.length) {
      return null;
    }
    return Uint8List.fromList(bytes.sublist(offset, offset + imageLength));
  }
}

String? _value(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

int? _number(String? value) =>
    int.tryParse(value?.split('/').first.trim() ?? '');
