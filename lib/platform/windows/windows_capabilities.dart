import 'package:flutter/foundation.dart';

abstract interface class WindowsCapabilities {
  bool get supportsCdRipping;
}

class DefaultWindowsCapabilities implements WindowsCapabilities {
  const DefaultWindowsCapabilities();

  @override
  bool get supportsCdRipping => defaultTargetPlatform == TargetPlatform.windows;
}
