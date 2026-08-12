import 'package:flutter_test/flutter_test.dart';

import 'package:music_base/data/metadata/musicbrainz_api_client.dart';

void main() {
  test(
    'maps release search results and sends an identifying user agent',
    () async {
      final httpClient = _FakeMusicBrainzHttpClient(
        const MusicBrainzHttpResponse(
          200,
          '{"releases":[{"id":"release-id","title":"Album",'
          '"artist-credit":[{"name":"Artist"}],"date":"2020-01-02",'
          '"country":"JP","track-count":10}]}',
        ),
      );
      final client = MusicBrainzApiClient(
        httpClient: httpClient,
        minimumRequestInterval: Duration.zero,
      );

      final results = await client.searchReleases(
        artist: 'Artist',
        album: 'Album',
      );

      expect(results.single.id, 'release-id');
      expect(results.single.artist, 'Artist');
      expect(results.single.coverArtUrl, contains('release-id'));
      expect(httpClient.userAgent, contains('MusicBase/'));
      expect(httpClient.uri!.queryParameters['fmt'], 'json');
    },
  );

  test('uses the response cache for identical searches', () async {
    final httpClient = _FakeMusicBrainzHttpClient(
      const MusicBrainzHttpResponse(200, '{"releases":[]}'),
    );
    final client = MusicBrainzApiClient(
      httpClient: httpClient,
      minimumRequestInterval: Duration.zero,
    );

    await client.searchReleases(album: 'Album');
    await client.searchReleases(album: ' Album ');

    expect(httpClient.requestCount, 1);
  });
}

class _FakeMusicBrainzHttpClient implements MusicBrainzHttpClient {
  _FakeMusicBrainzHttpClient(this.response);

  final MusicBrainzHttpResponse response;
  Uri? uri;
  String? userAgent;
  int requestCount = 0;

  @override
  Future<MusicBrainzHttpResponse> get(
    Uri requestUri, {
    required String userAgent,
  }) async {
    uri = requestUri;
    this.userAgent = userAgent;
    requestCount++;
    return response;
  }

  @override
  void close() {}
}
