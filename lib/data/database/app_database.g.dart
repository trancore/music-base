// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LibraryArtworksTable extends LibraryArtworks
    with TableInfo<$LibraryArtworksTable, LibraryArtwork> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LibraryArtworksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  @override
  late final GeneratedColumn<Uint8List> bytes = GeneratedColumn<Uint8List>(
    'bytes',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, contentHash, bytes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'library_artworks';
  @override
  VerificationContext validateIntegrity(
    Insertable<LibraryArtwork> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentHashMeta);
    }
    if (data.containsKey('bytes')) {
      context.handle(
        _bytesMeta,
        bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta),
      );
    } else if (isInserting) {
      context.missing(_bytesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LibraryArtwork map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LibraryArtwork(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      )!,
      bytes: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}bytes'],
      )!,
    );
  }

  @override
  $LibraryArtworksTable createAlias(String alias) {
    return $LibraryArtworksTable(attachedDatabase, alias);
  }
}

class LibraryArtwork extends DataClass implements Insertable<LibraryArtwork> {
  final int id;
  final String contentHash;
  final Uint8List bytes;
  const LibraryArtwork({
    required this.id,
    required this.contentHash,
    required this.bytes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['content_hash'] = Variable<String>(contentHash);
    map['bytes'] = Variable<Uint8List>(bytes);
    return map;
  }

  LibraryArtworksCompanion toCompanion(bool nullToAbsent) {
    return LibraryArtworksCompanion(
      id: Value(id),
      contentHash: Value(contentHash),
      bytes: Value(bytes),
    );
  }

  factory LibraryArtwork.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LibraryArtwork(
      id: serializer.fromJson<int>(json['id']),
      contentHash: serializer.fromJson<String>(json['contentHash']),
      bytes: serializer.fromJson<Uint8List>(json['bytes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'contentHash': serializer.toJson<String>(contentHash),
      'bytes': serializer.toJson<Uint8List>(bytes),
    };
  }

  LibraryArtwork copyWith({int? id, String? contentHash, Uint8List? bytes}) =>
      LibraryArtwork(
        id: id ?? this.id,
        contentHash: contentHash ?? this.contentHash,
        bytes: bytes ?? this.bytes,
      );
  LibraryArtwork copyWithCompanion(LibraryArtworksCompanion data) {
    return LibraryArtwork(
      id: data.id.present ? data.id.value : this.id,
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LibraryArtwork(')
          ..write('id: $id, ')
          ..write('contentHash: $contentHash, ')
          ..write('bytes: $bytes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, contentHash, $driftBlobEquality.hash(bytes));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibraryArtwork &&
          other.id == this.id &&
          other.contentHash == this.contentHash &&
          $driftBlobEquality.equals(other.bytes, this.bytes));
}

class LibraryArtworksCompanion extends UpdateCompanion<LibraryArtwork> {
  final Value<int> id;
  final Value<String> contentHash;
  final Value<Uint8List> bytes;
  const LibraryArtworksCompanion({
    this.id = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.bytes = const Value.absent(),
  });
  LibraryArtworksCompanion.insert({
    this.id = const Value.absent(),
    required String contentHash,
    required Uint8List bytes,
  }) : contentHash = Value(contentHash),
       bytes = Value(bytes);
  static Insertable<LibraryArtwork> custom({
    Expression<int>? id,
    Expression<String>? contentHash,
    Expression<Uint8List>? bytes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (contentHash != null) 'content_hash': contentHash,
      if (bytes != null) 'bytes': bytes,
    });
  }

  LibraryArtworksCompanion copyWith({
    Value<int>? id,
    Value<String>? contentHash,
    Value<Uint8List>? bytes,
  }) {
    return LibraryArtworksCompanion(
      id: id ?? this.id,
      contentHash: contentHash ?? this.contentHash,
      bytes: bytes ?? this.bytes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<Uint8List>(bytes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LibraryArtworksCompanion(')
          ..write('id: $id, ')
          ..write('contentHash: $contentHash, ')
          ..write('bytes: $bytes')
          ..write(')'))
        .toString();
  }
}

class $LibraryTracksTable extends LibraryTracks
    with TableInfo<$LibraryTracksTable, LibraryTrack> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LibraryTracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sourcePathMeta = const VerificationMeta(
    'sourcePath',
  );
  @override
  late final GeneratedColumn<String> sourcePath = GeneratedColumn<String>(
    'source_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _comparisonPathMeta = const VerificationMeta(
    'comparisonPath',
  );
  @override
  late final GeneratedColumn<String> comparisonPath = GeneratedColumn<String>(
    'comparison_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sourceKeyMeta = const VerificationMeta(
    'sourceKey',
  );
  @override
  late final GeneratedColumn<String> sourceKey = GeneratedColumn<String>(
    'source_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
    'artist',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _albumMeta = const VerificationMeta('album');
  @override
  late final GeneratedColumn<String> album = GeneratedColumn<String>(
    'album',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _artworkMeta = const VerificationMeta(
    'artwork',
  );
  @override
  late final GeneratedColumn<Uint8List> artwork = GeneratedColumn<Uint8List>(
    'artwork',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _artworkIdMeta = const VerificationMeta(
    'artworkId',
  );
  @override
  late final GeneratedColumn<int> artworkId = GeneratedColumn<int>(
    'artwork_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES library_artworks (id)',
    ),
  );
  static const VerificationMeta _lastSeenAtMeta = const VerificationMeta(
    'lastSeenAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSeenAt = GeneratedColumn<DateTime>(
    'last_seen_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
    'modified_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scanGenerationMeta = const VerificationMeta(
    'scanGeneration',
  );
  @override
  late final GeneratedColumn<int> scanGeneration = GeneratedColumn<int>(
    'scan_generation',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _discNumberMeta = const VerificationMeta(
    'discNumber',
  );
  @override
  late final GeneratedColumn<int> discNumber = GeneratedColumn<int>(
    'disc_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trackNumberMeta = const VerificationMeta(
    'trackNumber',
  );
  @override
  late final GeneratedColumn<int> trackNumber = GeneratedColumn<int>(
    'track_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _metadataVersionMeta = const VerificationMeta(
    'metadataVersion',
  );
  @override
  late final GeneratedColumn<int> metadataVersion = GeneratedColumn<int>(
    'metadata_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourcePath,
    comparisonPath,
    sourceKey,
    title,
    artist,
    album,
    artwork,
    artworkId,
    lastSeenAt,
    fileSize,
    modifiedAt,
    scanGeneration,
    discNumber,
    trackNumber,
    metadataVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'library_tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<LibraryTrack> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source_path')) {
      context.handle(
        _sourcePathMeta,
        sourcePath.isAcceptableOrUnknown(data['source_path']!, _sourcePathMeta),
      );
    } else if (isInserting) {
      context.missing(_sourcePathMeta);
    }
    if (data.containsKey('comparison_path')) {
      context.handle(
        _comparisonPathMeta,
        comparisonPath.isAcceptableOrUnknown(
          data['comparison_path']!,
          _comparisonPathMeta,
        ),
      );
    }
    if (data.containsKey('source_key')) {
      context.handle(
        _sourceKeyMeta,
        sourceKey.isAcceptableOrUnknown(data['source_key']!, _sourceKeyMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('artist')) {
      context.handle(
        _artistMeta,
        artist.isAcceptableOrUnknown(data['artist']!, _artistMeta),
      );
    }
    if (data.containsKey('album')) {
      context.handle(
        _albumMeta,
        album.isAcceptableOrUnknown(data['album']!, _albumMeta),
      );
    }
    if (data.containsKey('artwork')) {
      context.handle(
        _artworkMeta,
        artwork.isAcceptableOrUnknown(data['artwork']!, _artworkMeta),
      );
    }
    if (data.containsKey('artwork_id')) {
      context.handle(
        _artworkIdMeta,
        artworkId.isAcceptableOrUnknown(data['artwork_id']!, _artworkIdMeta),
      );
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
        _lastSeenAtMeta,
        lastSeenAt.isAcceptableOrUnknown(
          data['last_seen_at']!,
          _lastSeenAtMeta,
        ),
      );
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    }
    if (data.containsKey('scan_generation')) {
      context.handle(
        _scanGenerationMeta,
        scanGeneration.isAcceptableOrUnknown(
          data['scan_generation']!,
          _scanGenerationMeta,
        ),
      );
    }
    if (data.containsKey('disc_number')) {
      context.handle(
        _discNumberMeta,
        discNumber.isAcceptableOrUnknown(data['disc_number']!, _discNumberMeta),
      );
    }
    if (data.containsKey('track_number')) {
      context.handle(
        _trackNumberMeta,
        trackNumber.isAcceptableOrUnknown(
          data['track_number']!,
          _trackNumberMeta,
        ),
      );
    }
    if (data.containsKey('metadata_version')) {
      context.handle(
        _metadataVersionMeta,
        metadataVersion.isAcceptableOrUnknown(
          data['metadata_version']!,
          _metadataVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LibraryTrack map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LibraryTrack(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sourcePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_path'],
      )!,
      comparisonPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comparison_path'],
      )!,
      sourceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_key'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      artist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist'],
      ),
      album: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album'],
      ),
      artwork: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}artwork'],
      ),
      artworkId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}artwork_id'],
      ),
      lastSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_seen_at'],
      ),
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      ),
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified_at'],
      ),
      scanGeneration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scan_generation'],
      )!,
      discNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}disc_number'],
      ),
      trackNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_number'],
      ),
      metadataVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}metadata_version'],
      )!,
    );
  }

  @override
  $LibraryTracksTable createAlias(String alias) {
    return $LibraryTracksTable(attachedDatabase, alias);
  }
}

