class MusicBrainzRelease {
  const MusicBrainzRelease({
    required this.id,
    required this.title,
    this.artist,
    this.releaseDate,
    this.country,
    this.trackCount,
  });

  final String id;
  final String title;
  final String? artist;
  final String? releaseDate;
  final String? country;
  final int? trackCount;

  String get coverArtUrl => 'https://coverartarchive.org/release/$id/front-250';
}
