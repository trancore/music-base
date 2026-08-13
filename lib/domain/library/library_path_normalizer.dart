import 'package:path/path.dart' as p;

/// Returns a stable path key for matching playlist entries to library tracks.
///
/// Windows drive paths are case-insensitive. POSIX and SMB paths retain their
/// case because the backing filesystem may be case-sensitive.
String normalizeLibraryComparisonPath(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';
  final slashPath = trimmed.replaceAll('\\', '/');
  if (RegExp(r'^[a-zA-Z]:/').hasMatch(slashPath)) {
    return p.windows.normalize(slashPath).replaceAll('\\', '/').toLowerCase();
  }
  if (slashPath.startsWith('smb://')) {
    final uri = Uri.tryParse(slashPath);
    if (uri != null && uri.scheme == 'smb' && uri.host.isNotEmpty) {
      final path = p.posix.normalize('/${uri.pathSegments.join('/')}');
      return 'smb://${uri.authority}$path';
    }
    final separator = slashPath.indexOf('/', 'smb://'.length);
    if (separator < 0) return slashPath;
    final authority = slashPath.substring(0, separator);
    final path = p.posix.normalize(slashPath.substring(separator));
    return '$authority$path';
  }
  return p.posix.normalize(slashPath);
}

String joinLibraryPath(String root, String relativePath) {
  final normalizedRoot = root.trim().replaceAll('\\', '/');
  final normalizedRelative = relativePath.trim().replaceAll('\\', '/');
  if (RegExp(r'^[a-zA-Z]:/').hasMatch(normalizedRoot)) {
    return p.windows
        .normalize(p.windows.join(normalizedRoot, normalizedRelative))
        .replaceAll('\\', '/');
  }
  if (normalizedRoot.startsWith('smb://')) {
    final uri = Uri.tryParse(normalizedRoot);
    if (uri != null && uri.scheme == 'smb' && uri.host.isNotEmpty) {
      final pathSegments = [
        ...uri.pathSegments.where((segment) => segment.isNotEmpty),
        ...p.posix
            .normalize(normalizedRelative)
            .split('/')
            .where((segment) => segment.isNotEmpty && segment != '.'),
      ];
      return Uri(
        scheme: uri.scheme,
        userInfo: uri.userInfo,
        host: uri.host,
        port: uri.hasPort ? uri.port : null,
        pathSegments: pathSegments,
      ).toString();
    }
  }
  return p.posix.normalize(p.posix.join(normalizedRoot, normalizedRelative));
}
