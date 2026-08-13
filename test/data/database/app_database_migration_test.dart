import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_base/data/database/app_database.dart';

void main() {
  test('repairs a v5 database that already has comparison_path', () async {
    final directory = await Directory.systemTemp.createTemp(
      'music-base-migration-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/music_base.sqlite');

    final initial = AppDatabase.forTesting(NativeDatabase(file));
    await initial
        .into(initial.libraryTracks)
        .insert(
          LibraryTracksCompanion.insert(
            sourcePath: r'X:\SampleLibrary\Track.FLAC',
            sourceKey: const Value(r'X:\SampleLibrary'),
          ),
        );
    await initial.customStatement(
      "UPDATE library_tracks SET comparison_path = ''",
    );
    await initial.customStatement('PRAGMA user_version = 5');
    await initial.close();

    final migrated = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(migrated.close);
    final track = await migrated.select(migrated.libraryTracks).getSingle();
    final version = await migrated
        .customSelect('PRAGMA user_version')
        .getSingle();

    expect(version.read<int>('user_version'), 7);
    expect(track.comparisonPath, 'x:/samplelibrary/track.flac');
  });

  test('rebuilds encoded SMB comparison paths when upgrading v6', () async {
    final directory = await Directory.systemTemp.createTemp(
      'music-base-smb-migration-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/music_base.sqlite');

    final initial = AppDatabase.forTesting(NativeDatabase(file));
    const sourcePath =
        'smb://media.example.test/audio-share/Audio/'
        '%E3%82%B5%E3%83%B3%E3%83%97%E3%83%AB/Collection/Track.flac';
    await initial
        .into(initial.libraryTracks)
        .insert(
          LibraryTracksCompanion.insert(
            sourcePath: sourcePath,
            comparisonPath: const Value(sourcePath),
            sourceKey: const Value('smb://media.example.test/audio-share'),
          ),
        );
    await initial.customStatement('PRAGMA user_version = 6');
    await initial.close();

    final migrated = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(migrated.close);
    final track = await migrated.select(migrated.libraryTracks).getSingle();

    expect(
      track.comparisonPath,
      'smb://media.example.test/audio-share/Audio/サンプル/Collection/Track.flac',
    );
  });
}
