
import 'dart:io';
import 'package:fit_tool/fit_tool.dart';

int toFitTime(DateTime dateTime) {
  return (dateTime.toUtc().millisecondsSinceEpoch / 1000).round() - 631065600;
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

  final startTime = DateTime.now().subtract(Duration(seconds: powers.length + 7200));
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
  );

  double cumulativeDist = 0;
  for (int i = 0; i < powers.length; i++) {
    final recTime = startTime.add(Duration(seconds: i));
    double speedMs = 8.5; // ~30.6 km/h
    cumulativeDist += speedMs;

    builder.add(RecordMessage()
      ..timestamp = toFitTime(recTime)
      ..distance = cumulativeDist
      ..power = powers[i]
      ..heartRate = hrs[i]
      ..cadence = cads[i]
      ..speed = speedMs
    );
  }

  final endTime = startTime.add(Duration(seconds: powers.length));
  final endFitTime = toFitTime(endTime);

  builder.add(EventMessage()
    ..timestamp = endFitTime
    ..event = Event.timer
    ..eventType = EventType.stop
  );

  // SESSIONE: MOLTIPLICO X 1000 PER EVITARE CHE STRAVA DIVIDA PER 1000
  builder.add(SessionMessage()
    ..timestamp = endFitTime
    ..startTime = startFitTime
    ..totalTimerTime = powers.length.toDouble() * 1000.0 // FORZATO SCALE 1000
    ..totalElapsedTime = powers.length.toDouble() * 1000.0 // FORZATO SCALE 1000
    ..totalDistance = cumulativeDist * 100.0 // FORZATO SCALE 100
    ..avgPower = (powers.reduce((a, b) => a + b) / powers.length).toInt()
    ..sport = Sport.cycling
    ..subSport = SubSport.indoorCycling
    ..firstLapIndex = 0
    ..numLaps = 1
  );

  builder.add(ActivityMessage()
    ..timestamp = endFitTime
    ..totalTimerTime = powers.length.toDouble() * 1000.0 // FORZATO SCALE 1000
    ..numSessions = 1
    ..type = Activity.manual
    ..event = Event.activity
    ..eventType = EventType.stop
  );

  final repairedFile = builder.build();
  final desktopPath = 'C:/Users/Diego Truant/Desktop/Workout_DEFINITIVO_Diego.fit';
  await File(desktopPath).writeAsBytes(repairedFile.toBytes());
  
  print('Riparazione V4 completata. File salvato sul Desktop.');
}
