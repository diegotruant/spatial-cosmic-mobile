import 'dart:io';
import 'package:fit_tool/fit_tool.dart';

void main() async {
  print('🧪 TESTING RAW VALUES WITH LAP MESSAGE');
  
  final builder = FitFileBuilder();
  
  final startTime = DateTime.now().subtract(Duration(seconds: 3779));
  final startFit = (startTime.millisecondsSinceEpoch - DateTime.utc(1989, 12, 31).millisecondsSinceEpoch) ~/ 1000;
  final endTime = DateTime.now();
  final endFit = (endTime.millisecondsSinceEpoch - DateTime.utc(1989, 12, 31).millisecondsSinceEpoch) ~/ 1000;
  
  builder.add(FileIdMessage()
    ..type = FileType.activity
    ..manufacturer = 1
    ..product = 1
    ..timeCreated = endFit
    ..serialNumber = 777
  );
  
  builder.add(EventMessage()
    ..timestamp = startFit
    ..event = Event.timer
    ..eventType = EventType.start
  );
  
  // Add Records
  for (int i = 0; i <= 3779; i += 10) { // Every 10s
    builder.add(RecordMessage()
       ..timestamp = startFit + i
       ..distance = (i * 8.5)
       ..speed = 8.5
       ..power = 197
       ..heartRate = 140
       ..cadence = 80
    );
  }
  
  builder.add(EventMessage()
    ..timestamp = endFit
    ..event = Event.timer
    ..eventType = EventType.stop
  );
  
  // Add Lap
  builder.add(LapMessage()
    ..timestamp = endFit
    ..startTime = startFit
    ..totalTimerTime = 3779.0 // Raw Seconds -> Scaled to 3779000 by fit_tool
    ..totalElapsedTime = 3779.0
    ..totalDistance = 32121.0 // Raw Meters -> Scaled to 3212100 by fit_tool
    ..avgPower = 197
    ..normalizedPower = 211
    ..avgSpeed = 8.5
  );
  
  // Add Session
  builder.add(SessionMessage()
    ..timestamp = endFit
    ..startTime = startFit
    ..totalTimerTime = 3779.0
    ..totalElapsedTime = 3779.0
    ..totalDistance = 32121.0
    ..avgPower = 197
    ..normalizedPower = 211
    ..avgSpeed = 8.5
    ..sport = Sport.cycling
    ..subSport = SubSport.indoorCycling
    ..numLaps = 1
    ..firstLapIndex = 0
  );
  
  // Add Activity
  builder.add(ActivityMessage()
    ..timestamp = endFit
    ..totalTimerTime = 3779.0
    ..numSessions = 1
    ..type = Activity.manual
    ..event = Event.activity
    ..eventType = EventType.stop
  );

  final newFile = builder.build();
  await File('C:/Users/Diego Truant/Desktop/Workout_RAW_WITH_LAP.fit').writeAsBytes(newFile.toBytes());
  
  print('✅ GENERATED: Workout_RAW_WITH_LAP.fit');
  print('   Values: 3779s (RAW), 32km (RAW).');
  print('   Includes: Lap, Session, Activity, Events, Records.');
  print('📤 UPLOAD THIS TO STRAVA!');
}
