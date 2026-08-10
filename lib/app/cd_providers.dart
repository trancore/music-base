import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cd/windows_cd_drive_service.dart';
import '../domain/cd/cd_drive_service.dart';

final cdDriveServiceProvider = Provider<CdDriveService>((ref) {
  return WindowsCdDriveService();
});
