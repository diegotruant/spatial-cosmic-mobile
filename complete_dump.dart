import 'dart:io';
import 'package:fit_tool/fit_tool.dart';

void main() async {
  print('🔍 COMPLETE FIT FILE ANALYSIS');
  print('=' * 60);
  
  final file = File('C:/Users/Diego Truant/Desktop/Workout_FIXED_WITH_SCALE.fit');
  if (!file.existsSync()) {
    print('❌ File not found!');
    return;
  }
  
  final bytes = await file.readAsBytes();
  final fitFile = FitFile.fromBytes(bytes);
  
  print('📦 ALL MESSAGES IN FILE:');
  print('');
  
  int recordCount = 0;
  for (final record in fitFile.records) {
    final msg = record.message;
    final msgType = msg.runtimeType.toString();
    
    print('Message type: $msgType');
    
    if (msg is SessionMessage) {
      print('  ✅ SESSION MESSAGE FOUND!');
      print('  totalTimerTime: ${msg.totalTimerTime}');
      print('  totalElapsedTime: ${msg.totalElapsedTime}');
      print('  totalDistance: ${msg.totalDistance}');
      print('  avgPower: ${msg.avgPower}');
      print('  normalizedPower: ${msg.normalizedPower}');
      print('  avgSpeed: ${msg.avgSpeed}');
      print('  sport: ${msg.sport}');
      print('');
    }
    
    if (msg is ActivityMessage) {
      print('  ✅ ACTIVITY MESSAGE FOUND!');
      print('  totalTimerTime: ${msg.totalTimerTime}');
      print('  numSessions: ${msg.numSessions}');
      print('  type: ${msg.type}');
      print('');
    }
    
    if (msg is LapMessage) {
      print('  ✅ LAP MESSAGE FOUND!');
      print('  totalTimerTime: ${msg.totalTimerTime}');
      print('  totalDistance: ${msg.totalDistance}');
      print('  avgPower: ${msg.avgPower}');
      print('');
    }
    
    if (msg is RecordMessage) {
      recordCount++;
      if (recordCount == 1) {
        print('  First Record:');
        print('    distance: ${msg.distance}');
        print('    speed: ${msg.speed}');
        print('    power: ${msg.power}');
        print('');
      }
    }
  }
  
  print('Total RecordMessages: $recordCount');
  print('');
  print('🎯 CRITICAL QUESTION:');
  print('Are the values above ALREADY scaled or RAW?');
}
