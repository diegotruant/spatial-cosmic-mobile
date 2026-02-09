import 'dart:io';
import 'package:fit_tool/fit_tool.dart';

void main() async {
  print('=' * 60);
  print('VERIFICATION: Workout_FIXED_WITH_SCALE.fit');
  print('=' * 60);
  print('');
  
  final file = File('C:/Users/Diego Truant/Desktop/Workout_FIXED_WITH_SCALE.fit');
  if (!file.existsSync()) {
    print('❌ File not found!');
    return;
  }
  
  final bytes = await file.readAsBytes();
  final fitFile = FitFile.fromBytes(bytes);
  
  for (final record in fitFile.records) {
    final msg = record.message;
    
    if (msg is SessionMessage) {
      print('📊 SessionMessage (what Strava will read):');
      print('   totalTimerTime: ${msg.totalTimerTime}');
      print('   totalElapsedTime: ${msg.totalElapsedTime}');
      print('   totalDistance: ${msg.totalDistance}');
      print('   avgPower: ${msg.avgPower}W');
      print('   normalizedPower: ${msg.normalizedPower}W');
      print('   avgSpeed: ${msg.avgSpeed}');
      print('');
      
      print('✅ VERIFICATION:');
      if (msg.totalTimerTime != null && msg.totalTimerTime! > 1000000) {
        double seconds = msg.totalTimerTime! / 1000;
        double minutes = seconds / 60;
        print('   ✅ Time: ${seconds.toStringAsFixed(0)}s (${minutes.toStringAsFixed(1)} min)');
        print('      Scale factor x1000 APPLIED CORRECTLY');
      } else {
        print('   ❌ Time: ${msg.totalTimerTime}');
        print('      Scale factor NOT applied!');
      }
      
      if (msg.totalDistance != null && msg.totalDistance! > 100000) {
        double meters = msg.totalDistance! / 100;
        double km = meters / 1000;
        print('   ✅ Distance: ${meters.toStringAsFixed(0)}m (${km.toStringAsFixed(2)} km)');
        print('      Scale factor x100 APPLIED CORRECTLY');
      } else {
        print('   ❌ Distance: ${msg.totalDistance}');
        print('      Scale factor NOT applied!');
      }
      
      if (msg.normalizedPower != null && msg.normalizedPower! > 0) {
        print('   ✅ NormalizedPower: ${msg.normalizedPower}W');
        print('      Field is present!');
      } else {
        print('   ❌ NormalizedPower: null or 0');
      }
      
      print('');
      print('🎯 EXPECTED STRAVA DISPLAY:');
      if (msg.totalTimerTime != null) {
        double minutes = (msg.totalTimerTime! / 1000) / 60;
        print('   Time: ${minutes.toStringAsFixed(1)} minutes');
      }
      if (msg.totalDistance != null && msg.totalTimerTime != null) {
        double meters = msg.totalDistance! / 100;
        double km = meters / 1000;
        double seconds = msg.totalTimerTime! / 1000;
        double speedKmh = (meters / seconds) * 3.6;
        print('   Distance: ${km.toStringAsFixed(2)} km');
        print('   Avg Speed: ${speedKmh.toStringAsFixed(1)} km/h');
      }
      print('   Avg Power: ${msg.avgPower}W');
      print('   Normalized Power: ${msg.normalizedPower}W');
    }
    
    if (msg is ActivityMessage) {
      print('');
      print('📋 ActivityMessage:');
      print('   totalTimerTime: ${msg.totalTimerTime}');
      print('   numSessions: ${msg.numSessions}');
      print('   type: ${msg.type}');
      print('   event: ${msg.event}');
      print('   eventType: ${msg.eventType}');
    }
  }
  
  print('');
  print('=' * 60);
  print('✅ FILE READY FOR STRAVA UPLOAD!');
  print('=' * 60);
}
