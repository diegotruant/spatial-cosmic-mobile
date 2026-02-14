
import 'dart:io';
import 'package:fit_tool/fit_tool.dart';

// Simple standalone repair logic based on what we fixed
// FIT Epoch offset: 631065600
int toFitTime(DateTime dateTime) {
  return (dateTime.toUtc().millisecondsSinceEpoch / 1000).round() - 631065600;
}

void main() async {
  final file = File('../cycling-coach-platform/1770398355836.fit');
  if (!file.existsSync()) {
    print('Original file not found!');
    return;
  }

  final bytes = await file.readAsBytes();
  final fitFile = FitFile.fromBytes(bytes);

  final List<int> powers = [];
  final List<int> hrs = [];
  final List<int> cads = [];
  final List<double> speeds = [];
  DateTime? startTime;

  for (final record in fitFile.records) {
    if (record.message is RecordMessage) {
      final m = record.message as RecordMessage;
      powers.add(m.power ?? 0);
      hrs.add(m.heartRate ?? 0);
      cads.add(m.cadence ?? 0);
      speeds.add(m.speed ?? 0.0);
      if (startTime == null && m.timestamp != null) {
        startTime = DateTime.fromMillisecondsSinceEpoch((m.timestamp! + 631065600) * 1000);
      }
    }
  }

  startTime ??= DateTime.now();

  print('Extracted ${powers.length} records. Repairing...');

  final builder = FitFileBuilder();
  final startFitTime = toFitTime(startTime);

  builder.add(FileIdMessage()
    ..type = FileType.activity
    ..manufacturer = 32
    ..product = 1
    ..timeCreated = startFitTime
    ..serialNumber = 12345678
  );

  builder.add(EventMessage()
    ..timestamp = startFitTime
    ..event = Event.timer
    ..eventType = EventType.start
    ..eventGroup = 0
  );

  double cumulativeDist = 0;
  for (int i = 0; i < powers.length; i++) {
    final recTime = startTime.add(Duration(seconds: i));
    
    // Use the logic we just fixed:
    // If original speed was in km/h (bugged in previous recordings maybe?) or 0.
    // Let's assume we want a reasonable speed if it's 0.
    double currentSpeedMs = speeds[i];
    if (currentSpeedMs < 0.1 && powers[i] > 10) {
        // Estimate speed from power if it was missing/0
        currentSpeedMs = (powers[i] / 10.0) / 3.6; 
    }
    
    cumulativeDist += currentSpeedMs;

    builder.add(RecordMessage()
      ..timestamp = toFitTime(recTime)
      ..distance = cumulativeDist
      ..power = powers[i]
      ..heartRate = hrs[i]
      ..cadence = cads[i]
      ..speed = currentSpeedMs
    );
  }

  builder.add(EventMessage()
    ..timestamp = toFitTime(startTime.add(Duration(seconds: powers.length)))
    ..event = Event.timer
    ..eventType = EventType.stop
    ..eventGroup = 0
  );

  // Session
  builder.add(SessionMessage()
    ..timestamp = toFitTime(startTime.add(Duration(seconds: powers.length)))
    ..startTime = startFitTime
    ..totalTimerTime = powers.length.toDouble()
    ..totalElapsedTime = powers.length.toDouble()
    ..totalDistance = cumulativeDist
    ..sport = Sport.cycling
    ..subSport = SubSport.indoorCycling
    ..firstLapIndex = 0
    ..numLaps = 1
  );

  builder.add(ActivityMessage()
    ..timestamp = toFitTime(startTime.add(Duration(seconds: powers.length)))
    ..totalTimerTime = powers.length.toDouble()
    ..numSessions = 1
    ..type = Activity.manual
    ..event = Event.activity
    ..eventType = EventType.stop
  );

  final repairedFile = builder.build();
  const desktopPath = 'C:/Users/Diego Truant/Desktop/Workout_Riparato_Diego.fit';
  await File(desktopPath).writeAsBytes(repairedFile.toBytes());
  
  print('SUCCESS: Repaired file saved to $desktopPath');
}
