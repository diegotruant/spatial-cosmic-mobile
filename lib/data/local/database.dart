import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

part 'database.g.dart';

// Tables
class Workouts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sport => text().withDefault(const Constant('bike'))();
  DateTimeColumn get startTime => dateTime()();
  IntColumn get duration => integer().withDefault(const Constant(0))(); // seconds
  IntColumn get avgPower => integer().nullable()();
  IntColumn get avgHr => integer().nullable()();
  RealColumn get totalKj => real().nullable()();
  RealColumn get normalizedPower => real().nullable()();
}

class BikeSamples extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutId => integer().references(Workouts, #id)();
  DateTimeColumn get timestamp => dateTime()();
  IntColumn get heartRate => integer().nullable()();
  IntColumn get power => integer().nullable()();
  IntColumn get cadence => integer().nullable()();
  RealColumn get speed => real().nullable()(); // m/s
}

class RrIntervals extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutId => integer().references(Workouts, #id)();
  DateTimeColumn get timestamp => dateTime()(); // approximate time of interval
  IntColumn get rrMs => integer()(); // raw RR in ms
}

@DriftDatabase(tables: [Workouts, BikeSamples, RrIntervals])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // DAOs
  Future<int> createWorkout(WorkoutsCompanion entry) {
    return into(workouts).insert(entry);
  }

  Future<void> updateWorkout(int id, WorkoutsCompanion entry) {
    return (update(workouts)..where((t) => t.id.equals(id))).write(entry);
  }

  Future<void> insertSample(BikeSamplesCompanion sample) {
    return into(bikeSamples).insert(sample);
  }

  Future<void> insertRrInterval(RrIntervalsCompanion interval) {
    return into(rrIntervals).insert(interval);
  }

  Future<List<BikeSamplesData>> getSamplesForWorkout(int workoutId) {
    return (select(bikeSamples)..where((t) => t.workoutId.equals(workoutId))
      ..orderBy([(t) => OrderingTerm(expression: t.timestamp)]))
        .get();
  }

  Future<List<RrIntervalsData>> getRrForWorkout(int workoutId) {
    return (select(rrIntervals)..where((t) => t.workoutId.equals(workoutId))
      ..orderBy([(t) => OrderingTerm(expression: t.timestamp)]))
        .get();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    
    // Also work around limitations on old Android versions
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(file);
  });
}
