import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class LibraryTracks extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get sourcePath => text().unique()();

  TextColumn get title => text().nullable()();

  TextColumn get artist => text().nullable()();

  TextColumn get album => text().nullable()();

  DateTimeColumn get lastSeenAt => dateTime().nullable()();
}

@DriftDatabase(tables: [LibraryTracks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'music_base'));

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;
}
