import 'smb_source.dart';

abstract interface class SmbService {
  Future<void> testConnection(SmbSource source, String password);
}

class SmbConnectionException implements Exception {
  const SmbConnectionException(this.message);

  final String message;

  @override
  String toString() => message;
}
