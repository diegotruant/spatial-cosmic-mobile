// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $WorkoutsTable extends Workouts with TableInfo<$WorkoutsTable, Workout> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _sportMeta = const VerificationMeta('sport');
  @override
  late final GeneratedColumn<String> sport = GeneratedColumn<String>(
      'sport', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('bike'));
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
      'start_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _durationMeta =
      const VerificationMeta('duration');
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
      'duration', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _avgPowerMeta =
      const VerificationMeta('avgPower');
  @override
  late final GeneratedColumn<int> avgPower = GeneratedColumn<int>(
      'avg_power', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _avgHrMeta = const VerificationMeta('avgHr');
  @override
  late final GeneratedColumn<int> avgHr = GeneratedColumn<int>(
      'avg_hr', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _totalKjMeta =
      const VerificationMeta('totalKj');
  @override
  late final GeneratedColumn<double> totalKj = GeneratedColumn<double>(
      'total_kj', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _normalizedPowerMeta =
      const VerificationMeta('normalizedPower');
  @override
  late final GeneratedColumn<double> normalizedPower = GeneratedColumn<double>(
      'normalized_power', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        sport,
        startTime,
        duration,
        avgPower,
        avgHr,
        totalKj,
        normalizedPower
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workouts';
  @override
  VerificationContext validateIntegrity(Insertable<Workout> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sport')) {
      context.handle(
          _sportMeta, sport.isAcceptableOrUnknown(data['sport']!, _sportMeta));
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('duration')) {
      context.handle(_durationMeta,
          duration.isAcceptableOrUnknown(data['duration']!, _durationMeta));
    }
    if (data.containsKey('avg_power')) {
      context.handle(_avgPowerMeta,
          avgPower.isAcceptableOrUnknown(data['avg_power']!, _avgPowerMeta));
    }
    if (data.containsKey('avg_hr')) {
      context.handle(
          _avgHrMeta, avgHr.isAcceptableOrUnknown(data['avg_hr']!, _avgHrMeta));
    }
    if (data.containsKey('total_kj')) {
      context.handle(_totalKjMeta,
          totalKj.isAcceptableOrUnknown(data['total_kj']!, _totalKjMeta));
    }
    if (data.containsKey('normalized_power')) {
      context.handle(
          _normalizedPowerMeta,
          normalizedPower.isAcceptableOrUnknown(
              data['normalized_power']!, _normalizedPowerMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Workout map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Workout(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      sport: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sport'])!,
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_time'])!,
      duration: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration'])!,
      avgPower: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}avg_power']),
      avgHr: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}avg_hr']),
      totalKj: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_kj']),
      normalizedPower: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}normalized_power']),
    );
  }

  @override
  $WorkoutsTable createAlias(String alias) {
    return $WorkoutsTable(attachedDatabase, alias);
  }
}

class Workout extends DataClass implements Insertable<Workout> {
  final int id;
  final String sport;
  final DateTime startTime;
  final int duration;
  final int? avgPower;
  final int? avgHr;
  final double? totalKj;
  final double? normalizedPower;
  const Workout(
      {required this.id,
      required this.sport,
      required this.startTime,
      required this.duration,
      this.avgPower,
      this.avgHr,
      this.totalKj,
      this.normalizedPower});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sport'] = Variable<String>(sport);
    map['start_time'] = Variable<DateTime>(startTime);
    map['duration'] = Variable<int>(duration);
    if (!nullToAbsent || avgPower != null) {
      map['avg_power'] = Variable<int>(avgPower);
    }
    if (!nullToAbsent || avgHr != null) {
      map['avg_hr'] = Variable<int>(avgHr);
    }
    if (!nullToAbsent || totalKj != null) {
      map['total_kj'] = Variable<double>(totalKj);
    }
    if (!nullToAbsent || normalizedPower != null) {
      map['normalized_power'] = Variable<double>(normalizedPower);
    }
    return map;
  }

  WorkoutsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutsCompanion(
      id: Value(id),
      sport: Value(sport),
      startTime: Value(startTime),
      duration: Value(duration),
      avgPower: avgPower == null && nullToAbsent
          ? const Value.absent()
          : Value(avgPower),
      avgHr:
          avgHr == null && nullToAbsent ? const Value.absent() : Value(avgHr),
      totalKj: totalKj == null && nullToAbsent
          ? const Value.absent()
          : Value(totalKj),
      normalizedPower: normalizedPower == null && nullToAbsent
          ? const Value.absent()
          : Value(normalizedPower),
    );
  }

  factory Workout.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Workout(
      id: serializer.fromJson<int>(json['id']),
      sport: serializer.fromJson<String>(json['sport']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      duration: serializer.fromJson<int>(json['duration']),
      avgPower: serializer.fromJson<int?>(json['avgPower']),
      avgHr: serializer.fromJson<int?>(json['avgHr']),
      totalKj: serializer.fromJson<double?>(json['totalKj']),
      normalizedPower: serializer.fromJson<double?>(json['normalizedPower']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sport': serializer.toJson<String>(sport),
      'startTime': serializer.toJson<DateTime>(startTime),
      'duration': serializer.toJson<int>(duration),
      'avgPower': serializer.toJson<int?>(avgPower),
      'avgHr': serializer.toJson<int?>(avgHr),
      'totalKj': serializer.toJson<double?>(totalKj),
      'normalizedPower': serializer.toJson<double?>(normalizedPower),
    };
  }

  Workout copyWith(
          {int? id,
          String? sport,
          DateTime? startTime,
          int? duration,
          Value<int?> avgPower = const Value.absent(),
          Value<int?> avgHr = const Value.absent(),
          Value<double?> totalKj = const Value.absent(),
          Value<double?> normalizedPower = const Value.absent()}) =>
      Workout(
        id: id ?? this.id,
        sport: sport ?? this.sport,
        startTime: startTime ?? this.startTime,
        duration: duration ?? this.duration,
        avgPower: avgPower.present ? avgPower.value : this.avgPower,
        avgHr: avgHr.present ? avgHr.value : this.avgHr,
        totalKj: totalKj.present ? totalKj.value : this.totalKj,
        normalizedPower: normalizedPower.present
            ? normalizedPower.value
            : this.normalizedPower,
      );
  Workout copyWithCompanion(WorkoutsCompanion data) {
    return Workout(
      id: data.id.present ? data.id.value : this.id,
      sport: data.sport.present ? data.sport.value : this.sport,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      duration: data.duration.present ? data.duration.value : this.duration,
      avgPower: data.avgPower.present ? data.avgPower.value : this.avgPower,
      avgHr: data.avgHr.present ? data.avgHr.value : this.avgHr,
      totalKj: data.totalKj.present ? data.totalKj.value : this.totalKj,
      normalizedPower: data.normalizedPower.present
          ? data.normalizedPower.value
          : this.normalizedPower,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Workout(')
          ..write('id: $id, ')
          ..write('sport: $sport, ')
          ..write('startTime: $startTime, ')
          ..write('duration: $duration, ')
          ..write('avgPower: $avgPower, ')
          ..write('avgHr: $avgHr, ')
          ..write('totalKj: $totalKj, ')
          ..write('normalizedPower: $normalizedPower')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sport, startTime, duration, avgPower,
      avgHr, totalKj, normalizedPower);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Workout &&
          other.id == this.id &&
          other.sport == this.sport &&
          other.startTime == this.startTime &&
          other.duration == this.duration &&
          other.avgPower == this.avgPower &&
          other.avgHr == this.avgHr &&
          other.totalKj == this.totalKj &&
          other.normalizedPower == this.normalizedPower);
}

class WorkoutsCompanion extends UpdateCompanion<Workout> {
  final Value<int> id;
  final Value<String> sport;
  final Value<DateTime> startTime;
  final Value<int> duration;
  final Value<int?> avgPower;
  final Value<int?> avgHr;
  final Value<double?> totalKj;
  final Value<double?> normalizedPower;
  const WorkoutsCompanion({
    this.id = const Value.absent(),
    this.sport = const Value.absent(),
    this.startTime = const Value.absent(),
    this.duration = const Value.absent(),
    this.avgPower = const Value.absent(),
    this.avgHr = const Value.absent(),
    this.totalKj = const Value.absent(),
    this.normalizedPower = const Value.absent(),
  });
  WorkoutsCompanion.insert({
    this.id = const Value.absent(),
    this.sport = const Value.absent(),
    required DateTime startTime,
    this.duration = const Value.absent(),
    this.avgPower = const Value.absent(),
    this.avgHr = const Value.absent(),
    this.totalKj = const Value.absent(),
    this.normalizedPower = const Value.absent(),
  }) : startTime = Value(startTime);
  static Insertable<Workout> custom({
    Expression<int>? id,
    Expression<String>? sport,
    Expression<DateTime>? startTime,
    Expression<int>? duration,
    Expression<int>? avgPower,
    Expression<int>? avgHr,
    Expression<double>? totalKj,
    Expression<double>? normalizedPower,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sport != null) 'sport': sport,
      if (startTime != null) 'start_time': startTime,
      if (duration != null) 'duration': duration,
      if (avgPower != null) 'avg_power': avgPower,
      if (avgHr != null) 'avg_hr': avgHr,
      if (totalKj != null) 'total_kj': totalKj,
      if (normalizedPower != null) 'normalized_power': normalizedPower,
    });
  }

  WorkoutsCompanion copyWith(
      {Value<int>? id,
      Value<String>? sport,
      Value<DateTime>? startTime,
      Value<int>? duration,
      Value<int?>? avgPower,
      Value<int?>? avgHr,
      Value<double?>? totalKj,
      Value<double?>? normalizedPower}) {
    return WorkoutsCompanion(
      id: id ?? this.id,
      sport: sport ?? this.sport,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      avgPower: avgPower ?? this.avgPower,
      avgHr: avgHr ?? this.avgHr,
      totalKj: totalKj ?? this.totalKj,
      normalizedPower: normalizedPower ?? this.normalizedPower,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sport.present) {
      map['sport'] = Variable<String>(sport.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (avgPower.present) {
      map['avg_power'] = Variable<int>(avgPower.value);
    }
    if (avgHr.present) {
      map['avg_hr'] = Variable<int>(avgHr.value);
    }
    if (totalKj.present) {
      map['total_kj'] = Variable<double>(totalKj.value);
    }
    if (normalizedPower.present) {
      map['normalized_power'] = Variable<double>(normalizedPower.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutsCompanion(')
          ..write('id: $id, ')
          ..write('sport: $sport, ')
          ..write('startTime: $startTime, ')
          ..write('duration: $duration, ')
          ..write('avgPower: $avgPower, ')
          ..write('avgHr: $avgHr, ')
          ..write('totalKj: $totalKj, ')
          ..write('normalizedPower: $normalizedPower')
          ..write(')'))
        .toString();
  }
}

class $BikeSamplesTable extends BikeSamples
    with TableInfo<$BikeSamplesTable, BikeSample> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BikeSamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _workoutIdMeta =
      const VerificationMeta('workoutId');
  @override
  late final GeneratedColumn<int> workoutId = GeneratedColumn<int>(
      'workout_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES workouts (id)'));
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _heartRateMeta =
      const VerificationMeta('heartRate');
  @override
  late final GeneratedColumn<int> heartRate = GeneratedColumn<int>(
      'heart_rate', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _powerMeta = const VerificationMeta('power');
  @override
  late final GeneratedColumn<int> power = GeneratedColumn<int>(
      'power', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _cadenceMeta =
      const VerificationMeta('cadence');
  @override
  late final GeneratedColumn<int> cadence = GeneratedColumn<int>(
      'cadence', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _speedMeta = const VerificationMeta('speed');
  @override
  late final GeneratedColumn<double> speed = GeneratedColumn<double>(
      'speed', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, workoutId, timestamp, heartRate, power, cadence, speed];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bike_samples';
  @override
  VerificationContext validateIntegrity(Insertable<BikeSample> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('workout_id')) {
      context.handle(_workoutIdMeta,
          workoutId.isAcceptableOrUnknown(data['workout_id']!, _workoutIdMeta));
    } else if (isInserting) {
      context.missing(_workoutIdMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('heart_rate')) {
      context.handle(_heartRateMeta,
          heartRate.isAcceptableOrUnknown(data['heart_rate']!, _heartRateMeta));
    }
    if (data.containsKey('power')) {
      context.handle(
          _powerMeta, power.isAcceptableOrUnknown(data['power']!, _powerMeta));
    }
    if (data.containsKey('cadence')) {
      context.handle(_cadenceMeta,
          cadence.isAcceptableOrUnknown(data['cadence']!, _cadenceMeta));
    }
    if (data.containsKey('speed')) {
      context.handle(
          _speedMeta, speed.isAcceptableOrUnknown(data['speed']!, _speedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BikeSample map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BikeSample(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      workoutId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}workout_id'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
      heartRate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}heart_rate']),
      power: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}power']),
      cadence: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cadence']),
      speed: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}speed']),
    );
  }

  @override
  $BikeSamplesTable createAlias(String alias) {
    return $BikeSamplesTable(attachedDatabase, alias);
  }
}

class BikeSample extends DataClass implements Insertable<BikeSample> {
  final int id;
  final int workoutId;
  final DateTime timestamp;
  final int? heartRate;
  final int? power;
  final int? cadence;
  final double? speed;
  const BikeSample(
      {required this.id,
      required this.workoutId,
      required this.timestamp,
      this.heartRate,
      this.power,
      this.cadence,
      this.speed});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['workout_id'] = Variable<int>(workoutId);
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || heartRate != null) {
      map['heart_rate'] = Variable<int>(heartRate);
    }
    if (!nullToAbsent || power != null) {
      map['power'] = Variable<int>(power);
    }
    if (!nullToAbsent || cadence != null) {
      map['cadence'] = Variable<int>(cadence);
    }
    if (!nullToAbsent || speed != null) {
      map['speed'] = Variable<double>(speed);
    }
    return map;
  }

  BikeSamplesCompanion toCompanion(bool nullToAbsent) {
    return BikeSamplesCompanion(
      id: Value(id),
      workoutId: Value(workoutId),
      timestamp: Value(timestamp),
      heartRate: heartRate == null && nullToAbsent
          ? const Value.absent()
          : Value(heartRate),
      power:
          power == null && nullToAbsent ? const Value.absent() : Value(power),
      cadence: cadence == null && nullToAbsent
          ? const Value.absent()
          : Value(cadence),
      speed:
          speed == null && nullToAbsent ? const Value.absent() : Value(speed),
    );
  }

  factory BikeSample.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BikeSample(
      id: serializer.fromJson<int>(json['id']),
      workoutId: serializer.fromJson<int>(json['workoutId']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      heartRate: serializer.fromJson<int?>(json['heartRate']),
      power: serializer.fromJson<int?>(json['power']),
      cadence: serializer.fromJson<int?>(json['cadence']),
      speed: serializer.fromJson<double?>(json['speed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'workoutId': serializer.toJson<int>(workoutId),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'heartRate': serializer.toJson<int?>(heartRate),
      'power': serializer.toJson<int?>(power),
      'cadence': serializer.toJson<int?>(cadence),
      'speed': serializer.toJson<double?>(speed),
    };
  }

  BikeSample copyWith(
          {int? id,
          int? workoutId,
          DateTime? timestamp,
          Value<int?> heartRate = const Value.absent(),
          Value<int?> power = const Value.absent(),
          Value<int?> cadence = const Value.absent(),
          Value<double?> speed = const Value.absent()}) =>
      BikeSample(
        id: id ?? this.id,
        workoutId: workoutId ?? this.workoutId,
        timestamp: timestamp ?? this.timestamp,
        heartRate: heartRate.present ? heartRate.value : this.heartRate,
        power: power.present ? power.value : this.power,
        cadence: cadence.present ? cadence.value : this.cadence,
        speed: speed.present ? speed.value : this.speed,
      );
  BikeSample copyWithCompanion(BikeSamplesCompanion data) {
    return BikeSample(
      id: data.id.present ? data.id.value : this.id,
      workoutId: data.workoutId.present ? data.workoutId.value : this.workoutId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      heartRate: data.heartRate.present ? data.heartRate.value : this.heartRate,
      power: data.power.present ? data.power.value : this.power,
      cadence: data.cadence.present ? data.cadence.value : this.cadence,
      speed: data.speed.present ? data.speed.value : this.speed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BikeSample(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('timestamp: $timestamp, ')
          ..write('heartRate: $heartRate, ')
          ..write('power: $power, ')
          ..write('cadence: $cadence, ')
          ..write('speed: $speed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, workoutId, timestamp, heartRate, power, cadence, speed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BikeSample &&
          other.id == this.id &&
          other.workoutId == this.workoutId &&
          other.timestamp == this.timestamp &&
          other.heartRate == this.heartRate &&
          other.power == this.power &&
          other.cadence == this.cadence &&
          other.speed == this.speed);
}

class BikeSamplesCompanion extends UpdateCompanion<BikeSample> {
  final Value<int> id;
  final Value<int> workoutId;
  final Value<DateTime> timestamp;
  final Value<int?> heartRate;
  final Value<int?> power;
  final Value<int?> cadence;
  final Value<double?> speed;
  const BikeSamplesCompanion({
    this.id = const Value.absent(),
    this.workoutId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.heartRate = const Value.absent(),
    this.power = const Value.absent(),
    this.cadence = const Value.absent(),
    this.speed = const Value.absent(),
  });
  BikeSamplesCompanion.insert({
    this.id = const Value.absent(),
    required int workoutId,
    required DateTime timestamp,
    this.heartRate = const Value.absent(),
    this.power = const Value.absent(),
    this.cadence = const Value.absent(),
    this.speed = const Value.absent(),
  })  : workoutId = Value(workoutId),
        timestamp = Value(timestamp);
  static Insertable<BikeSample> custom({
    Expression<int>? id,
    Expression<int>? workoutId,
    Expression<DateTime>? timestamp,
    Expression<int>? heartRate,
    Expression<int>? power,
    Expression<int>? cadence,
    Expression<double>? speed,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workoutId != null) 'workout_id': workoutId,
      if (timestamp != null) 'timestamp': timestamp,
      if (heartRate != null) 'heart_rate': heartRate,
      if (power != null) 'power': power,
      if (cadence != null) 'cadence': cadence,
      if (speed != null) 'speed': speed,
    });
  }

  BikeSamplesCompanion copyWith(
      {Value<int>? id,
      Value<int>? workoutId,
      Value<DateTime>? timestamp,
      Value<int?>? heartRate,
      Value<int?>? power,
      Value<int?>? cadence,
      Value<double?>? speed}) {
    return BikeSamplesCompanion(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      timestamp: timestamp ?? this.timestamp,
      heartRate: heartRate ?? this.heartRate,
      power: power ?? this.power,
      cadence: cadence ?? this.cadence,
      speed: speed ?? this.speed,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (workoutId.present) {
      map['workout_id'] = Variable<int>(workoutId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (heartRate.present) {
      map['heart_rate'] = Variable<int>(heartRate.value);
    }
    if (power.present) {
      map['power'] = Variable<int>(power.value);
    }
    if (cadence.present) {
      map['cadence'] = Variable<int>(cadence.value);
    }
    if (speed.present) {
      map['speed'] = Variable<double>(speed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BikeSamplesCompanion(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('timestamp: $timestamp, ')
          ..write('heartRate: $heartRate, ')
          ..write('power: $power, ')
          ..write('cadence: $cadence, ')
          ..write('speed: $speed')
          ..write(')'))
        .toString();
  }
}

class $RrIntervalsTable extends RrIntervals
    with TableInfo<$RrIntervalsTable, RrInterval> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RrIntervalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _workoutIdMeta =
      const VerificationMeta('workoutId');
  @override
  late final GeneratedColumn<int> workoutId = GeneratedColumn<int>(
      'workout_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES workouts (id)'));
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _rrMsMeta = const VerificationMeta('rrMs');
  @override
  late final GeneratedColumn<int> rrMs = GeneratedColumn<int>(
      'rr_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, workoutId, timestamp, rrMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rr_intervals';
  @override
  VerificationContext validateIntegrity(Insertable<RrInterval> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('workout_id')) {
      context.handle(_workoutIdMeta,
          workoutId.isAcceptableOrUnknown(data['workout_id']!, _workoutIdMeta));
    } else if (isInserting) {
      context.missing(_workoutIdMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('rr_ms')) {
      context.handle(
          _rrMsMeta, rrMs.isAcceptableOrUnknown(data['rr_ms']!, _rrMsMeta));
    } else if (isInserting) {
      context.missing(_rrMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RrInterval map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RrInterval(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      workoutId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}workout_id'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
      rrMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rr_ms'])!,
    );
  }

  @override
  $RrIntervalsTable createAlias(String alias) {
    return $RrIntervalsTable(attachedDatabase, alias);
  }
}

class RrInterval extends DataClass implements Insertable<RrInterval> {
  final int id;
  final int workoutId;
  final DateTime timestamp;
  final int rrMs;
  const RrInterval(
      {required this.id,
      required this.workoutId,
      required this.timestamp,
      required this.rrMs});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['workout_id'] = Variable<int>(workoutId);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['rr_ms'] = Variable<int>(rrMs);
    return map;
  }

  RrIntervalsCompanion toCompanion(bool nullToAbsent) {
    return RrIntervalsCompanion(
      id: Value(id),
      workoutId: Value(workoutId),
      timestamp: Value(timestamp),
      rrMs: Value(rrMs),
    );
  }

  factory RrInterval.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RrInterval(
      id: serializer.fromJson<int>(json['id']),
      workoutId: serializer.fromJson<int>(json['workoutId']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      rrMs: serializer.fromJson<int>(json['rrMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'workoutId': serializer.toJson<int>(workoutId),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'rrMs': serializer.toJson<int>(rrMs),
    };
  }

  RrInterval copyWith(
          {int? id, int? workoutId, DateTime? timestamp, int? rrMs}) =>
      RrInterval(
        id: id ?? this.id,
        workoutId: workoutId ?? this.workoutId,
        timestamp: timestamp ?? this.timestamp,
        rrMs: rrMs ?? this.rrMs,
      );
  RrInterval copyWithCompanion(RrIntervalsCompanion data) {
    return RrInterval(
      id: data.id.present ? data.id.value : this.id,
      workoutId: data.workoutId.present ? data.workoutId.value : this.workoutId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      rrMs: data.rrMs.present ? data.rrMs.value : this.rrMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RrInterval(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('timestamp: $timestamp, ')
          ..write('rrMs: $rrMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, workoutId, timestamp, rrMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RrInterval &&
          other.id == this.id &&
          other.workoutId == this.workoutId &&
          other.timestamp == this.timestamp &&
          other.rrMs == this.rrMs);
}

class RrIntervalsCompanion extends UpdateCompanion<RrInterval> {
  final Value<int> id;
  final Value<int> workoutId;
  final Value<DateTime> timestamp;
  final Value<int> rrMs;
  const RrIntervalsCompanion({
    this.id = const Value.absent(),
    this.workoutId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.rrMs = const Value.absent(),
  });
  RrIntervalsCompanion.insert({
    this.id = const Value.absent(),
    required int workoutId,
    required DateTime timestamp,
    required int rrMs,
  })  : workoutId = Value(workoutId),
        timestamp = Value(timestamp),
        rrMs = Value(rrMs);
  static Insertable<RrInterval> custom({
    Expression<int>? id,
    Expression<int>? workoutId,
    Expression<DateTime>? timestamp,
    Expression<int>? rrMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workoutId != null) 'workout_id': workoutId,
      if (timestamp != null) 'timestamp': timestamp,
      if (rrMs != null) 'rr_ms': rrMs,
    });
  }

  RrIntervalsCompanion copyWith(
      {Value<int>? id,
      Value<int>? workoutId,
      Value<DateTime>? timestamp,
      Value<int>? rrMs}) {
    return RrIntervalsCompanion(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      timestamp: timestamp ?? this.timestamp,
      rrMs: rrMs ?? this.rrMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (workoutId.present) {
      map['workout_id'] = Variable<int>(workoutId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (rrMs.present) {
      map['rr_ms'] = Variable<int>(rrMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RrIntervalsCompanion(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('timestamp: $timestamp, ')
          ..write('rrMs: $rrMs')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WorkoutsTable workouts = $WorkoutsTable(this);
  late final $BikeSamplesTable bikeSamples = $BikeSamplesTable(this);
  late final $RrIntervalsTable rrIntervals = $RrIntervalsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [workouts, bikeSamples, rrIntervals];
}

typedef $$WorkoutsTableCreateCompanionBuilder = WorkoutsCompanion Function({
  Value<int> id,
  Value<String> sport,
  required DateTime startTime,
  Value<int> duration,
  Value<int?> avgPower,
  Value<int?> avgHr,
  Value<double?> totalKj,
  Value<double?> normalizedPower,
});
typedef $$WorkoutsTableUpdateCompanionBuilder = WorkoutsCompanion Function({
  Value<int> id,
  Value<String> sport,
  Value<DateTime> startTime,
  Value<int> duration,
  Value<int?> avgPower,
  Value<int?> avgHr,
  Value<double?> totalKj,
  Value<double?> normalizedPower,
});

final class $$WorkoutsTableReferences
    extends BaseReferences<_$AppDatabase, $WorkoutsTable, Workout> {
  $$WorkoutsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BikeSamplesTable, List<BikeSample>>
      _bikeSamplesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.bikeSamples,
          aliasName:
              $_aliasNameGenerator(db.workouts.id, db.bikeSamples.workoutId));

  $$BikeSamplesTableProcessedTableManager get bikeSamplesRefs {
    final manager = $$BikeSamplesTableTableManager($_db, $_db.bikeSamples)
        .filter((f) => f.workoutId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_bikeSamplesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$RrIntervalsTable, List<RrInterval>>
      _rrIntervalsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.rrIntervals,
          aliasName:
              $_aliasNameGenerator(db.workouts.id, db.rrIntervals.workoutId));

  $$RrIntervalsTableProcessedTableManager get rrIntervalsRefs {
    final manager = $$RrIntervalsTableTableManager($_db, $_db.rrIntervals)
        .filter((f) => f.workoutId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_rrIntervalsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$WorkoutsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sport => $composableBuilder(
      column: $table.sport, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get avgPower => $composableBuilder(
      column: $table.avgPower, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get avgHr => $composableBuilder(
      column: $table.avgHr, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalKj => $composableBuilder(
      column: $table.totalKj, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get normalizedPower => $composableBuilder(
      column: $table.normalizedPower,
      builder: (column) => ColumnFilters(column));

  Expression<bool> bikeSamplesRefs(
      Expression<bool> Function($$BikeSamplesTableFilterComposer f) f) {
    final $$BikeSamplesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.bikeSamples,
        getReferencedColumn: (t) => t.workoutId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BikeSamplesTableFilterComposer(
              $db: $db,
              $table: $db.bikeSamples,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> rrIntervalsRefs(
      Expression<bool> Function($$RrIntervalsTableFilterComposer f) f) {
    final $$RrIntervalsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.rrIntervals,
        getReferencedColumn: (t) => t.workoutId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RrIntervalsTableFilterComposer(
              $db: $db,
              $table: $db.rrIntervals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WorkoutsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sport => $composableBuilder(
      column: $table.sport, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get avgPower => $composableBuilder(
      column: $table.avgPower, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get avgHr => $composableBuilder(
      column: $table.avgHr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalKj => $composableBuilder(
      column: $table.totalKj, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get normalizedPower => $composableBuilder(
      column: $table.normalizedPower,
      builder: (column) => ColumnOrderings(column));
}

class $$WorkoutsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sport =>
      $composableBuilder(column: $table.sport, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<int> get avgPower =>
      $composableBuilder(column: $table.avgPower, builder: (column) => column);

  GeneratedColumn<int> get avgHr =>
      $composableBuilder(column: $table.avgHr, builder: (column) => column);

  GeneratedColumn<double> get totalKj =>
      $composableBuilder(column: $table.totalKj, builder: (column) => column);

  GeneratedColumn<double> get normalizedPower => $composableBuilder(
      column: $table.normalizedPower, builder: (column) => column);

  Expression<T> bikeSamplesRefs<T extends Object>(
      Expression<T> Function($$BikeSamplesTableAnnotationComposer a) f) {
    final $$BikeSamplesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.bikeSamples,
        getReferencedColumn: (t) => t.workoutId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BikeSamplesTableAnnotationComposer(
              $db: $db,
              $table: $db.bikeSamples,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> rrIntervalsRefs<T extends Object>(
      Expression<T> Function($$RrIntervalsTableAnnotationComposer a) f) {
    final $$RrIntervalsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.rrIntervals,
        getReferencedColumn: (t) => t.workoutId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RrIntervalsTableAnnotationComposer(
              $db: $db,
              $table: $db.rrIntervals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WorkoutsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WorkoutsTable,
    Workout,
    $$WorkoutsTableFilterComposer,
    $$WorkoutsTableOrderingComposer,
    $$WorkoutsTableAnnotationComposer,
    $$WorkoutsTableCreateCompanionBuilder,
    $$WorkoutsTableUpdateCompanionBuilder,
    (Workout, $$WorkoutsTableReferences),
    Workout,
    PrefetchHooks Function({bool bikeSamplesRefs, bool rrIntervalsRefs})> {
  $$WorkoutsTableTableManager(_$AppDatabase db, $WorkoutsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> sport = const Value.absent(),
            Value<DateTime> startTime = const Value.absent(),
            Value<int> duration = const Value.absent(),
            Value<int?> avgPower = const Value.absent(),
            Value<int?> avgHr = const Value.absent(),
            Value<double?> totalKj = const Value.absent(),
            Value<double?> normalizedPower = const Value.absent(),
          }) =>
              WorkoutsCompanion(
            id: id,
            sport: sport,
            startTime: startTime,
            duration: duration,
            avgPower: avgPower,
            avgHr: avgHr,
            totalKj: totalKj,
            normalizedPower: normalizedPower,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> sport = const Value.absent(),
            required DateTime startTime,
            Value<int> duration = const Value.absent(),
            Value<int?> avgPower = const Value.absent(),
            Value<int?> avgHr = const Value.absent(),
            Value<double?> totalKj = const Value.absent(),
            Value<double?> normalizedPower = const Value.absent(),
          }) =>
              WorkoutsCompanion.insert(
            id: id,
            sport: sport,
            startTime: startTime,
            duration: duration,
            avgPower: avgPower,
            avgHr: avgHr,
            totalKj: totalKj,
            normalizedPower: normalizedPower,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$WorkoutsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {bikeSamplesRefs = false, rrIntervalsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (bikeSamplesRefs) db.bikeSamples,
                if (rrIntervalsRefs) db.rrIntervals
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (bikeSamplesRefs)
                    await $_getPrefetchedData<Workout, $WorkoutsTable,
                            BikeSample>(
                        currentTable: table,
                        referencedTable:
                            $$WorkoutsTableReferences._bikeSamplesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WorkoutsTableReferences(db, table, p0)
                                .bikeSamplesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.workoutId == item.id),
                        typedResults: items),
                  if (rrIntervalsRefs)
                    await $_getPrefetchedData<Workout, $WorkoutsTable,
                            RrInterval>(
                        currentTable: table,
                        referencedTable:
                            $$WorkoutsTableReferences._rrIntervalsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WorkoutsTableReferences(db, table, p0)
                                .rrIntervalsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.workoutId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$WorkoutsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WorkoutsTable,
    Workout,
    $$WorkoutsTableFilterComposer,
    $$WorkoutsTableOrderingComposer,
    $$WorkoutsTableAnnotationComposer,
    $$WorkoutsTableCreateCompanionBuilder,
    $$WorkoutsTableUpdateCompanionBuilder,
    (Workout, $$WorkoutsTableReferences),
    Workout,
    PrefetchHooks Function({bool bikeSamplesRefs, bool rrIntervalsRefs})>;
typedef $$BikeSamplesTableCreateCompanionBuilder = BikeSamplesCompanion
    Function({
  Value<int> id,
  required int workoutId,
  required DateTime timestamp,
  Value<int?> heartRate,
  Value<int?> power,
  Value<int?> cadence,
  Value<double?> speed,
});
typedef $$BikeSamplesTableUpdateCompanionBuilder = BikeSamplesCompanion
    Function({
  Value<int> id,
  Value<int> workoutId,
  Value<DateTime> timestamp,
  Value<int?> heartRate,
  Value<int?> power,
  Value<int?> cadence,
  Value<double?> speed,
});

final class $$BikeSamplesTableReferences
    extends BaseReferences<_$AppDatabase, $BikeSamplesTable, BikeSample> {
  $$BikeSamplesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkoutsTable _workoutIdTable(_$AppDatabase db) =>
      db.workouts.createAlias(
          $_aliasNameGenerator(db.bikeSamples.workoutId, db.workouts.id));

  $$WorkoutsTableProcessedTableManager get workoutId {
    final $_column = $_itemColumn<int>('workout_id')!;

    final manager = $$WorkoutsTableTableManager($_db, $_db.workouts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workoutIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$BikeSamplesTableFilterComposer
    extends Composer<_$AppDatabase, $BikeSamplesTable> {
  $$BikeSamplesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get heartRate => $composableBuilder(
      column: $table.heartRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get power => $composableBuilder(
      column: $table.power, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cadence => $composableBuilder(
      column: $table.cadence, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get speed => $composableBuilder(
      column: $table.speed, builder: (column) => ColumnFilters(column));

  $$WorkoutsTableFilterComposer get workoutId {
    final $$WorkoutsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workoutId,
        referencedTable: $db.workouts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutsTableFilterComposer(
              $db: $db,
              $table: $db.workouts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BikeSamplesTableOrderingComposer
    extends Composer<_$AppDatabase, $BikeSamplesTable> {
  $$BikeSamplesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get heartRate => $composableBuilder(
      column: $table.heartRate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get power => $composableBuilder(
      column: $table.power, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cadence => $composableBuilder(
      column: $table.cadence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get speed => $composableBuilder(
      column: $table.speed, builder: (column) => ColumnOrderings(column));

  $$WorkoutsTableOrderingComposer get workoutId {
    final $$WorkoutsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workoutId,
        referencedTable: $db.workouts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutsTableOrderingComposer(
              $db: $db,
              $table: $db.workouts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BikeSamplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BikeSamplesTable> {
  $$BikeSamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get heartRate =>
      $composableBuilder(column: $table.heartRate, builder: (column) => column);

  GeneratedColumn<int> get power =>
      $composableBuilder(column: $table.power, builder: (column) => column);

  GeneratedColumn<int> get cadence =>
      $composableBuilder(column: $table.cadence, builder: (column) => column);

  GeneratedColumn<double> get speed =>
      $composableBuilder(column: $table.speed, builder: (column) => column);

  $$WorkoutsTableAnnotationComposer get workoutId {
    final $$WorkoutsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workoutId,
        referencedTable: $db.workouts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutsTableAnnotationComposer(
              $db: $db,
              $table: $db.workouts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BikeSamplesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BikeSamplesTable,
    BikeSample,
    $$BikeSamplesTableFilterComposer,
    $$BikeSamplesTableOrderingComposer,
    $$BikeSamplesTableAnnotationComposer,
    $$BikeSamplesTableCreateCompanionBuilder,
    $$BikeSamplesTableUpdateCompanionBuilder,
    (BikeSample, $$BikeSamplesTableReferences),
    BikeSample,
    PrefetchHooks Function({bool workoutId})> {
  $$BikeSamplesTableTableManager(_$AppDatabase db, $BikeSamplesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BikeSamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BikeSamplesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BikeSamplesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> workoutId = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
            Value<int?> heartRate = const Value.absent(),
            Value<int?> power = const Value.absent(),
            Value<int?> cadence = const Value.absent(),
            Value<double?> speed = const Value.absent(),
          }) =>
              BikeSamplesCompanion(
            id: id,
            workoutId: workoutId,
            timestamp: timestamp,
            heartRate: heartRate,
            power: power,
            cadence: cadence,
            speed: speed,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int workoutId,
            required DateTime timestamp,
            Value<int?> heartRate = const Value.absent(),
            Value<int?> power = const Value.absent(),
            Value<int?> cadence = const Value.absent(),
            Value<double?> speed = const Value.absent(),
          }) =>
              BikeSamplesCompanion.insert(
            id: id,
            workoutId: workoutId,
            timestamp: timestamp,
            heartRate: heartRate,
            power: power,
            cadence: cadence,
            speed: speed,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$BikeSamplesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({workoutId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (workoutId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.workoutId,
                    referencedTable:
                        $$BikeSamplesTableReferences._workoutIdTable(db),
                    referencedColumn:
                        $$BikeSamplesTableReferences._workoutIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$BikeSamplesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BikeSamplesTable,
    BikeSample,
    $$BikeSamplesTableFilterComposer,
    $$BikeSamplesTableOrderingComposer,
    $$BikeSamplesTableAnnotationComposer,
    $$BikeSamplesTableCreateCompanionBuilder,
    $$BikeSamplesTableUpdateCompanionBuilder,
    (BikeSample, $$BikeSamplesTableReferences),
    BikeSample,
    PrefetchHooks Function({bool workoutId})>;
typedef $$RrIntervalsTableCreateCompanionBuilder = RrIntervalsCompanion
    Function({
  Value<int> id,
  required int workoutId,
  required DateTime timestamp,
  required int rrMs,
});
typedef $$RrIntervalsTableUpdateCompanionBuilder = RrIntervalsCompanion
    Function({
  Value<int> id,
  Value<int> workoutId,
  Value<DateTime> timestamp,
  Value<int> rrMs,
});

final class $$RrIntervalsTableReferences
    extends BaseReferences<_$AppDatabase, $RrIntervalsTable, RrInterval> {
  $$RrIntervalsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkoutsTable _workoutIdTable(_$AppDatabase db) =>
      db.workouts.createAlias(
          $_aliasNameGenerator(db.rrIntervals.workoutId, db.workouts.id));

  $$WorkoutsTableProcessedTableManager get workoutId {
    final $_column = $_itemColumn<int>('workout_id')!;

    final manager = $$WorkoutsTableTableManager($_db, $_db.workouts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workoutIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$RrIntervalsTableFilterComposer
    extends Composer<_$AppDatabase, $RrIntervalsTable> {
  $$RrIntervalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rrMs => $composableBuilder(
      column: $table.rrMs, builder: (column) => ColumnFilters(column));

  $$WorkoutsTableFilterComposer get workoutId {
    final $$WorkoutsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workoutId,
        referencedTable: $db.workouts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutsTableFilterComposer(
              $db: $db,
              $table: $db.workouts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RrIntervalsTableOrderingComposer
    extends Composer<_$AppDatabase, $RrIntervalsTable> {
  $$RrIntervalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rrMs => $composableBuilder(
      column: $table.rrMs, builder: (column) => ColumnOrderings(column));

  $$WorkoutsTableOrderingComposer get workoutId {
    final $$WorkoutsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workoutId,
        referencedTable: $db.workouts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutsTableOrderingComposer(
              $db: $db,
              $table: $db.workouts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RrIntervalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RrIntervalsTable> {
  $$RrIntervalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get rrMs =>
      $composableBuilder(column: $table.rrMs, builder: (column) => column);

  $$WorkoutsTableAnnotationComposer get workoutId {
    final $$WorkoutsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.workoutId,
        referencedTable: $db.workouts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutsTableAnnotationComposer(
              $db: $db,
              $table: $db.workouts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RrIntervalsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RrIntervalsTable,
    RrInterval,
    $$RrIntervalsTableFilterComposer,
    $$RrIntervalsTableOrderingComposer,
    $$RrIntervalsTableAnnotationComposer,
    $$RrIntervalsTableCreateCompanionBuilder,
    $$RrIntervalsTableUpdateCompanionBuilder,
    (RrInterval, $$RrIntervalsTableReferences),
    RrInterval,
    PrefetchHooks Function({bool workoutId})> {
  $$RrIntervalsTableTableManager(_$AppDatabase db, $RrIntervalsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RrIntervalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RrIntervalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RrIntervalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> workoutId = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
            Value<int> rrMs = const Value.absent(),
          }) =>
              RrIntervalsCompanion(
            id: id,
            workoutId: workoutId,
            timestamp: timestamp,
            rrMs: rrMs,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int workoutId,
            required DateTime timestamp,
            required int rrMs,
          }) =>
              RrIntervalsCompanion.insert(
            id: id,
            workoutId: workoutId,
            timestamp: timestamp,
            rrMs: rrMs,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$RrIntervalsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({workoutId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (workoutId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.workoutId,
                    referencedTable:
                        $$RrIntervalsTableReferences._workoutIdTable(db),
                    referencedColumn:
                        $$RrIntervalsTableReferences._workoutIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$RrIntervalsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RrIntervalsTable,
    RrInterval,
    $$RrIntervalsTableFilterComposer,
    $$RrIntervalsTableOrderingComposer,
    $$RrIntervalsTableAnnotationComposer,
    $$RrIntervalsTableCreateCompanionBuilder,
    $$RrIntervalsTableUpdateCompanionBuilder,
    (RrInterval, $$RrIntervalsTableReferences),
    RrInterval,
    PrefetchHooks Function({bool workoutId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WorkoutsTableTableManager get workouts =>
      $$WorkoutsTableTableManager(_db, _db.workouts);
  $$BikeSamplesTableTableManager get bikeSamples =>
      $$BikeSamplesTableTableManager(_db, _db.bikeSamples);
  $$RrIntervalsTableTableManager get rrIntervals =>
      $$RrIntervalsTableTableManager(_db, _db.rrIntervals);
}
