
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

  // Usiamo un'ora di inizio pulita (es. 2 ore fa) per evitare conflitti
  final startTime = DateTime.now().subtract(Duration(seconds: powers.length + 3600));
  print('Riparazione V3: ${powers.length} secondi di attività.');

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
    
    // Velocità verosimile ~30km/h (8.33 m/s)
    double speedMs = 8.33 + (powers[i] > 200 ? 2.0 : -1.0); 
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

  // SESSIONE: Qui applichiamo lo SCALING x1000 richiesto da Strava per durata e distanza
  builder.add(SessionMessage()
    ..timestamp = endFitTime
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
    ..timestamp = endFitTime
    ..totalTimerTime = powers.length.toDouble()
    ..numSessions = 1
    ..type = Activity.manual
    ..event = Event.activity
    ..eventType = EventType.stop
  );

  final repairedFile = builder.build();
  const desktopPath = 'C:/Users/Diego Truant/Desktop/Workout_VERO_Diego.fit';
  await File(desktopPath).writeAsBytes(repairedFile.toBytes());
  
  print('SUCCESSO: File VERO salvato sul Desktop.');
}
