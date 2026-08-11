import '../library/library_track.dart';

abstract interface class AudioAnalysisService {
  Future<List<double>> waveformFor(LibraryTrack track);
}
