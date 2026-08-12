import 'musicbrainz_release.dart';

abstract interface class MusicBrainzService {
  Future<List<MusicBrainzRelease>> searchReleases({
    String? artist,
    String? album,
    int limit = 10,
  });

  Future<MusicBrainzRelease> getRelease(String id);
}
