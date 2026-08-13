import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_base/data/library/smb_flac_metadata_reader.dart';
import 'package:music_base/domain/library/library_metadata.dart';

void main() {
  test('reads FLAC comments and embedded artwork using ranges', () async {
    final image = Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]);
    final file = _flac([
      (
        type: 4,
        data: _comments(const [
          'TITLE=sample track',
          'ARTIST=sample performer',
          'ALBUM=sample collection',
          'DISCNUMBER=2/3',
          'TRACKNUMBER=7/12',
        ]),
      ),
      (type: 6, data: _picture(image)),
    ]);
    final requests = <({int offset, int length})>[];

    final metadata = await const SmbFlacMetadataReader().read((
      offset,
      length,
    ) async {
      requests.add((offset: offset, length: length));
      return Uint8List.fromList(file.sublist(offset, offset + length));
    }, const LibraryMetadata(title: 'fallback'));

    expect(metadata.title, 'sample track');
    expect(metadata.artist, 'sample performer');
    expect(metadata.album, 'sample collection');
    expect(metadata.discNumber, 2);
    expect(metadata.trackNumber, 7);
    expect(metadata.artwork, image);
    expect(metadata.parsedSuccessfully, isTrue);
    expect(
      requests.map((request) => request.length).reduce((a, b) => a + b),
      lessThan(file.length + 20),
    );
  });

  test('uses folder artwork when the FLAC has no picture block', () async {
    final folderArtwork = Uint8List.fromList([1, 2, 3]);
    final file = _flac([(type: 4, data: _comments(const []))]);

    final metadata = await const SmbFlacMetadataReader().read(
      (offset, length) async =>
          Uint8List.fromList(file.sublist(offset, offset + length)),
      const LibraryMetadata(title: 'fallback'),
      folderArtwork: folderArtwork,
    );

    expect(metadata.artwork, folderArtwork);
  });
}

Uint8List _flac(List<({int type, Uint8List data})> blocks) {
  final result = BytesBuilder()..add(ascii.encode('fLaC'));
  for (var index = 0; index < blocks.length; index++) {
    final block = blocks[index];
    final length = block.data.length;
    result
      ..add([
        block.type | (index == blocks.length - 1 ? 0x80 : 0),
        length >> 16,
        length >> 8,
        length,
      ])
      ..add(block.data);
  }
  return result.toBytes();
}

Uint8List _comments(List<String> comments) {
  final result = BytesBuilder();
  _addUint32(result, 0, Endian.little);
  _addUint32(result, comments.length, Endian.little);
  for (final comment in comments) {
    final bytes = utf8.encode(comment);
    _addUint32(result, bytes.length, Endian.little);
    result.add(bytes);
  }
  return result.toBytes();
}

Uint8List _picture(Uint8List image) {
  final result = BytesBuilder();
  _addUint32(result, 3, Endian.big);
  final mime = ascii.encode('image/jpeg');
  _addUint32(result, mime.length, Endian.big);
  result.add(mime);
  _addUint32(result, 0, Endian.big);
  for (final value in [600, 600, 24, 0, image.length]) {
    _addUint32(result, value, Endian.big);
  }
  result.add(image);
  return result.toBytes();
}

void _addUint32(BytesBuilder builder, int value, Endian endian) {
  final bytes = Uint8List(4);
  ByteData.sublistView(bytes).setUint32(0, value, endian);
  builder.add(bytes);
}
