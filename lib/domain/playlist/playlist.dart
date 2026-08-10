class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    required this.trackPaths,
  });

  final String id;
  final String name;
  final List<String> trackPaths;
}
