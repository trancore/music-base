enum PlaylistType { manual, automatic }

enum AutoPlaylistField { artist }

enum AutoPlaylistComparison { startsWith }

class AutoPlaylistRule {
  const AutoPlaylistRule({
    required this.field,
    required this.comparison,
    required this.value,
  });

  final AutoPlaylistField field;
  final AutoPlaylistComparison comparison;
  final String value;

  bool matches({String? artist}) {
    final candidate = switch (field) {
      AutoPlaylistField.artist => artist,
    };
    if (candidate == null) return false;
    final normalizedCandidate = candidate.toLowerCase();
    final normalizedValue = value.toLowerCase();
    return switch (comparison) {
      AutoPlaylistComparison.startsWith => normalizedCandidate.startsWith(
        normalizedValue,
      ),
    };
  }
}

class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    this.trackPaths = const [],
    this.type = PlaylistType.manual,
    this.query,
    this.autoRule,
    this.parentFolderId,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final List<String> trackPaths;
  final PlaylistType type;
  final String? query;
  final AutoPlaylistRule? autoRule;
  final String? parentFolderId;
  final int sortOrder;

  bool get isAutomatic => type == PlaylistType.automatic;

  Playlist copyWith({
    String? name,
    List<String>? trackPaths,
    PlaylistType? type,
    String? query,
    AutoPlaylistRule? autoRule,
    String? parentFolderId,
    bool moveToRoot = false,
    int? sortOrder,
  }) => Playlist(
    id: id,
    name: name ?? this.name,
    trackPaths: trackPaths ?? this.trackPaths,
    type: type ?? this.type,
    query: query ?? this.query,
    autoRule: autoRule ?? this.autoRule,
    parentFolderId: moveToRoot ? null : parentFolderId ?? this.parentFolderId,
    sortOrder: sortOrder ?? this.sortOrder,
  );
}

class PlaylistFolder {
  const PlaylistFolder({
    required this.id,
    required this.name,
    this.parentFolderId,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String? parentFolderId;
  final int sortOrder;

  PlaylistFolder copyWith({
    String? name,
    String? parentFolderId,
    bool moveToRoot = false,
    int? sortOrder,
  }) => PlaylistFolder(
    id: id,
    name: name ?? this.name,
    parentFolderId: moveToRoot ? null : parentFolderId ?? this.parentFolderId,
    sortOrder: sortOrder ?? this.sortOrder,
  );
}
