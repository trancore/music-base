import 'library_track.dart';

enum LibrarySortField { title, artist, album, sourcePath, albumTrack }

enum LibraryGroupKind { album, artist }

class LibraryQuery {
  const LibraryQuery({
    this.sourceKey,
    this.search = '',
    this.sortField = LibrarySortField.title,
    this.ascending = true,
    this.pageSize = 200,
    this.cursor,
    this.album,
    this.artist,
  });

  final String? sourceKey;
  final String search;
  final LibrarySortField sortField;
  final bool ascending;
  final int pageSize;
  final LibraryCursor? cursor;
  final String? album;
  final String? artist;

  LibraryQuery copyWith({LibraryCursor? cursor, bool clearCursor = false}) =>
      LibraryQuery(
        sourceKey: sourceKey,
        search: search,
        sortField: sortField,
        ascending: ascending,
        pageSize: pageSize,
        cursor: clearCursor ? null : cursor ?? this.cursor,
        album: album,
        artist: artist,
      );
}

class LibraryGroupQuery {
  const LibraryGroupQuery({
    required this.kind,
    this.sourceKey,
    this.search = '',
    this.pageSize = 100,
    this.cursor,
  });

  final LibraryGroupKind kind;
  final String? sourceKey;
  final String search;
  final int pageSize;
  final LibraryGroupCursor? cursor;
}

class LibraryGroupCursor {
  const LibraryGroupCursor({required this.sortValue, required this.groupValue});

  final String sortValue;
  final String groupValue;
}

class LibraryGroup {
  const LibraryGroup({
    required this.kind,
    required this.value,
    required this.trackCount,
    this.artworkTrackId,
  });

  final LibraryGroupKind kind;
  final String value;
  final int trackCount;
  final int? artworkTrackId;

  String get displayName => value.isEmpty
      ? switch (kind) {
          LibraryGroupKind.album => 'Unknown album',
          LibraryGroupKind.artist => 'Unknown artist',
        }
      : value;

  LibraryQuery tracksQuery({String? sourceKey}) => LibraryQuery(
    sourceKey: sourceKey,
    album: kind == LibraryGroupKind.album ? value : null,
    artist: kind == LibraryGroupKind.artist ? value : null,
    sortField: kind == LibraryGroupKind.album
        ? LibrarySortField.albumTrack
        : LibrarySortField.album,
  );
}

class LibraryGroupPage {
  const LibraryGroupPage({
    required this.items,
    required this.totalCount,
    this.nextCursor,
  });

  final List<LibraryGroup> items;
  final int totalCount;
  final LibraryGroupCursor? nextCursor;
}

class LibraryCursor {
  const LibraryCursor({required this.sortValue, required this.id});

  final String sortValue;
  final int id;
}

class LibraryPage {
  const LibraryPage({
    required this.items,
    required this.totalCount,
    this.nextCursor,
  });

  final List<LibraryTrack> items;
  final int totalCount;
  final LibraryCursor? nextCursor;
}

class LibraryPlaybackQueueDescriptor {
  const LibraryPlaybackQueueDescriptor({
    required this.id,
    required this.length,
  });

  final String id;
  final int length;
}
