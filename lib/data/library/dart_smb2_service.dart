import 'package:dart_smb2/dart_smb2.dart';

import '../../domain/library/smb_service.dart';
import '../../domain/library/smb_source.dart';

class DartSmb2Service implements SmbService {
  const DartSmb2Service();

  @override
  Future<void> testConnection(SmbSource source, String password) async {
    _validate(source);
    Smb2Pool? pool;
    try {
      pool = await Smb2Pool.connect(
        host: source.host,
        share: source.share,
        user: source.username,
        password: password,
        workers: 1,
        timeoutSeconds: 30,
      );
      await pool.listDirectory(source.subfolder);
    } on Smb2Exception catch (error) {
      throw SmbConnectionException(_messageFor(error));
    } on Exception catch (error) {
      throw SmbConnectionException(
        'Unable to connect to the SMB share: $error',
      );
    } finally {
      await pool?.disconnect();
    }
  }

  void _validate(SmbSource source) {
    if (source.host.trim().isEmpty || source.share.trim().isEmpty) {
      throw const SmbConnectionException('SMB host and share are required.');
    }
    if (source.username.trim().isEmpty) {
      throw const SmbConnectionException('SMB username is required.');
    }
  }

  String _messageFor(Smb2Exception error) {
    return switch (error.type) {
      Smb2ErrorType.auth => 'SMB authentication failed.',
      Smb2ErrorType.connection ||
      Smb2ErrorType.timeout => 'The SMB server could not be reached.',
      Smb2ErrorType.accessDenied => 'Access to the SMB share was denied.',
      _ => 'The SMB connection failed: ${error.message}',
    };
  }
}
