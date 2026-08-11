import 'package:flutter_test/flutter_test.dart';

import 'package:music_base/domain/library/library_path.dart';

void main() {
  test('accepts the library itself and paths below it', () {
    expect(isPathWithinLibrary('/Music', '/Music'), isTrue);
    expect(isPathWithinLibrary('/Music', '/Music/Artist/Album'), isTrue);
  });

  test('rejects sibling paths with a shared prefix', () {
    expect(isPathWithinLibrary('/Music', '/Music-old/Album'), isFalse);
  });
}
