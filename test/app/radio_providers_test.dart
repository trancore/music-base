import 'package:flutter_test/flutter_test.dart';
import 'package:music_base/app/radio_providers.dart';

void main() {
  test('accepts direct HTTP audio stream URLs', () {
    expect(validateRadioStationUrl('https://u1.happyhardcore.com/'), isNull);
    expect(
      validateRadioStationUrl('http://radio.example.test:8000/stream'),
      isNull,
    );
  });

  test('rejects web pages and invalid URLs', () {
    expect(
      validateRadioStationUrl(
        'https://www.happyhardcore.com/radio/player/radio.asp',
      ),
      contains('audio stream URL'),
    );
    expect(validateRadioStationUrl('file:///tmp/radio.mp3'), isNotNull);
    expect(validateRadioStationUrl('not a url'), isNotNull);
  });
}
