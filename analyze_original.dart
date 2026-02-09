import 'dart:io';
import 'package:fit_tool/fit_tool.dart';

void main() async {
  print('🔍 ANALYZING ORIGINAL FIT FILE');
  print('=' * 60);
  
  final file = File('../cycling-coach-platform/1770398355836.fit');
  if (!file.existsSync()) {
    print('❌ File not found!');
    return;
  }
  
  final bytes = await file.readAsBytes();
  final fitFile = FitFile.fromBytes(bytes);
  
  print('📦 ORIGINAL FILE MESSAGES:');
  print('');
  
  for (final record in fitFile.records) {
    final msg = record.message;
    
    if (msg is SessionMessage) {
      print('✅ SESSION MESSAGE:');
      print('  totalTimerTime: ${msg.totalTimerTime}');
      print('  totalElapsedTime: ${msg.totalElapsedTime}');
      print('  totalDistance: ${msg.totalDistance}');
      print('  avgPower: ${msg.avgPower}');
      print('  avgSpeed: ${msg.avgSpeed}');
      print('  maxSpeed: ${msg.maxSpeed}');
      print('  sport: ${msg.sport}');
      print('  subSport: ${msg.subSport}');
      print('');
      print('  📊 INTERPRETATION:');
      if (msg.totalTimerTime != null) {
        print('    Time as seconds: ${msg.totalTimerTime! / 1000} s');
        print('    Time as minutes: ${msg.totalTimerTime! / 60000} min');
      }
      if (msg.totalDistance != null) {
        print('    Distance as meters: ${msg.totalDistance! / 100} m');
        print('    Distance as km: ${msg.totalDistance! / 100000} km');
      }
      print('');
    }
    
    if (msg is ActivityMessage) {
      print('✅ ACTIVITY MESSAGE:');
      print('  totalTimerTime: ${msg.totalTimerTime}');
      print('  numSessions: ${msg.numSessions}');
      print('  type: ${msg.type}');
      print('  event: ${msg.event}');
      print('  eventType: ${msg.eventType}');
      print('');
    }
    
    if (msg is LapMessage) {
      print('✅ LAP MESSAGE:');
      print('  totalTimerTime: ${msg.totalTimerTime}');
      print('  totalElapsedTime: ${msg.totalElapsedTime}');
      print('  totalDistance: ${msg.totalDistance}');
      print('  avgPower: ${msg.avgPower}');
      print('');
    }
    
    if (msg is RecordMessage) {
      print('First Record: distance=${msg.distance}, speed=${msg.speed}');
      break;
    }
  }
  
  print('🎯 QUESTION: What values does THIS file show on Strava?');
}
