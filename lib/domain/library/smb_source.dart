class SmbSource {
  const SmbSource({
    required this.host,
    required this.share,
    this.subfolder = '',
    required this.username,
  });

  final String host;
  final String share;
  final String subfolder;
  final String username;

  /// Normalizes a subfolder path for SMB directory listing.
  static String normalizeSubfolder(String path) =>
      path.replaceAll('\\', '/').replaceAll(RegExp(r'^/+|/+$'), '');

  String get normalizedSubfolder => normalizeSubfolder(subfolder);

  String get librarySourceKey => 'smb://$host/$share';

  String get displayPath {
    final folder = normalizedSubfolder;
    return folder.isEmpty ? librarySourceKey : '$librarySourceKey/$folder';
  }

  SmbSource copyWith({
    String? host,
    String? share,
    String? subfolder,
    String? username,
  }) {
    return SmbSource(
      host: host ?? this.host,
      share: share ?? this.share,
      subfolder: subfolder ?? this.subfolder,
      username: username ?? this.username,
    );
  }
}
