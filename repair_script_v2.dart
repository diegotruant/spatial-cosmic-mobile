
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
  DateTime? startTime;

  for (final record in fitFile.records) {
    if (record.message is RecordMessage) {
      final m = record.message as RecordMessage;
      powers.add(m.power ?? 0);
      hrs.add(m.heartRate ?? 0);
      cads.add(m.cadence ?? 0);
      if (startTime == null && m.timestamp != null) {
        startTime = DateTime.fromMillisecondsSinceEpoch((m.timestamp! + 631065600) * 1000);
      }
    }
  }

  startTime ??= DateTime.now();

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
    
    // Calcolo velocità realistica dai watt (approssimazione per indoor)
    // 200W -> ~30km/h -> 8.33 m/s
    double speedMs = 0;
    if (powers[i] > 10) {
        speedMs = (powers[i] / 24.0) + 2.0; // Formula semplificata per velocità verosimile
    }
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

  builder.add(EventMessage()
    ..timestamp = toFitTime(endTime)
    ..event = Event.timer
    ..eventType = EventType.stop
  );

  // NOTA CRITICA: Molti campi FIT richiedono scaling. 
  // totalTimerTime in FIT binary è in ms (scale 1000). 
  // Usiamo il builder che dovrebbe gestire lo scaling ma per sicurezza verifichiamo i nomi dei campi.
  
  builder.add(SessionMessage()
    ..timestamp = toFitTime(endTime)
    ..startTime = startFitTime
    ..totalTimerTime = powers.length.toDouble() 
    ..totalElapsedTime = powers.length.toDouble()
    ..totalDistance = cumulativeDist
    ..avgPower = (powers.reduce((a, b) => a + b) / powers.length).toInt()
    ..sport = Sport.cycling
    ..subSport = SubSport.indoorCycling
    ..firstLapIndex = 0
    ..numLaps = 1
  );

  builder.add(ActivityMessage()
    ..timestamp = toFitTime(endTime)
    ..totalTimerTime = powers.length.toDouble()
    ..numSessions = 1
    ..type = Activity.manual
    ..event = Event.activity
    ..eventType = EventType.stop
  );

  final repairedFile = builder.build();
  const desktopPath = 'C:/Users/Diego Truant/Desktop/Workout_Riparato_Diego_V2.fit';
  await File(desktopPath).writeAsBytes(repairedFile.toBytes());
  
  print('Riparazione V2 completata: $desktopPath');
}
