import 'package:flutter/services.dart';

import '../../domain/library/local_directory_access_service.dart';

class MacosLocalDirectoryAccessService implements LocalDirectoryAccessService {
  MacosLocalDirectoryAccessService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('music_base/macos_file_access');

  final MethodChannel _channel;

  @override
  Future<void> prepareAccess(String path) async {
    await _channel.invokeMethod<void>('prepareAccess', {'path': path});
  }

  @override
  Future<void> saveAccess(String path) async {
    await _channel.invokeMethod<void>('saveAccess', {'path': path});
  }
}
