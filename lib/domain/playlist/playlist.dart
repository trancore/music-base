enum PlaylistType { manual, automatic }

class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    this.trackPaths = const [],
    this.type = PlaylistType.manual,
    this.query,
  });

  final String id;
  final String name;
  final List<String> trackPaths;
  final PlaylistType type;
  final String? query;

  bool get isAutomatic => type == PlaylistType.automatic;
}
