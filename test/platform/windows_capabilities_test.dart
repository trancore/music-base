import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:music_base/platform/windows/windows_capabilities.dart';

void main() {
  test('reports CD ripping only on Windows', () {
    final capabilities = const DefaultWindowsCapabilities();

    expect(
      capabilities.supportsCdRipping,
      defaultTargetPlatform == TargetPlatform.windows,
    );
  });
}
