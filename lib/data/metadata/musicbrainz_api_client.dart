import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/metadata/musicbrainz_release.dart';
import '../../domain/metadata/musicbrainz_service.dart';

class MusicBrainzHttpResponse {
  const MusicBrainzHttpResponse(this.statusCode, this.body);

  final int statusCode;
  final String body;
}

abstract interface class MusicBrainzHttpClient {
  Future<MusicBrainzHttpResponse> get(Uri uri, {required String userAgent});

  void close();
}

class IoMusicBrainzHttpClient implements MusicBrainzHttpClient {
  final HttpClient _client = HttpClient();

  @override
  Future<MusicBrainzHttpResponse> get(
    Uri uri, {
    required String userAgent,
  }) async {
    final request = await _client.getUrl(uri);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.headers.set(HttpHeaders.userAgentHeader, userAgent);
    final response = await request.close();
    return MusicBrainzHttpResponse(
      response.statusCode,
      await response.transform(utf8.decoder).join(),
    );
  }

  @override
  void close() => _client.close(force: true);
}

class MusicBrainzException implements Exception {
  const MusicBrainzException(this.message);

  final String message;

  @override
  String toString() => 'MusicBrainzException: $message';
}

class MusicBrainzApiClient implements MusicBrainzService {
  MusicBrainzApiClient({
    required this.httpClient,
    this.userAgent = 'MusicBase/1.2.0 (https://github.com/trancore/music-base)',
    this.minimumRequestInterval = const Duration(seconds: 1),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final MusicBrainzHttpClient httpClient;
  final String userAgent;
  final Duration minimumRequestInterval;
  final DateTime Function() _now;
  final Map<String, List<MusicBrainzRelease>> _cache = {};
  DateTime? _lastRequestAt;
  Future<void> _requestLock = Future<void>.value();

  @override
  Future<List<MusicBrainzRelease>> searchReleases({
    String? artist,
    String? album,
    int limit = 10,
  }) async {
    final normalizedArtist = artist?.trim() ?? '';
    final normalizedAlbum = album?.trim() ?? '';
    if (normalizedArtist.isEmpty && normalizedAlbum.isEmpty) {
      return const [];
    }
    final boundedLimit = limit.clamp(1, 100).toInt();
    final cacheKey =
        '${normalizedArtist.toLowerCase()}|${normalizedAlbum.toLowerCase()}|$boundedLimit';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final queryParts = <String>[];
    if (normalizedArtist.isNotEmpty) {
      queryParts.add('artist:"${_escapeQuery(normalizedArtist)}"');
    }
    if (normalizedAlbum.isNotEmpty) {
      queryParts.add('release:"${_escapeQuery(normalizedAlbum)}"');
    }
    final uri = Uri.https('musicbrainz.org', '/ws/2/release', {
      'query': queryParts.join(' AND '),
      'fmt': 'json',
      'limit': '$boundedLimit',
    });
    final response = await _get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MusicBrainzException(
        'MusicBrainz request failed with HTTP ${response.statusCode}.',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['releases'] is! List) {
      throw const MusicBrainzException('Invalid MusicBrainz response.');
    }
    final releases = (decoded['releases'] as List)
        .whereType<Map>()
        .map(_parseRelease)
        .whereType<MusicBrainzRelease>()
        .toList(growable: false);
    _cache[cacheKey] = releases;
    return releases;
  }

  @override
  Future<MusicBrainzRelease> getRelease(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw const MusicBrainzException('A release MBID is required.');
    }
    final cacheKey = 'release:$normalizedId';
    final cached = _cache[cacheKey];
    if (cached != null && cached.isNotEmpty) return cached.first;

    final uri = Uri.https('musicbrainz.org', '/ws/2/release/$normalizedId', {
      'inc': 'artist-credits+media+recordings',
      'fmt': 'json',
    });
    final response = await _get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MusicBrainzException(
        'MusicBrainz release lookup failed with HTTP ${response.statusCode}.',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const MusicBrainzException('Invalid MusicBrainz release response.');
    }
    final release = _parseRelease(decoded);
    if (release == null) {
      throw const MusicBrainzException('MusicBrainz response has no release.');
    }
    _cache[cacheKey] = [release];
    return release;
  }

  Future<MusicBrainzHttpResponse> _get(Uri uri) async {
    final previous = _requestLock;
    final completer = Completer<void>();
    _requestLock = completer.future;
    await previous;
    try {
      final lastRequestAt = _lastRequestAt;
      if (lastRequestAt != null) {
        final elapsed = _now().difference(lastRequestAt);
        final remaining = minimumRequestInterval - elapsed;
        if (remaining > Duration.zero) await Future<void>.delayed(remaining);
      }
      _lastRequestAt = _now();
      return await httpClient.get(uri, userAgent: userAgent);
    } finally {
      completer.complete();
    }
  }

  MusicBrainzRelease? _parseRelease(Map entry) {
    final id = entry['id'];
    final title = entry['title'];
    if (id is! String || title is! String || id.isEmpty || title.isEmpty) {
      return null;
    }
    final artistCredit = entry['artist-credit'];
    String? artist;
    if (artistCredit is List && artistCredit.isNotEmpty) {
      final firstCredit = artistCredit.first;
      if (firstCredit is Map && firstCredit['name'] is String) {
        artist = firstCredit['name'] as String;
      }
    }
    return MusicBrainzRelease(
      id: id,
      title: title,
      artist: artist,
      releaseDate: entry['date'] as String?,
      country: entry['country'] as String?,
      trackCount: (entry['track-count'] as num?)?.toInt(),
      media: _parseMedia(entry['media']),
    );
  }

  List<MusicBrainzMedium> _parseMedia(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((medium) {
          final tracks = medium['tracks'];
          return MusicBrainzMedium(
            position: (medium['position'] as num?)?.toInt() ?? 0,
            format: medium['format'] as String?,
            title: medium['title'] as String?,
            tracks: tracks is List
                ? tracks
                      .whereType<Map>()
                      .map((track) {
                        final recording = track['recording'];
                        final recordingTitle = recording is Map
                            ? recording['title'] as String?
                            : null;
                        return MusicBrainzTrack(
                          position: (track['position'] as num?)?.toInt() ?? 0,
                          title:
                              track['title'] as String? ?? recordingTitle ?? '',
                          number: track['number'] as String?,
                          lengthMilliseconds:
                              (track['length'] as num?)?.toInt() ??
                              (recording is Map
                                  ? (recording['length'] as num?)?.toInt()
                                  : null),
                        );
                      })
                      .where((track) => track.title.isNotEmpty)
                      .toList(growable: false)
                : const [],
          );
        })
        .toList(growable: false);
  }

  String _escapeQuery(String value) =>
      value.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
}
