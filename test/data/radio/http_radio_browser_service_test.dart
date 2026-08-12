import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:music_base/data/radio/http_radio_browser_service.dart';

void main() {
  test('searches Radio Browser and keeps reachable direct streams', () async {
    final client = MockClient((request) async {
      expect(request.url.queryParameters['name'], 'SomaFM');
      expect(request.headers['user-agent'], contains('Music Base'));
      return http.Response(
        '[{"stationuuid":"ok","name":"Good Station","url":"https://example.test/listen.pls","url_resolved":"https://example.test/live.mp3","tags":"ambient","codec":"MP3","bitrate":128,"lastcheckok":1,"hls":0},{"stationuuid":"bad","name":"Offline","url_resolved":"https://example.test/offline.mp3","lastcheckok":0,"hls":0}]',
        200,
      );
    });
    final service = HttpRadioBrowserService(client: client);

    final stations = await service.search('SomaFM');

    expect(stations, hasLength(1));
    expect(stations.single.streamUrl, 'https://example.test/live.mp3');
  });

  test('reports an API failure', () async {
    final service = HttpRadioBrowserService(
      client: MockClient((_) async => http.Response('error', 503)),
    );

    expect(() => service.search('jazz'), throwsA(isA<StateError>()));
  });
}
