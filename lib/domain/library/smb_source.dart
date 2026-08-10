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
