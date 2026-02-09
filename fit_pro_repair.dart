
import 'dart:io';
import 'dart:math';
import 'package:fit_tool/fit_tool.dart';

int toFitTime(DateTime dateTime) {
  final fitEpoch = DateTime.utc(1989, 12, 31, 0, 0, 0).millisecondsSinceEpoch;
  return (dateTime.millisecondsSinceEpoch - fitEpoch) ~/ 1000;
}

int calculateNormalizedPower(List<int> powers) {
  if (powers.length < 30) {
    if (powers.isEmpty) return 0;
    return (powers.fold(0, (a, b) => a + b) / powers.length).round();
  }

  List<double> rollingAvgs = [];
  for (int i = 29; i < powers.length; i++) {
    double sum = 0;
    for (int j = i - 29; j <= i; j++) {
      sum += powers[j];
    }
    rollingAvgs.add(sum / 30);
  }

  double sumOfFourthPower = 0;
  for (var avg in rollingAvgs) {
    sumOfFourthPower += pow(avg, 4);
  }

  double np = pow(sumOfFourthPower / rollingAvgs.length, 1/4).toDouble();
  return np.round();
}

void main() async {
  final file = File('../cycling-coach-platform/1770398355836.fit');
  if (!file.existsSync()) return;
  final bytes = await file.readAsBytes();
  final fitFile = FitFile.fromBytes(bytes);
  
  final List<int> powers = [];
  final List<int> hrs = [];
  final List<int> cads = [];
  for (final record in fitFile.records) {
    if (record.message is RecordMessage) {
      final m = record.message as RecordMessage;
      powers.add(m.power ?? 0);
      hrs.add(m.heartRate ?? 0);
      cads.add(m.cadence ?? 0);
    }
  }

  final startTime = DateTime(2026, 2, 6, 18, 0, 0); 
  final builder = FitFileBuilder();

  builder.add(FileIdMessage()
    ..type = FileType.activity
    ..manufacturer = 1 // Garmin
    ..product = 1
    ..timeCreated = toFitTime(startTime)
    ..serialNumber = 987654321
  );

  builder.add(EventMessage()
    ..timestamp = toFitTime(startTime)
    ..event = Event.timer
    ..eventType = EventType.start
  );

  double distance = 0;
  for (int i = 0; i < powers.length; i++) {
    final timestamp = startTime.add(Duration(seconds: i));
    double speed = 8.5; // ~30.6 km/h in m/s
    distance += speed;

    builder.add(RecordMessage()
      ..timestamp = toFitTime(timestamp)
      ..distance = distance
      ..power = powers[i]
      ..heartRate = hrs[i]
      ..cadence = cads[i]
      ..speed = speed
    );
  }

  final endTime = startTime.add(Duration(seconds: powers.length));
  
  builder.add(EventMessage()
    ..timestamp = toFitTime(endTime)
    ..event = Event.timer
    ..eventType = EventType.stop
  );

  final avgPower = (powers.reduce((a, b) => a + b) / powers.length).toInt();
  final normalizedPower = calculateNormalizedPower(powers);
  
  // APPLY SCALE FACTORS: x1000 for time, x100 for distance, x1000 for speed
  builder.add(SessionMessage()
    ..timestamp = toFitTime(endTime)
    ..startTime = toFitTime(startTime)
    ..totalTimerTime = powers.length.toDouble() * 1000.0  // Scale factor x1000
    ..totalElapsedTime = powers.length.toDouble() * 1000.0  // Scale factor x1000
    ..totalDistance = distance * 100.0  // Scale factor x100
    ..avgPower = avgPower
    ..normalizedPower = normalizedPower
    ..sport = Sport.cycling
    ..subSport = SubSport.indoorCycling
  );

  builder.add(ActivityMessage()
    ..timestamp = toFitTime(endTime)
    ..totalTimerTime = powers.length.toDouble() * 1000.0  // Scale factor x1000
    ..numSessions = 1
    ..type = Activity.manual
    ..event = Event.activity
    ..eventType = EventType.stop
  );

  final repairedFile = builder.build();
  await File('C:/Users/Diego Truant/Desktop/Workout_FIXED_WITH_SCALE.fit').writeAsBytes(repairedFile.toBytes());
  print('✅ GENERATED: Workout_FIXED_WITH_SCALE.fit');
  print('   Duration: ${powers.length}s (${(powers.length / 60).toStringAsFixed(1)} minutes)');
  print('   Avg Power: ${avgPower}W');
  print('   Normalized Power: ${normalizedPower}W');
  print('   Distance: ${(distance / 1000).toStringAsFixed(2)} km');
}
