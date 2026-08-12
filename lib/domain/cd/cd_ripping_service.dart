import 'cd_drive_service.dart';
import 'cd_import_plan.dart';

class CdRippingCancellationToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;
}

abstract interface class CdRippingService {
  Future<void> ripTrack({
    required CdDrive drive,
    required CdTrack track,
    required String outputPath,
    required CdImportFormat format,
    String? title,
    String? artist,
    String? album,
    String? releaseDate,
    CdRippingCancellationToken? cancellationToken,
  });
}

class CdRippingException implements Exception {
  const CdRippingException(this.message);

  final String message;

  @override
  String toString() => 'CdRippingException: $message';
}
