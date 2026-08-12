abstract interface class LocalDirectoryAccessService {
  Future<void> prepareAccess(String path);

  Future<void> saveAccess(String path);
}
