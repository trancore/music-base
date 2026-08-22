import 'package:flutter_test/flutter_test.dart';

import 'package:music_base/data/radio/radio_station_transfer.dart';
import 'package:music_base/domain/radio/internet_radio_station.dart';

void main() {
  test('round trips radio station metadata as JSON', () {
    const stations = [
      InternetRadioStation(
        id: 'station-1',
        name: 'Example FM',
        streamUrl: 'https://example.com/stream',
        description: 'A test station',
        genre: 'Electronic',
      ),
    ];

    final restored = RadioStationTransfer.decode(
      RadioStationTransfer.encode(stations),
    );

    expect(restored, hasLength(1));
    expect(restored.single.id, stations.single.id);
    expect(restored.single.name, stations.single.name);
    expect(restored.single.streamUrl, stations.single.streamUrl);
    expect(restored.single.description, stations.single.description);
    expect(restored.single.genre, stations.single.genre);
  });

  test('rejects unsupported transfer files', () {
    expect(
      () => RadioStationTransfer.decode('{"version":2,"stations":[]}'),
      throwsFormatException,
    );
  });
}
