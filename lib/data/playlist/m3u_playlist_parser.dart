import 'dart:convert';

import 'package:path/path.dart' as p;

class M3uPlaylistImport {
  const M3uPlaylistImport({required this.name, required this.trackPaths});

  final String name;
  final List<String> trackPaths;
}

class M3uPlaylistParser {
  const M3uPlaylistParser();

  M3uPlaylistImport parseBytes(List<int> bytes, {required String sourcePath}) {
    return parse(utf8.decode(bytes), sourcePath: sourcePath);
  }

  M3uPlaylistImport parse(String content, {required String sourcePath}) {
    final paths = <String>[];
    for (var line in const LineSplitter().convert(content)) {
      line = line.trim();
      if (line.startsWith('\ufeff')) line = line.substring(1).trimLeft();
      if (line.isEmpty || line.startsWith('#')) continue;
      if (line.length >= 2 && line.startsWith('"') && line.endsWith('"')) {
        line = line.substring(1, line.length - 1);
      }
      paths.add(_resolvePath(line, sourcePath));
    }

    return M3uPlaylistImport(
      name: _playlistName(sourcePath),
      trackPaths: List.unmodifiable(paths),
    );
  }

  String _resolvePath(String entry, String sourcePath) {
    if (entry.startsWith('smb://')) return entry;
    if (p.windows.isAbsolute(entry)) {
      return p.windows.normalize(entry).replaceAll('\\', '/');
    }
    if (p.posix.isAbsolute(entry)) return p.posix.normalize(entry);

    if (p.windows.isAbsolute(sourcePath)) {
      return p.windows
          .normalize(p.windows.join(p.windows.dirname(sourcePath), entry))
          .replaceAll('\\', '/');
    }
    return p.normalize(p.join(p.dirname(sourcePath), entry));
  }

  String _playlistName(String sourcePath) {
    final basename = p.windows.isAbsolute(sourcePath)
        ? p.windows.basenameWithoutExtension(sourcePath)
        : p.basenameWithoutExtension(sourcePath);
    return basename.trim().isEmpty ? 'Imported playlist' : basename.trim();
  }
}
