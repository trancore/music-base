import '../../domain/library/local_directory_access_service.dart';

class DefaultLocalDirectoryAccessService
    implements LocalDirectoryAccessService {
  const DefaultLocalDirectoryAccessService();

  @override
  Future<void> prepareAccess(String path) async {}

  @override
  Future<void> saveAccess(String path) async {}
}
