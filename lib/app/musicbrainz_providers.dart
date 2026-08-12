import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/metadata/musicbrainz_api_client.dart';
import '../domain/metadata/musicbrainz_service.dart';

final musicBrainzServiceProvider = Provider<MusicBrainzService>((ref) {
  final client = MusicBrainzApiClient(httpClient: IoMusicBrainzHttpClient());
  ref.onDispose(client.httpClient.close);
  return client;
});
