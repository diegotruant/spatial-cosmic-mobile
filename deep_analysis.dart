import 'dart:io';
import 'package:fit_tool/fit_tool.dart';

void main() async {
  print('🔍 ANALYZING STRAVA UPLOAD ISSUE');
  print('=' * 60);
  
  // Read our "fixed" file
  final file = File('C:/Users/Diego Truant/Desktop/Workout_FIXED_WITH_SCALE.fit');
  if (!file.existsSync()) {
    print('❌ File not found!');
    return;
  }
  
  final bytes = await file.readAsBytes();
  print('File size: ${bytes.length} bytes');
  print('');
  
  final fitFile = FitFile.fromBytes(bytes);
  
  print('📊 ANALYZING BINARY ENCODING:');
  print('');
  
  for (final record in fitFile.records) {
    final msg = record.message;
    
    if (msg is SessionMessage) {
      print('SessionMessage Fields:');
      print('  totalTimerTime (raw from binary): ${msg.totalTimerTime}');
      print('  totalElapsedTime (raw from binary): ${msg.totalElapsedTime}');
      print('  totalDistance (raw from binary): ${msg.totalDistance}');
      print('  avgPower: ${msg.avgPower}');
      print('  normalizedPower: ${msg.normalizedPower}');
      print('  avgSpeed: ${msg.avgSpeed}');
      print('  maxSpeed: ${msg.maxSpeed}');
      print('');
      
      // Try to understand what Strava is reading
      if (msg.totalTimerTime != null) {
        print('🤔 INTERPRETATION ANALYSIS:');
        print('  If Strava reads ${msg.totalTimerTime} as-is:');
        print('    → ${msg.totalTimerTime! / 1000} seconds = ${msg.totalTimerTime! / 60000} minutes');
        print('  If Strava divides by 1000:');
        print('    → ${msg.totalTimerTime} milliseconds = ${msg.totalTimerTime! / 1000} seconds');
        print('');
      }
    }
    
    if (msg is RecordMessage) {
      // Check first record to see encoding
      print('First RecordMessage:');
      print('  timestamp: ${msg.timestamp}');
      print('  distance: ${msg.distance}');
      print('  speed: ${msg.speed}');
      print('  power: ${msg.power}');
      print('');
      break; // Only first record
    }
  }
  
  print('');
  print('🎯 HYPOTHESIS:');
  print('If Strava shows 3 seconds and we stored 3779000...');
  print('Strava might be reading: 3779000 / 1000 / 1000 = 3.779 seconds');
  print('This suggests fit_tool is ALREADY applying scale factor');
  print('when writing to binary, and we DOUBLED it!');
}
