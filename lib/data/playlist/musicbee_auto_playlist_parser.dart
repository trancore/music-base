import 'dart:convert';

import 'package:path/path.dart' as p;

import '../../domain/playlist/playlist.dart';

class MusicBeeAutoPlaylistImport {
  const MusicBeeAutoPlaylistImport({required this.name, required this.rule});

  final String name;
  final AutoPlaylistRule rule;
}

/// Reads the supported subset of MusicBee smart playlists (`.xautopf`).
class MusicBeeAutoPlaylistParser {
  const MusicBeeAutoPlaylistParser();

  static final _conditionsPattern = RegExp(
    r'<Conditions\b([^>]*)>([\s\S]*?)</Conditions\s*>',
    caseSensitive: false,
  );
  static final _conditionPattern = RegExp(
    r'<Condition\b([^>]*)/?>',
    caseSensitive: false,
  );
  static final _attributePattern = RegExp(
    r'''([A-Za-z][\w:-]*)\s*=\s*(?:"([^"]*)"|'([^']*)')''',
  );

  MusicBeeAutoPlaylistImport parseBytes(
    List<int> bytes, {
    required String sourcePath,
  }) {
    final xml = utf8.decode(bytes, allowMalformed: false);
    if (!RegExp(r'<SmartPlaylist\b', caseSensitive: false).hasMatch(xml)) {
      throw const FormatException('The file is not a MusicBee auto playlist.');
    }

    final conditionsMatch = _conditionsPattern.firstMatch(xml);
    if (conditionsMatch == null ||
        _conditionsPattern.allMatches(xml).length != 1) {
      throw const FormatException(
        'The MusicBee auto playlist must contain one conditions group.',
      );
    }
    final conditionsAttributes = _attributes(conditionsMatch.group(1)!);
    if ((conditionsAttributes['combinemethod'] ?? 'All').toLowerCase() !=
        'all') {
      throw const FormatException(
        'Only MusicBee auto playlists that match all conditions are supported.',
      );
    }

    final conditionMatches = _conditionPattern
        .allMatches(conditionsMatch.group(2)!)
        .toList(growable: false);
    if (conditionMatches.length != 1) {
      throw const FormatException(
        'Only MusicBee auto playlists with one condition are supported.',
      );
    }
    final attributes = _attributes(conditionMatches.single.group(1)!);
    final field = attributes['field'];
    final comparison = attributes['comparison'];
    final value = attributes['value']?.trim();
    if (field?.toLowerCase() != 'artistpeople' ||
        comparison?.toLowerCase() != 'startswith' ||
        value == null ||
        value.isEmpty) {
      throw const FormatException(
        'Only an ArtistPeople StartsWith condition is currently supported.',
      );
    }

    return MusicBeeAutoPlaylistImport(
      name: _playlistName(sourcePath),
      rule: AutoPlaylistRule(
        field: AutoPlaylistField.artist,
        comparison: AutoPlaylistComparison.startsWith,
        value: value,
      ),
    );
  }

  Map<String, String> _attributes(String source) => {
    for (final match in _attributePattern.allMatches(source))
      match.group(1)!.toLowerCase(): _decodeXmlEntities(
        match.group(2) ?? match.group(3)!,
      ),
  };

  String _decodeXmlEntities(String value) {
    return value.replaceAllMapped(RegExp(r'&(#x[0-9A-Fa-f]+|#\d+|\w+);'), (
      match,
    ) {
      final entity = match.group(1)!;
      if (entity.startsWith('#x')) {
        return String.fromCharCode(int.parse(entity.substring(2), radix: 16));
      }
      if (entity.startsWith('#')) {
        return String.fromCharCode(int.parse(entity.substring(1)));
      }
      return switch (entity) {
        'amp' => '&',
        'lt' => '<',
        'gt' => '>',
        'quot' => '"',
        'apos' => "'",
        _ => throw FormatException('Unsupported XML entity: &$entity;'),
      };
    });
  }

  String _playlistName(String sourcePath) {
    final basename = sourcePath.trim().isEmpty
        ? ''
        : p.basenameWithoutExtension(sourcePath);
    return basename.trim().isEmpty ? 'Imported playlist' : basename.trim();
  }
}
