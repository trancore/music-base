import 'internet_radio_station.dart';

class RadioBrowserStation {
  const RadioBrowserStation({
    required this.stationUuid,
    required this.name,
    required this.streamUrl,
    required this.homepage,
    required this.tags,
    required this.countryCode,
    required this.codec,
    required this.bitrate,
    required this.lastCheckOk,
    required this.hls,
  });

  final String stationUuid;
  final String name;
  final String streamUrl;
  final String? homepage;
  final String? tags;
  final String? countryCode;
  final String? codec;
  final int? bitrate;
  final bool lastCheckOk;
  final bool hls;

  InternetRadioStation toInternetRadioStation() {
    final details = [
      if (countryCode case final country? when country.isNotEmpty) country,
      if (codec case final format? when format.isNotEmpty) format,
      if (bitrate case final rate?) '${rate}kbps',
    ].join(' • ');
    return InternetRadioStation(
      id: 'radio-browser:$stationUuid',
      name: name,
      streamUrl: streamUrl,
      genre: tags,
      description: details.isEmpty ? homepage : details,
    );
  }

  static RadioBrowserStation? fromJson(Object? value) {
    if (value is! Map) return null;
    final uuid = value['stationuuid'];
    final name = value['name'];
    final url = value['url_resolved'] ?? value['url'];
    if (uuid is! String || name is! String || url is! String) return null;
    final bitrate = value['bitrate'];
    final hls = value['hls'];
    final lastCheckOk = value['lastcheckok'];
    return RadioBrowserStation(
      stationUuid: uuid,
      name: name.trim().isEmpty ? 'Unnamed station' : name.trim(),
      streamUrl: url,
      homepage: value['homepage'] as String?,
      tags: value['tags'] as String?,
      countryCode: value['countrycode'] as String?,
      codec: value['codec'] as String?,
      bitrate: bitrate is num ? bitrate.toInt() : null,
      lastCheckOk: lastCheckOk == 1 || lastCheckOk == true,
      hls: hls == 1 || hls == true,
    );
  }
}
