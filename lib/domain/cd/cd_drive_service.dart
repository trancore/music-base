class CdDrive {
  const CdDrive({
    required this.deviceId,
    required this.driveLetter,
    required this.name,
    required this.mediaLoaded,
  });

  final String deviceId;
  final String driveLetter;
  final String name;
  final bool mediaLoaded;
}

abstract interface class CdDriveService {
  Future<List<CdDrive>> listDrives();
}

class CdDriveException implements Exception {
  const CdDriveException(this.message);

  final String message;

  @override
  String toString() => 'CdDriveException: $message';
}