class LibraryTrack extends DataClass implements Insertable<LibraryTrack> {
  final int id;
  final String sourcePath;
  final String comparisonPath;
  final String sourceKey;
  final String? title;
  final String? artist;
  final String? album;
  final Uint8List? artwork;
  final int? artworkId;
  final DateTime? lastSeenAt;
  final int? fileSize;
  final DateTime? modifiedAt;
  final int scanGeneration;
  final int? discNumber;
  final int? trackNumber;
  final int metadataVersion;
  const LibraryTrack({
    required this.id,
    required this.sourcePath,
    required this.comparisonPath,
    required this.sourceKey,
    this.title,
    this.artist,
    this.album,
    this.artwork,
    this.artworkId,
    this.lastSeenAt,
    this.fileSize,
    this.modifiedAt,
    required this.scanGeneration,
    this.discNumber,
    this.trackNumber,
    required this.metadataVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['source_path'] = Variable<String>(sourcePath);
    map['comparison_path'] = Variable<String>(comparisonPath);
    map['source_key'] = Variable<String>(sourceKey);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || artist != null) {
      map['artist'] = Variable<String>(artist);
    }
    if (!nullToAbsent || album != null) {
      map['album'] = Variable<String>(album);
    }
    if (!nullToAbsent || artwork != null) {
      map['artwork'] = Variable<Uint8List>(artwork);
    }
    if (!nullToAbsent || artworkId != null) {
      map['artwork_id'] = Variable<int>(artworkId);
    }
    if (!nullToAbsent || lastSeenAt != null) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt);
    }
    if (!nullToAbsent || fileSize != null) {
      map['file_size'] = Variable<int>(fileSize);
    }
    if (!nullToAbsent || modifiedAt != null) {
      map['modified_at'] = Variable<DateTime>(modifiedAt);
    }
    map['scan_generation'] = Variable<int>(scanGeneration);
    if (!nullToAbsent || discNumber != null) {
      map['disc_number'] = Variable<int>(discNumber);
    }
    if (!nullToAbsent || trackNumber != null) {
      map['track_number'] = Variable<int>(trackNumber);
    }
    map['metadata_version'] = Variable<int>(metadataVersion);
    return map;
  }

  LibraryTracksCompanion toCompanion(bool nullToAbsent) {
    return LibraryTracksCompanion(
      id: Value(id),
      sourcePath: Value(sourcePath),
      comparisonPath: Value(comparisonPath),
      sourceKey: Value(sourceKey),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      artist: artist == null && nullToAbsent
          ? const Value.absent()
          : Value(artist),
      album: album == null && nullToAbsent
          ? const Value.absent()
          : Value(album),
      artwork: artwork == null && nullToAbsent
          ? const Value.absent()
          : Value(artwork),
      artworkId: artworkId == null && nullToAbsent
          ? const Value.absent()
          : Value(artworkId),
      lastSeenAt: lastSeenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeenAt),
      fileSize: fileSize == null && nullToAbsent
          ? const Value.absent()
          : Value(fileSize),
      modifiedAt: modifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(modifiedAt),
      scanGeneration: Value(scanGeneration),
      discNumber: discNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(discNumber),
      trackNumber: trackNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(trackNumber),
      metadataVersion: Value(metadataVersion),
    );
  }

  factory LibraryTrack.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LibraryTrack(
      id: serializer.fromJson<int>(json['id']),
      sourcePath: serializer.fromJson<String>(json['sourcePath']),
      comparisonPath: serializer.fromJson<String>(json['comparisonPath']),
      sourceKey: serializer.fromJson<String>(json['sourceKey']),
      title: serializer.fromJson<String?>(json['title']),
      artist: serializer.fromJson<String?>(json['artist']),
      album: serializer.fromJson<String?>(json['album']),
      artwork: serializer.fromJson<Uint8List?>(json['artwork']),
      artworkId: serializer.fromJson<int?>(json['artworkId']),
      lastSeenAt: serializer.fromJson<DateTime?>(json['lastSeenAt']),
      fileSize: serializer.fromJson<int?>(json['fileSize']),
      modifiedAt: serializer.fromJson<DateTime?>(json['modifiedAt']),
      scanGeneration: serializer.fromJson<int>(json['scanGeneration']),
      discNumber: serializer.fromJson<int?>(json['discNumber']),
      trackNumber: serializer.fromJson<int?>(json['trackNumber']),
      metadataVersion: serializer.fromJson<int>(json['metadataVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sourcePath': serializer.toJson<String>(sourcePath),
      'comparisonPath': serializer.toJson<String>(comparisonPath),
      'sourceKey': serializer.toJson<String>(sourceKey),
      'title': serializer.toJson<String?>(title),
      'artist': serializer.toJson<String?>(artist),
      'album': serializer.toJson<String?>(album),
      'artwork': serializer.toJson<Uint8List?>(artwork),
      'artworkId': serializer.toJson<int?>(artworkId),
      'lastSeenAt': serializer.toJson<DateTime?>(lastSeenAt),
      'fileSize': serializer.toJson<int?>(fileSize),
      'modifiedAt': serializer.toJson<DateTime?>(modifiedAt),
      'scanGeneration': serializer.toJson<int>(scanGeneration),
      'discNumber': serializer.toJson<int?>(discNumber),
      'trackNumber': serializer.toJson<int?>(trackNumber),
      'metadataVersion': serializer.toJson<int>(metadataVersion),
    };
  }

  LibraryTrack copyWith({
    int? id,
    String? sourcePath,
    String? comparisonPath,
    String? sourceKey,
    Value<String?> title = const Value.absent(),
    Value<String?> artist = const Value.absent(),
    Value<String?> album = const Value.absent(),
    Value<Uint8List?> artwork = const Value.absent(),
    Value<int?> artworkId = const Value.absent(),
    Value<DateTime?> lastSeenAt = const Value.absent(),
    Value<int?> fileSize = const Value.absent(),
    Value<DateTime?> modifiedAt = const Value.absent(),
    int? scanGeneration,
    Value<int?> discNumber = const Value.absent(),
    Value<int?> trackNumber = const Value.absent(),
    int? metadataVersion,
  }) => LibraryTrack(
    id: id ?? this.id,
    sourcePath: sourcePath ?? this.sourcePath,
    comparisonPath: comparisonPath ?? this.comparisonPath,
    sourceKey: sourceKey ?? this.sourceKey,
    title: title.present ? title.value : this.title,
    artist: artist.present ? artist.value : this.artist,
    album: album.present ? album.value : this.album,
    artwork: artwork.present ? artwork.value : this.artwork,
    artworkId: artworkId.present ? artworkId.value : this.artworkId,
    lastSeenAt: lastSeenAt.present ? lastSeenAt.value : this.lastSeenAt,
    fileSize: fileSize.present ? fileSize.value : this.fileSize,
    modifiedAt: modifiedAt.present ? modifiedAt.value : this.modifiedAt,
    scanGeneration: scanGeneration ?? this.scanGeneration,
    discNumber: discNumber.present ? discNumber.value : this.discNumber,
    trackNumber: trackNumber.present ? trackNumber.value : this.trackNumber,
    metadataVersion: metadataVersion ?? this.metadataVersion,
  );
  LibraryTrack copyWithCompanion(LibraryTracksCompanion data) {
    return LibraryTrack(
      id: data.id.present ? data.id.value : this.id,
      sourcePath: data.sourcePath.present
          ? data.sourcePath.value
          : this.sourcePath,
      comparisonPath: data.comparisonPath.present
          ? data.comparisonPath.value
          : this.comparisonPath,
      sourceKey: data.sourceKey.present ? data.sourceKey.value : this.sourceKey,
      title: data.title.present ? data.title.value : this.title,
      artist: data.artist.present ? data.artist.value : this.artist,
      album: data.album.present ? data.album.value : this.album,
      artwork: data.artwork.present ? data.artwork.value : this.artwork,
      artworkId: data.artworkId.present ? data.artworkId.value : this.artworkId,
      lastSeenAt: data.lastSeenAt.present
          ? data.lastSeenAt.value
          : this.lastSeenAt,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      scanGeneration: data.scanGeneration.present
          ? data.scanGeneration.value
          : this.scanGeneration,
      discNumber: data.discNumber.present
          ? data.discNumber.value
          : this.discNumber,
      trackNumber: data.trackNumber.present
          ? data.trackNumber.value
          : this.trackNumber,
      metadataVersion: data.metadataVersion.present
          ? data.metadataVersion.value
          : this.metadataVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LibraryTrack(')
          ..write('id: $id, ')
          ..write('sourcePath: $sourcePath, ')
          ..write('comparisonPath: $comparisonPath, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('artwork: $artwork, ')
          ..write('artworkId: $artworkId, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('fileSize: $fileSize, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('scanGeneration: $scanGeneration, ')
          ..write('discNumber: $discNumber, ')
          ..write('trackNumber: $trackNumber, ')
          ..write('metadataVersion: $metadataVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourcePath,
    comparisonPath,
    sourceKey,
    title,
    artist,
    album,
    $driftBlobEquality.hash(artwork),
    artworkId,
    lastSeenAt,
    fileSize,
    modifiedAt,
    scanGeneration,
    discNumber,
    trackNumber,
    metadataVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibraryTrack &&
          other.id == this.id &&
          other.sourcePath == this.sourcePath &&
          other.comparisonPath == this.comparisonPath &&
          other.sourceKey == this.sourceKey &&
          other.title == this.title &&
          other.artist == this.artist &&
          other.album == this.album &&
          $driftBlobEquality.equals(other.artwork, this.artwork) &&
          other.artworkId == this.artworkId &&
          other.lastSeenAt == this.lastSeenAt &&
          other.fileSize == this.fileSize &&
          other.modifiedAt == this.modifiedAt &&
          other.scanGeneration == this.scanGeneration &&
          other.discNumber == this.discNumber &&
          other.trackNumber == this.trackNumber &&
          other.metadataVersion == this.metadataVersion);
}

class LibraryTracksCompanion extends UpdateCompanion<LibraryTrack> {
  final Value<int> id;
  final Value<String> sourcePath;
  final Value<String> comparisonPath;
  final Value<String> sourceKey;
  final Value<String?> title;
  final Value<String?> artist;
  final Value<String?> album;
  final Value<Uint8List?> artwork;
  final Value<int?> artworkId;
  final Value<DateTime?> lastSeenAt;
  final Value<int?> fileSize;
  final Value<DateTime?> modifiedAt;
  final Value<int> scanGeneration;
  final Value<int?> discNumber;
  final Value<int?> trackNumber;
  final Value<int> metadataVersion;
  const LibraryTracksCompanion({
    this.id = const Value.absent(),
    this.sourcePath = const Value.absent(),
    this.comparisonPath = const Value.absent(),
    this.sourceKey = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.album = const Value.absent(),
    this.artwork = const Value.absent(),
    this.artworkId = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.scanGeneration = const Value.absent(),
    this.discNumber = const Value.absent(),
    this.trackNumber = const Value.absent(),
    this.metadataVersion = const Value.absent(),
  });
  LibraryTracksCompanion.insert({
    this.id = const Value.absent(),
    required String sourcePath,
    this.comparisonPath = const Value.absent(),
    this.sourceKey = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.album = const Value.absent(),
    this.artwork = const Value.absent(),
    this.artworkId = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.scanGeneration = const Value.absent(),
    this.discNumber = const Value.absent(),
    this.trackNumber = const Value.absent(),
    this.metadataVersion = const Value.absent(),
  }) : sourcePath = Value(sourcePath);
  static Insertable<LibraryTrack> custom({
    Expression<int>? id,
    Expression<String>? sourcePath,
    Expression<String>? comparisonPath,
    Expression<String>? sourceKey,
    Expression<String>? title,
    Expression<String>? artist,
    Expression<String>? album,
    Expression<Uint8List>? artwork,
    Expression<int>? artworkId,
    Expression<DateTime>? lastSeenAt,
    Expression<int>? fileSize,
    Expression<DateTime>? modifiedAt,
    Expression<int>? scanGeneration,
    Expression<int>? discNumber,
    Expression<int>? trackNumber,
    Expression<int>? metadataVersion,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourcePath != null) 'source_path': sourcePath,
      if (comparisonPath != null) 'comparison_path': comparisonPath,
      if (sourceKey != null) 'source_key': sourceKey,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (album != null) 'album': album,
      if (artwork != null) 'artwork': artwork,
      if (artworkId != null) 'artwork_id': artworkId,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (fileSize != null) 'file_size': fileSize,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (scanGeneration != null) 'scan_generation': scanGeneration,
      if (discNumber != null) 'disc_number': discNumber,
      if (trackNumber != null) 'track_number': trackNumber,
      if (metadataVersion != null) 'metadata_version': metadataVersion,
    });
  }

  LibraryTracksCompanion copyWith({
    Value<int>? id,
    Value<String>? sourcePath,
    Value<String>? comparisonPath,
    Value<String>? sourceKey,
    Value<String?>? title,
    Value<String?>? artist,
    Value<String?>? album,
    Value<Uint8List?>? artwork,
    Value<int?>? artworkId,
    Value<DateTime?>? lastSeenAt,
    Value<int?>? fileSize,
    Value<DateTime?>? modifiedAt,
    Value<int>? scanGeneration,
    Value<int?>? discNumber,
    Value<int?>? trackNumber,
    Value<int>? metadataVersion,
  }) {
    return LibraryTracksCompanion(
      id: id ?? this.id,
      sourcePath: sourcePath ?? this.sourcePath,
      comparisonPath: comparisonPath ?? this.comparisonPath,
      sourceKey: sourceKey ?? this.sourceKey,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      artwork: artwork ?? this.artwork,
      artworkId: artworkId ?? this.artworkId,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      fileSize: fileSize ?? this.fileSize,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      scanGeneration: scanGeneration ?? this.scanGeneration,
      discNumber: discNumber ?? this.discNumber,
      trackNumber: trackNumber ?? this.trackNumber,
      metadataVersion: metadataVersion ?? this.metadataVersion,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourcePath.present) {
      map['source_path'] = Variable<String>(sourcePath.value);
    }
    if (comparisonPath.present) {
      map['comparison_path'] = Variable<String>(comparisonPath.value);
    }
    if (sourceKey.present) {
      map['source_key'] = Variable<String>(sourceKey.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (album.present) {
      map['album'] = Variable<String>(album.value);
    }
    if (artwork.present) {
      map['artwork'] = Variable<Uint8List>(artwork.value);
    }
    if (artworkId.present) {
      map['artwork_id'] = Variable<int>(artworkId.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
    }
    if (scanGeneration.present) {
      map['scan_generation'] = Variable<int>(scanGeneration.value);
    }
    if (discNumber.present) {
      map['disc_number'] = Variable<int>(discNumber.value);
    }
    if (trackNumber.present) {
      map['track_number'] = Variable<int>(trackNumber.value);
    }
    if (metadataVersion.present) {
      map['metadata_version'] = Variable<int>(metadataVersion.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LibraryTracksCompanion(')
          ..write('id: $id, ')
          ..write('sourcePath: $sourcePath, ')
          ..write('comparisonPath: $comparisonPath, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('artwork: $artwork, ')
          ..write('artworkId: $artworkId, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('fileSize: $fileSize, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('scanGeneration: $scanGeneration, ')
          ..write('discNumber: $discNumber, ')
          ..write('trackNumber: $trackNumber, ')
          ..write('metadataVersion: $metadataVersion')
          ..write(')'))
        .toString();
  }
}

class $PlaybackQueueEntriesTable extends PlaybackQueueEntries
    with TableInfo<$PlaybackQueueEntriesTable, PlaybackQueueEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaybackQueueEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _queueIdMeta = const VerificationMeta(
    'queueId',
  );
  @override
  late final GeneratedColumn<String> queueId = GeneratedColumn<String>(
    'queue_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<int> trackId = GeneratedColumn<int>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES library_tracks (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [queueId, position, trackId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playback_queue_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaybackQueueEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('queue_id')) {
      context.handle(
        _queueIdMeta,
        queueId.isAcceptableOrUnknown(data['queue_id']!, _queueIdMeta),
      );
    } else if (isInserting) {
      context.missing(_queueIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {queueId, position};
  @override
  PlaybackQueueEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaybackQueueEntry(
      queueId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}queue_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_id'],
      )!,
    );
  }

  @override
  $PlaybackQueueEntriesTable createAlias(String alias) {
    return $PlaybackQueueEntriesTable(attachedDatabase, alias);
  }
}

class PlaybackQueueEntry extends DataClass
    implements Insertable<PlaybackQueueEntry> {
  final String queueId;
  final int position;
  final int trackId;
  const PlaybackQueueEntry({
    required this.queueId,
    required this.position,
    required this.trackId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['queue_id'] = Variable<String>(queueId);
    map['position'] = Variable<int>(position);
    map['track_id'] = Variable<int>(trackId);
    return map;
  }

  PlaybackQueueEntriesCompanion toCompanion(bool nullToAbsent) {
    return PlaybackQueueEntriesCompanion(
      queueId: Value(queueId),
      position: Value(position),
      trackId: Value(trackId),
    );
  }

  factory PlaybackQueueEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaybackQueueEntry(
      queueId: serializer.fromJson<String>(json['queueId']),
      position: serializer.fromJson<int>(json['position']),
      trackId: serializer.fromJson<int>(json['trackId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'queueId': serializer.toJson<String>(queueId),
      'position': serializer.toJson<int>(position),
      'trackId': serializer.toJson<int>(trackId),
    };
  }

  PlaybackQueueEntry copyWith({String? queueId, int? position, int? trackId}) =>
      PlaybackQueueEntry(
        queueId: queueId ?? this.queueId,
        position: position ?? this.position,
        trackId: trackId ?? this.trackId,
      );
  PlaybackQueueEntry copyWithCompanion(PlaybackQueueEntriesCompanion data) {
    return PlaybackQueueEntry(
      queueId: data.queueId.present ? data.queueId.value : this.queueId,
      position: data.position.present ? data.position.value : this.position,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackQueueEntry(')
          ..write('queueId: $queueId, ')
          ..write('position: $position, ')
          ..write('trackId: $trackId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(queueId, position, trackId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaybackQueueEntry &&
          other.queueId == this.queueId &&
          other.position == this.position &&
          other.trackId == this.trackId);
}

class PlaybackQueueEntriesCompanion
    extends UpdateCompanion<PlaybackQueueEntry> {
  final Value<String> queueId;
  final Value<int> position;
  final Value<int> trackId;
  final Value<int> rowid;
  const PlaybackQueueEntriesCompanion({
    this.queueId = const Value.absent(),
    this.position = const Value.absent(),
    this.trackId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaybackQueueEntriesCompanion.insert({
    required String queueId,
    required int position,
    required int trackId,
    this.rowid = const Value.absent(),
  }) : queueId = Value(queueId),
       position = Value(position),
       trackId = Value(trackId);
  static Insertable<PlaybackQueueEntry> custom({
    Expression<String>? queueId,
    Expression<int>? position,
    Expression<int>? trackId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (queueId != null) 'queue_id': queueId,
      if (position != null) 'position': position,
      if (trackId != null) 'track_id': trackId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaybackQueueEntriesCompanion copyWith({
    Value<String>? queueId,
    Value<int>? position,
    Value<int>? trackId,
    Value<int>? rowid,
  }) {
    return PlaybackQueueEntriesCompanion(
      queueId: queueId ?? this.queueId,
      position: position ?? this.position,
      trackId: trackId ?? this.trackId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (queueId.present) {
      map['queue_id'] = Variable<String>(queueId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<int>(trackId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackQueueEntriesCompanion(')
          ..write('queueId: $queueId, ')
          ..write('position: $position, ')
          ..write('trackId: $trackId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LibraryArtworksTable libraryArtworks = $LibraryArtworksTable(
    this,
  );
  late final $LibraryTracksTable libraryTracks = $LibraryTracksTable(this);
  late final $PlaybackQueueEntriesTable playbackQueueEntries =
      $PlaybackQueueEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    libraryArtworks,
    libraryTracks,
    playbackQueueEntries,
  ];
}

typedef $$LibraryArtworksTableCreateCompanionBuilder =
    LibraryArtworksCompanion Function({
      Value<int> id,
      required String contentHash,
      required Uint8List bytes,
    });
typedef $$LibraryArtworksTableUpdateCompanionBuilder =
    LibraryArtworksCompanion Function({
      Value<int> id,
      Value<String> contentHash,
      Value<Uint8List> bytes,
    });

final class $$LibraryArtworksTableReferences
    extends
        BaseReferences<_$AppDatabase, $LibraryArtworksTable, LibraryArtwork> {
  $$LibraryArtworksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$LibraryTracksTable, List<LibraryTrack>>
  _libraryTracksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.libraryTracks,
    aliasName: 'library_artworks__id__library_tracks__artwork_id',
  );

  $$LibraryTracksTableProcessedTableManager get libraryTracksRefs {
    final manager = $$LibraryTracksTableTableManager(
      $_db,
      $_db.libraryTracks,
    ).filter((f) => f.artworkId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_libraryTracksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LibraryArtworksTableFilterComposer
    extends Composer<_$AppDatabase, $LibraryArtworksTable> {
  $$LibraryArtworksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> libraryTracksRefs(
    Expression<bool> Function($$LibraryTracksTableFilterComposer f) f,
  ) {
    final $$LibraryTracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.libraryTracks,
      getReferencedColumn: (t) => t.artworkId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryTracksTableFilterComposer(
            $db: $db,
            $table: $db.libraryTracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LibraryArtworksTableOrderingComposer
    extends Composer<_$AppDatabase, $LibraryArtworksTable> {
  $$LibraryArtworksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LibraryArtworksTableAnnotationComposer
    extends Composer<_$AppDatabase, $LibraryArtworksTable> {
  $$LibraryArtworksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => column);

  Expression<T> libraryTracksRefs<T extends Object>(
    Expression<T> Function($$LibraryTracksTableAnnotationComposer a) f,
  ) {
    final $$LibraryTracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.libraryTracks,
      getReferencedColumn: (t) => t.artworkId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryTracksTableAnnotationComposer(
            $db: $db,
            $table: $db.libraryTracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LibraryArtworksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LibraryArtworksTable,
          LibraryArtwork,
          $$LibraryArtworksTableFilterComposer,
          $$LibraryArtworksTableOrderingComposer,
          $$LibraryArtworksTableAnnotationComposer,
          $$LibraryArtworksTableCreateCompanionBuilder,
          $$LibraryArtworksTableUpdateCompanionBuilder,
          (LibraryArtwork, $$LibraryArtworksTableReferences),
          LibraryArtwork,
          PrefetchHooks Function({bool libraryTracksRefs})
        > {
  $$LibraryArtworksTableTableManager(
    _$AppDatabase db,
    $LibraryArtworksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LibraryArtworksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LibraryArtworksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LibraryArtworksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> contentHash = const Value.absent(),
                Value<Uint8List> bytes = const Value.absent(),
              }) => LibraryArtworksCompanion(
                id: id,
                contentHash: contentHash,
                bytes: bytes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String contentHash,
                required Uint8List bytes,
              }) => LibraryArtworksCompanion.insert(
                id: id,
                contentHash: contentHash,
                bytes: bytes,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LibraryArtworksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({libraryTracksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (libraryTracksRefs) db.libraryTracks,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (libraryTracksRefs)
                    await $_getPrefetchedData<
                      LibraryArtwork,
                      $LibraryArtworksTable,
                      LibraryTrack
                    >(
                      currentTable: table,
                      referencedTable: $$LibraryArtworksTableReferences
                          ._libraryTracksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$LibraryArtworksTableReferences(
                            db,
                            table,
                            p0,
                          ).libraryTracksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.artworkId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$LibraryArtworksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LibraryArtworksTable,
      LibraryArtwork,
      $$LibraryArtworksTableFilterComposer,
      $$LibraryArtworksTableOrderingComposer,
      $$LibraryArtworksTableAnnotationComposer,
      $$LibraryArtworksTableCreateCompanionBuilder,
      $$LibraryArtworksTableUpdateCompanionBuilder,
      (LibraryArtwork, $$LibraryArtworksTableReferences),
      LibraryArtwork,
      PrefetchHooks Function({bool libraryTracksRefs})
    >;
typedef $$LibraryTracksTableCreateCompanionBuilder =
    LibraryTracksCompanion Function({
      Value<int> id,
      required String sourcePath,
      Value<String> comparisonPath,
      Value<String> sourceKey,
      Value<String?> title,
      Value<String?> artist,
      Value<String?> album,
      Value<Uint8List?> artwork,
      Value<int?> artworkId,
      Value<DateTime?> lastSeenAt,
      Value<int?> fileSize,
      Value<DateTime?> modifiedAt,
      Value<int> scanGeneration,
      Value<int?> discNumber,
      Value<int?> trackNumber,
      Value<int> metadataVersion,
    });
typedef $$LibraryTracksTableUpdateCompanionBuilder =
    LibraryTracksCompanion Function({
      Value<int> id,
      Value<String> sourcePath,
      Value<String> comparisonPath,
      Value<String> sourceKey,
      Value<String?> title,
      Value<String?> artist,
      Value<String?> album,
      Value<Uint8List?> artwork,
      Value<int?> artworkId,
      Value<DateTime?> lastSeenAt,
      Value<int?> fileSize,
      Value<DateTime?> modifiedAt,
      Value<int> scanGeneration,
      Value<int?> discNumber,
      Value<int?> trackNumber,
      Value<int> metadataVersion,
    });

final class $$LibraryTracksTableReferences
    extends BaseReferences<_$AppDatabase, $LibraryTracksTable, LibraryTrack> {
  $$LibraryTracksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LibraryArtworksTable _artworkIdTable(_$AppDatabase db) => db
      .libraryArtworks
      .createAlias('library_tracks__artwork_id__library_artworks__id');

  $$LibraryArtworksTableProcessedTableManager? get artworkId {
    final $_column = $_itemColumn<int>('artwork_id');
    if ($_column == null) return null;
    final manager = $$LibraryArtworksTableTableManager(
      $_db,
      $_db.libraryArtworks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_artworkIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $PlaybackQueueEntriesTable,
    List<PlaybackQueueEntry>
  >
  _playbackQueueEntriesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.playbackQueueEntries,
        aliasName: 'library_tracks__id__playback_queue_entries__track_id',
      );

  $$PlaybackQueueEntriesTableProcessedTableManager
  get playbackQueueEntriesRefs {
    final manager = $$PlaybackQueueEntriesTableTableManager(
      $_db,
      $_db.playbackQueueEntries,
    ).filter((f) => f.trackId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _playbackQueueEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LibraryTracksTableFilterComposer
    extends Composer<_$AppDatabase, $LibraryTracksTable> {
  $$LibraryTracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourcePath => $composableBuilder(
    column: $table.sourcePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get comparisonPath => $composableBuilder(
    column: $table.comparisonPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceKey => $composableBuilder(
    column: $table.sourceKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get artwork => $composableBuilder(
    column: $table.artwork,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scanGeneration => $composableBuilder(
    column: $table.scanGeneration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discNumber => $composableBuilder(
    column: $table.discNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trackNumber => $composableBuilder(
    column: $table.trackNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get metadataVersion => $composableBuilder(
    column: $table.metadataVersion,
    builder: (column) => ColumnFilters(column),
  );

  $$LibraryArtworksTableFilterComposer get artworkId {
    final $$LibraryArtworksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artworkId,
      referencedTable: $db.libraryArtworks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryArtworksTableFilterComposer(
            $db: $db,
            $table: $db.libraryArtworks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> playbackQueueEntriesRefs(
    Expression<bool> Function($$PlaybackQueueEntriesTableFilterComposer f) f,
  ) {
    final $$PlaybackQueueEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playbackQueueEntries,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaybackQueueEntriesTableFilterComposer(
            $db: $db,
            $table: $db.playbackQueueEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LibraryTracksTableOrderingComposer
    extends Composer<_$AppDatabase, $LibraryTracksTable> {
  $$LibraryTracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourcePath => $composableBuilder(
    column: $table.sourcePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get comparisonPath => $composableBuilder(
    column: $table.comparisonPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceKey => $composableBuilder(
    column: $table.sourceKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get artwork => $composableBuilder(
    column: $table.artwork,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scanGeneration => $composableBuilder(
    column: $table.scanGeneration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discNumber => $composableBuilder(
    column: $table.discNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trackNumber => $composableBuilder(
    column: $table.trackNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get metadataVersion => $composableBuilder(
    column: $table.metadataVersion,
    builder: (column) => ColumnOrderings(column),
  );

  $$LibraryArtworksTableOrderingComposer get artworkId {
    final $$LibraryArtworksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artworkId,
      referencedTable: $db.libraryArtworks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryArtworksTableOrderingComposer(
            $db: $db,
            $table: $db.libraryArtworks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LibraryTracksTableAnnotationComposer
    extends Composer<_$AppDatabase, $LibraryTracksTable> {
  $$LibraryTracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourcePath => $composableBuilder(
    column: $table.sourcePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get comparisonPath => $composableBuilder(
    column: $table.comparisonPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceKey =>
      $composableBuilder(column: $table.sourceKey, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get album =>
      $composableBuilder(column: $table.album, builder: (column) => column);

  GeneratedColumn<Uint8List> get artwork =>
      $composableBuilder(column: $table.artwork, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get scanGeneration => $composableBuilder(
    column: $table.scanGeneration,
    builder: (column) => column,
  );

  GeneratedColumn<int> get discNumber => $composableBuilder(
    column: $table.discNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get trackNumber => $composableBuilder(
    column: $table.trackNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get metadataVersion => $composableBuilder(
    column: $table.metadataVersion,
    builder: (column) => column,
  );

  $$LibraryArtworksTableAnnotationComposer get artworkId {
    final $$LibraryArtworksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artworkId,
      referencedTable: $db.libraryArtworks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryArtworksTableAnnotationComposer(
            $db: $db,
            $table: $db.libraryArtworks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> playbackQueueEntriesRefs<T extends Object>(
    Expression<T> Function($$PlaybackQueueEntriesTableAnnotationComposer a) f,
  ) {
    final $$PlaybackQueueEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.playbackQueueEntries,
          getReferencedColumn: (t) => t.trackId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PlaybackQueueEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.playbackQueueEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$LibraryTracksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LibraryTracksTable,
          LibraryTrack,
          $$LibraryTracksTableFilterComposer,
          $$LibraryTracksTableOrderingComposer,
          $$LibraryTracksTableAnnotationComposer,
          $$LibraryTracksTableCreateCompanionBuilder,
          $$LibraryTracksTableUpdateCompanionBuilder,
          (LibraryTrack, $$LibraryTracksTableReferences),
          LibraryTrack,
          PrefetchHooks Function({
            bool artworkId,
            bool playbackQueueEntriesRefs,
          })
        > {
  $$LibraryTracksTableTableManager(_$AppDatabase db, $LibraryTracksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LibraryTracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LibraryTracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LibraryTracksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sourcePath = const Value.absent(),
                Value<String> comparisonPath = const Value.absent(),
                Value<String> sourceKey = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> artist = const Value.absent(),
                Value<String?> album = const Value.absent(),
                Value<Uint8List?> artwork = const Value.absent(),
                Value<int?> artworkId = const Value.absent(),
                Value<DateTime?> lastSeenAt = const Value.absent(),
                Value<int?> fileSize = const Value.absent(),
                Value<DateTime?> modifiedAt = const Value.absent(),
                Value<int> scanGeneration = const Value.absent(),
                Value<int?> discNumber = const Value.absent(),
                Value<int?> trackNumber = const Value.absent(),
                Value<int> metadataVersion = const Value.absent(),
              }) => LibraryTracksCompanion(
                id: id,
                sourcePath: sourcePath,
                comparisonPath: comparisonPath,
                sourceKey: sourceKey,
                title: title,
                artist: artist,
                album: album,
                artwork: artwork,
                artworkId: artworkId,
                lastSeenAt: lastSeenAt,
                fileSize: fileSize,
                modifiedAt: modifiedAt,
                scanGeneration: scanGeneration,
                discNumber: discNumber,
                trackNumber: trackNumber,
                metadataVersion: metadataVersion,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sourcePath,
                Value<String> comparisonPath = const Value.absent(),
                Value<String> sourceKey = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> artist = const Value.absent(),
                Value<String?> album = const Value.absent(),
                Value<Uint8List?> artwork = const Value.absent(),
                Value<int?> artworkId = const Value.absent(),
                Value<DateTime?> lastSeenAt = const Value.absent(),
                Value<int?> fileSize = const Value.absent(),
                Value<DateTime?> modifiedAt = const Value.absent(),
                Value<int> scanGeneration = const Value.absent(),
                Value<int?> discNumber = const Value.absent(),
                Value<int?> trackNumber = const Value.absent(),
                Value<int> metadataVersion = const Value.absent(),
              }) => LibraryTracksCompanion.insert(
                id: id,
                sourcePath: sourcePath,
                comparisonPath: comparisonPath,
                sourceKey: sourceKey,
                title: title,
                artist: artist,
                album: album,
                artwork: artwork,
                artworkId: artworkId,
                lastSeenAt: lastSeenAt,
                fileSize: fileSize,
                modifiedAt: modifiedAt,
                scanGeneration: scanGeneration,
                discNumber: discNumber,
                trackNumber: trackNumber,
                metadataVersion: metadataVersion,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LibraryTracksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({artworkId = false, playbackQueueEntriesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (playbackQueueEntriesRefs) db.playbackQueueEntries,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (artworkId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.artworkId,
                                    referencedTable:
                                        $$LibraryTracksTableReferences
                                            ._artworkIdTable(db),
                                    referencedColumn:
                                        $$LibraryTracksTableReferences
                                            ._artworkIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (playbackQueueEntriesRefs)
                        await $_getPrefetchedData<
                          LibraryTrack,
                          $LibraryTracksTable,
                          PlaybackQueueEntry
                        >(
                          currentTable: table,
                          referencedTable: $$LibraryTracksTableReferences
                              ._playbackQueueEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LibraryTracksTableReferences(
                                db,
                                table,
                                p0,
                              ).playbackQueueEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.trackId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LibraryTracksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LibraryTracksTable,
      LibraryTrack,
      $$LibraryTracksTableFilterComposer,
      $$LibraryTracksTableOrderingComposer,
      $$LibraryTracksTableAnnotationComposer,
      $$LibraryTracksTableCreateCompanionBuilder,
      $$LibraryTracksTableUpdateCompanionBuilder,
      (LibraryTrack, $$LibraryTracksTableReferences),
      LibraryTrack,
      PrefetchHooks Function({bool artworkId, bool playbackQueueEntriesRefs})
    >;
typedef $$PlaybackQueueEntriesTableCreateCompanionBuilder =
    PlaybackQueueEntriesCompanion Function({
      required String queueId,
      required int position,
      required int trackId,
      Value<int> rowid,
    });
typedef $$PlaybackQueueEntriesTableUpdateCompanionBuilder =
    PlaybackQueueEntriesCompanion Function({
      Value<String> queueId,
      Value<int> position,
      Value<int> trackId,
      Value<int> rowid,
    });

final class $$PlaybackQueueEntriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PlaybackQueueEntriesTable,
          PlaybackQueueEntry
        > {
  $$PlaybackQueueEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LibraryTracksTable _trackIdTable(_$AppDatabase db) => db.libraryTracks
      .createAlias('playback_queue_entries__track_id__library_tracks__id');

  $$LibraryTracksTableProcessedTableManager get trackId {
    final $_column = $_itemColumn<int>('track_id')!;

    final manager = $$LibraryTracksTableTableManager(
      $_db,
      $_db.libraryTracks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlaybackQueueEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $PlaybackQueueEntriesTable> {
  $$PlaybackQueueEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get queueId => $composableBuilder(
    column: $table.queueId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$LibraryTracksTableFilterComposer get trackId {
    final $$LibraryTracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.libraryTracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryTracksTableFilterComposer(
            $db: $db,
            $table: $db.libraryTracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaybackQueueEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaybackQueueEntriesTable> {
  $$PlaybackQueueEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get queueId => $composableBuilder(
    column: $table.queueId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$LibraryTracksTableOrderingComposer get trackId {
    final $$LibraryTracksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.libraryTracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryTracksTableOrderingComposer(
            $db: $db,
            $table: $db.libraryTracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaybackQueueEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaybackQueueEntriesTable> {
  $$PlaybackQueueEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get queueId =>
      $composableBuilder(column: $table.queueId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$LibraryTracksTableAnnotationComposer get trackId {
    final $$LibraryTracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.libraryTracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryTracksTableAnnotationComposer(
            $db: $db,
            $table: $db.libraryTracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaybackQueueEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaybackQueueEntriesTable,
          PlaybackQueueEntry,
          $$PlaybackQueueEntriesTableFilterComposer,
          $$PlaybackQueueEntriesTableOrderingComposer,
          $$PlaybackQueueEntriesTableAnnotationComposer,
          $$PlaybackQueueEntriesTableCreateCompanionBuilder,
          $$PlaybackQueueEntriesTableUpdateCompanionBuilder,
          (PlaybackQueueEntry, $$PlaybackQueueEntriesTableReferences),
          PlaybackQueueEntry,
          PrefetchHooks Function({bool trackId})
        > {
  $$PlaybackQueueEntriesTableTableManager(
    _$AppDatabase db,
    $PlaybackQueueEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaybackQueueEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaybackQueueEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PlaybackQueueEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> queueId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> trackId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaybackQueueEntriesCompanion(
                queueId: queueId,
                position: position,
                trackId: trackId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String queueId,
                required int position,
                required int trackId,
                Value<int> rowid = const Value.absent(),
              }) => PlaybackQueueEntriesCompanion.insert(
                queueId: queueId,
                position: position,
                trackId: trackId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlaybackQueueEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({trackId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (trackId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.trackId,
                                referencedTable:
                                    $$PlaybackQueueEntriesTableReferences
                                        ._trackIdTable(db),
                                referencedColumn:
                                    $$PlaybackQueueEntriesTableReferences
                                        ._trackIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlaybackQueueEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaybackQueueEntriesTable,
      PlaybackQueueEntry,
      $$PlaybackQueueEntriesTableFilterComposer,
      $$PlaybackQueueEntriesTableOrderingComposer,
      $$PlaybackQueueEntriesTableAnnotationComposer,
      $$PlaybackQueueEntriesTableCreateCompanionBuilder,
      $$PlaybackQueueEntriesTableUpdateCompanionBuilder,
      (PlaybackQueueEntry, $$PlaybackQueueEntriesTableReferences),
      PlaybackQueueEntry,
      PrefetchHooks Function({bool trackId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LibraryArtworksTableTableManager get libraryArtworks =>
      $$LibraryArtworksTableTableManager(_db, _db.libraryArtworks);
  $$LibraryTracksTableTableManager get libraryTracks =>
      $$LibraryTracksTableTableManager(_db, _db.libraryTracks);
  $$PlaybackQueueEntriesTableTableManager get playbackQueueEntries =>
      $$PlaybackQueueEntriesTableTableManager(_db, _db.playbackQueueEntries);
}
