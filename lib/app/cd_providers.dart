import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cd/windows_cd_drive_service.dart';
import '../data/cd/windows_cd_track_service.dart';
import '../data/cd/ffmpeg_cd_ripping_service.dart';
import '../domain/cd/cd_drive_service.dart';
import '../domain/cd/cd_track_service.dart';
import '../domain/cd/cd_ripping_service.dart';
import '../platform/windows/windows_capabilities.dart';

final windowsCapabilitiesProvider = Provider<WindowsCapabilities>(
  (ref) => const DefaultWindowsCapabilities(),
);

final cdDriveServiceProvider = Provider<CdDriveService>((ref) {
  return WindowsCdDriveService();
});

final cdTrackServiceProvider = Provider<CdTrackService>((ref) {
  return WindowsCdTrackService();
});

final cdRippingServiceProvider = Provider<CdRippingService>((ref) {
  return FfmpegCdRippingService();
});
