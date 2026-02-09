import 'dart:io';
import 'package:fit_tool/fit_tool.dart';

void main() async {
  print('🧪 TESTING TEMPLATE APPROACH');
  print('=' * 60);

  // 1. Read Working File
  final templateFile = File('C:/Users/Diego Truant/Desktop/Threshold_XCM_Steps.fit');
  final bytes = await templateFile.readAsBytes();
  final fitFile = FitFile.fromBytes(bytes);
  
  // 2. Extract Template Messages
  SessionMessage? templateSession;
  ActivityMessage? templateActivity;
  LapMessage? templateLap;
  
  for (final record in fitFile.records) {
    if (record.message is SessionMessage) templateSession = record.message as SessionMessage;
    if (record.message is ActivityMessage) templateActivity = record.message as ActivityMessage;
    if (record.message is LapMessage) templateLap = record.message as LapMessage;
  }
  
  if (templateSession == null) {
    print('❌ Template Session not found');
    return;
  }
  
  // 3. Create New File using Templates
  final builder = FitFileBuilder();
  
  // Add FileId
  builder.add(FileIdMessage()
    ..type = FileType.activity
    ..manufacturer = 1
    ..product = 1
    ..timeCreated = DateTime.now().millisecondsSinceEpoch ~/ 1000
    ..serialNumber = 999
  );
  
  // 4. Modify and Add Templates
  // New Values: 1h 2m 59s (3779s), 32.1 km (32121m), 197W, 211W NP
  
  // Note: We use the existing object and modify fields. 
  // We assume properties are mutable.
  
  // IMPORTANT: Set raw values (seconds/meters). 
  // If the Template has correct definition (Scale 1000), fit_tool should auto-scale.
  
  final newSession = templateSession
    ..totalTimerTime = 3779.0
    ..totalElapsedTime = 3779.0
    ..totalDistance = 32121.0
    ..avgPower = 197
    ..normalizedPower = 211
    ..avgSpeed = 8.5
    ..maxSpeed = 10.0;
    
  builder.add(newSession);
  
  if (templateActivity != null) {
      builder.add(templateActivity
        ..totalTimerTime = 3779.0
      );
  }
  
  // Add a Lap too
  if (templateLap != null) {
     builder.add(templateLap
        ..totalTimerTime = 3779.0
        ..totalDistance = 32121.0
        ..avgPower = 197
        ..normalizedPower = 211
     );
  }
  
  // Add Records (Simplified)
  // We won't use template records, just simple ones.
  // Standard RecordMessages should be fine? Or do we need template Record too?
  // Let's rely on standard records for now (Record is usually Message 20, standard).
  
  final startTime = DateTime.now().subtract(Duration(seconds: 3779));
  // toFitTime logic equivalent
  int startFit = (startTime.millisecondsSinceEpoch - DateTime.utc(1989, 12, 31).millisecondsSinceEpoch) ~/ 1000;
  
  for (int i = 0; i < 3779; i += 60) { // One record every minute to save space/time
     builder.add(RecordMessage()
       ..timestamp = startFit + i
       ..distance = (i * 8.5)
       ..speed = 8.5
       ..power = 197
     );
  }
  // Add final record
  builder.add(RecordMessage()
     ..timestamp = startFit + 3779
     ..distance = 32121.0
     ..speed = 8.5
     ..power = 197
  );

  final newFile = builder.build();
  await File('C:/Users/Diego Truant/Desktop/Workout_TEMPLATE_TEST.fit').writeAsBytes(newFile.toBytes());
  
  print('✅ GENERATED: Workout_TEMPLATE_TEST.fit');
  print('   Used Session Template from Working File.');
  print('   Values set: 3779s, 32km.');
  print('📤 UPLOAD THIS TO STRAVA!');
}
