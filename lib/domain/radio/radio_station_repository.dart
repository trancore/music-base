import 'internet_radio_station.dart';

abstract interface class RadioStationRepository {
  Future<List<InternetRadioStation>> loadAll();

  Future<void> save(InternetRadioStation station);

  Future<void> saveAll(List<InternetRadioStation> stations);

  Future<void> delete(String id);
}
