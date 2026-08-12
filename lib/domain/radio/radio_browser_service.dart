import 'radio_browser_station.dart';

abstract interface class RadioBrowserService {
  Future<List<RadioBrowserStation>> search(String query);
}
