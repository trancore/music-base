import 'package:flutter_test/flutter_test.dart';
import 'package:music_base/domain/library/smb_source.dart';

void main() {
  test('normalizes SMB subfolder paths', () {
    expect(
      SmbSource.normalizeSubfolder(r'\Music\ミュージック\sources'),
      'Music/ミュージック/sources',
    );
    expect(
      SmbSource.normalizeSubfolder('/Music/ミュージック/sources/'),
      'Music/ミュージック/sources',
    );
  });

  test('builds display path with subfolder', () {
    const source = SmbSource(
      host: 'nas.local',
      share: 'media',
      subfolder: r'Music\ミュージック\sources',
      username: 'user',
    );

    expect(source.librarySourceKey, 'smb://nas.local/media');
    expect(source.displayPath, 'smb://nas.local/media/Music/ミュージック/sources');
  });
}
