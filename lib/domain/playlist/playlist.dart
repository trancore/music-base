enum PlaylistType { manual, automatic }

class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    this.trackPaths = const [],
    this.type = PlaylistType.manual,
    this.query,
    this.parentFolderId,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final List<String> trackPaths;
  final PlaylistType type;
  final String? query;
  final String? parentFolderId;
  final int sortOrder;

  bool get isAutomatic => type == PlaylistType.automatic;

  Playlist copyWith({
    String? name,
    List<String>? trackPaths,
    PlaylistType? type,
    String? query,
    String? parentFolderId,
    bool moveToRoot = false,
    int? sortOrder,
  }) => Playlist(
    id: id,
    name: name ?? this.name,
    trackPaths: trackPaths ?? this.trackPaths,
    type: type ?? this.type,
    query: query ?? this.query,
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
