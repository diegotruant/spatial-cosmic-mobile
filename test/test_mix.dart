import 'dart:io';
import 'package:fit_tool/fit_tool.dart';

void main() async {
  print('🧪 TESTING MIX APPROACH (Working Session + New Records)');
  
  // 1. Read Working File
  final templateFile = File('C:/Users/Diego Truant/Desktop/Threshold_XCM_Steps.fit');
  final bytes = await templateFile.readAsBytes();
  final fitFile = FitFile.fromBytes(bytes);
  
  SessionMessage? templateSession;
  for (final record in fitFile.records) {
    if (record.message is SessionMessage) {
      templateSession = record.message as SessionMessage;
      break;
    }
  }
  
  // 2. Create Builder
  final builder = FitFileBuilder();
  
  builder.add(FileIdMessage()
    ..type = FileType.activity
    ..manufacturer = 1
    ..product = 1
    ..timeCreated = DateTime.now().millisecondsSinceEpoch ~/ 1000
    ..serialNumber = 555
  );
  
  // 3. Add Working Session (Modified Time)
  // We modify it to 3779s
  if (templateSession != null) {
    builder.add(templateSession
      ..totalTimerTime = 3779.0
      ..totalDistance = 32121.0
      ..avgPower = 197
    );
  }
  
  // 4. Add NEW Records
  final startTime = DateTime.now().subtract(const Duration(seconds: 3779));
  int startFit = (startTime.millisecondsSinceEpoch - DateTime.utc(1989, 12, 31).millisecondsSinceEpoch) ~/ 1000;
  
  for (int i = 0; i < 3779; i += 60) {
     builder.add(RecordMessage()
       ..timestamp = startFit + i
       ..distance = (i * 8.5)
       ..speed = 8.5
       ..power = 197
     );
  }
  // Last record
  builder.add(RecordMessage()
     ..timestamp = startFit + 3779
     ..distance = 32121.0
     ..speed = 8.5
     ..power = 197
  );

  final newFile = builder.build();
  await File('C:/Users/Diego Truant/Desktop/Workout_MIX_TEST.fit').writeAsBytes(newFile.toBytes());
  
  print('✅ GENERATED: Workout_MIX_TEST.fit');
  print('📤 UPLOAD THIS TO STRAVA!');
}
