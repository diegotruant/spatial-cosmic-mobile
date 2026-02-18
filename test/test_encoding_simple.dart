import 'package:fit_tool/fit_tool.dart';

void main() async {
  print('🧪 TESTING FIT_TOOL DEFAULT SCALES (Simplified)');
  
  // 1. Create a file with manually created SessionMessage
  final builder = FitFileBuilder();
  
  builder.add(FileIdMessage()
    ..type = FileType.activity
    ..manufacturer = 1
    ..product = 1
    ..timeCreated = DateTime.now().millisecondsSinceEpoch ~/ 1000
    ..serialNumber = 123
  );
  
  builder.add(SessionMessage()
    ..totalTimerTime = 1000.0 // Expecting 1000 seconds
    ..totalDistance = 1000.0  // Expecting 1000 meters
  );
  
  final fileBytes = builder.build().toBytes();
  
  // 2. Read it back
  final fitFile = FitFile.fromBytes(fileBytes);
  
  // 3. Inspect Data
  for (final record in fitFile.records) {
    if (record.message is SessionMessage) {
      final msg = record.message as SessionMessage;
      print('🔹 Decoded Data:');
      print('   - totalTimerTime: ${msg.totalTimerTime}');
      print('   - totalDistance: ${msg.totalDistance}');
      
      if (msg.totalTimerTime == 1000.0) {
        print('   ✅ Read back matches input.');
      } else {
        print('   ❌ Read back mismatch! Got ${msg.totalTimerTime}, Expected 1000.0');
      }
    }
  }
}
