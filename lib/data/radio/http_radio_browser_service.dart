import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/radio/radio_browser_service.dart';
import '../../domain/radio/radio_browser_station.dart';

class HttpRadioBrowserService implements RadioBrowserService {
  const HttpRadioBrowserService({this.client});

  static const _apiHost = 'de1.api.radio-browser.info';
  static const _userAgent = 'Music Base/1.0 (internet radio search)';
  final http.Client? client;

  @override
  Future<List<RadioBrowserStation>> search(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return const [];
    final uri = Uri.https(_apiHost, '/json/stations/search', {
      'name': trimmedQuery,
      'order': 'votes',
      'reverse': 'true',
      'hidebroken': 'true',
      'limit': '50',
    });
    final response = await (client ?? http.Client()).get(
      uri,
      headers: const {'Accept': 'application/json', 'User-Agent': _userAgent},
    );
    if (response.statusCode != 200) {
      throw StateError('Radio Browser returned HTTP ${response.statusCode}.');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];
    return decoded
        .map(RadioBrowserStation.fromJson)
        .whereType<RadioBrowserStation>()
        .where(
          (station) =>
              station.lastCheckOk &&
              !station.hls &&
              station.streamUrl.startsWith(RegExp(r'https?://')),
        )
        .toList(growable: false);
  }
}
