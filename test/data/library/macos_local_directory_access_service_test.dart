import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_base/data/library/macos_local_directory_access_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('forwards directory access lifecycle calls to macOS', () async {
    const channel = MethodChannel('music_base/macos_file_access');
    final calls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    final service = MacosLocalDirectoryAccessService(channel: channel);
    await service.prepareAccess('/Music');
    await service.saveAccess('/Music');

    expect(calls.map((call) => call.method), ['prepareAccess', 'saveAccess']);
    expect(calls.map((call) => (call.arguments as Map)['path']), [
      '/Music',
      '/Music',
    ]);
  });
}
