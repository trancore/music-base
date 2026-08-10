class MusicBrainzRelease {
  const MusicBrainzRelease({
    required this.id,
    required this.title,
    this.artist,
    this.releaseDate,
    this.country,
    this.trackCount,
    this.media = const [],
  });

  final String id;
  final String title;
  final String? artist;
  final String? releaseDate;
  final String? country;
  final int? trackCount;
  final List<MusicBrainzMedium> media;

  String get coverArtUrl => 'https://coverartarchive.org/release/$id/front-250';
}

class MusicBrainzMedium {
  const MusicBrainzMedium({
    required this.position,
    this.format,
    this.title,
    this.tracks = const [],
  });

  final int position;
  final String? format;
  final String? title;
  final List<MusicBrainzTrack> tracks;
}

class MusicBrainzTrack {
  const MusicBrainzTrack({
    required this.position,
    required this.title,
    this.number,
    this.lengthMilliseconds,
  });

  final int position;
  final String title;
  final String? number;
  final int? lengthMilliseconds;
}
