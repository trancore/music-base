import 'internet_radio_station.dart';

abstract interface class RadioStreamTester {
  Future<void> test(InternetRadioStation station);
}
