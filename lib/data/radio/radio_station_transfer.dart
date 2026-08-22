import 'dart:convert';

import '../../domain/radio/internet_radio_station.dart';

class RadioStationTransfer {
  const RadioStationTransfer._();

  static const formatVersion = 1;

  static String encode(Iterable<InternetRadioStation> stations) {
    return jsonEncode({
      'version': formatVersion,
      'stations': stations.map((station) => station.toJson()).toList(),
    });
  }

  static List<InternetRadioStation> decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map || decoded['version'] != formatVersion) {
      throw const FormatException('Unsupported radio station file format.');
    }
    final values = decoded['stations'];
    if (values is! List) {
      throw const FormatException('The station list is missing.');
    }
    final stations = values
        .map(InternetRadioStation.fromJson)
        .whereType<InternetRadioStation>()
        .toList(growable: false);
    if (stations.isEmpty && values.isNotEmpty) {
      throw const FormatException('No valid radio stations were found.');
    }
    return stations;
  }
}
