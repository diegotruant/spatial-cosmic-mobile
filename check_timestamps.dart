import 'dart:io';
import 'package:fit_tool/fit_tool.dart';

void main() async {
  print('🔍 ANALYZING TIMESTAMPS IN ORIGINAL FIT FILE');
  
  final file = File('C:/Users/Diego Truant/Desktop/Workout_RAW_WITH_LAP.fit');
  final bytes = await file.readAsBytes();
  final fitFile = FitFile.fromBytes(bytes);
  
  int? firstTime;
  int? lastTime;
  int count = 0;
  
  print('Checking first 20 records...');
  
  for (final record in fitFile.records) {
    if (record.message is RecordMessage) {
      final msg = record.message as RecordMessage;
      if (msg.timestamp != null) {
        if (firstTime == null) firstTime = msg.timestamp;
        lastTime = msg.timestamp;
        
        if (count < 20) {
          print('  Record #${count}: Timestamp ${msg.timestamp}');
        }
        count++;
      }
    }
  }
  
  if (firstTime != null && lastTime != null) {
    print('=' * 40);
    print('First Usage: $firstTime');
    print('Last Usage:  $lastTime');
    print('Delta:       ${lastTime - firstTime} seconds');
    print('Record Count: $count');
    
    if ((lastTime - firstTime) < 100) {
      print('❌ PROBLEM: Duration is too short! (${lastTime - firstTime}s)');
    } else {
      print('✅ Duration seems correct relative to timestamps.');
    }
  } else {
    print('❌ PROBLEM: No timestamps found in records.');
  }
}
