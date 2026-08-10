import 'package:flutter_test/flutter_test.dart';

import 'package:music_base/data/library/dart_smb2_service.dart';
import 'package:music_base/domain/library/smb_service.dart';
import 'package:music_base/domain/library/smb_source.dart';

void main() {
  test('rejects an incomplete SMB source before connecting', () async {
    expect(
      () => const DartSmb2Service().testConnection(
        const SmbSource(host: '', share: '', username: ''),
        '',
      ),
      throwsA(isA<SmbConnectionException>()),
    );
  });
}
