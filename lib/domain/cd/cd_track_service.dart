import 'cd_drive_service.dart';
import 'cd_import_plan.dart';

abstract interface class CdTrackService {
  Future<List<CdTrack>> readTracks(CdDrive drive);
}

class CdTrackException implements Exception {
  const CdTrackException(this.message);

  final String message;

  @override
  String toString() => 'CdTrackException: $message';
}
