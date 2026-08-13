import '../../domain/library/library_repository.dart';
import '../../domain/library/library_query.dart';
import '../../domain/library/library_track.dart';
import '../../domain/playback/playback_service.dart';

class LibraryPlaybackQueue implements PlaybackQueueSource {
  const LibraryPlaybackQueue(this.repository, this.descriptor);

  final LibraryRepository repository;
  final LibraryPlaybackQueueDescriptor descriptor;

  @override
  int get length => descriptor.length;

  @override
  Future<LibraryTrack?> trackAt(int index) {
    if (index < 0 || index >= descriptor.length) return Future.value();
    return repository.loadPlaybackQueueTrack(descriptor.id, index);
  }

  @override
  Future<void> dispose() => repository.deletePlaybackQueue(descriptor.id);
}
