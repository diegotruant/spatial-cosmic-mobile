import 'dart:io';
import 'package:fit_tool/fit_tool.dart';

void main() async {
  print('ANALYZING: test_correct_encoding.fit');
  print('==========================================\n');
  
  final file = File('test_correct_encoding.fit');
  final bytes = await file.readAsBytes();
  final fitFile = FitFile.fromBytes(bytes);
  
  for (final record in fitFile.records) {
    final msg = record.message;
    
    if (msg is SessionMessage) {
      print('SessionMessage:');
      print('  totalTimerTime: ${msg.totalTimerTime}');
      print('  totalElapsedTime: ${msg.totalElapsedTime}');
      print('  totalDistance: ${msg.totalDistance}');
      print('');
      
      print('INTERPRETATION CHECK:');
      if (msg.totalTimerTime != null) {
        print('  If ${msg.totalTimerTime} is SECONDS → ${(msg.totalTimerTime! / 60).toStringAsFixed(2)} minutes ✅');
        print('  If ${msg.totalTimerTime} is MILLISECONDS → ${(msg.totalTimerTime! / 1000 / 60).toStringAsFixed(2)} minutes ❌');
      }
    }
  }
  
  print('\n==========================================');
  print('NOW ANALYZING ORIGINAL PROBLEMATIC FILE');
  print('==========================================\n');
  
  final originalFile = File('../cycling-coach-platform/1770398355836.fit');
  if (originalFile.existsSync()) {
    final originalBytes = await originalFile.readAsBytes();
    final originalFitFile = FitFile.fromBytes(originalBytes);
    
    for (final record in originalFitFile.records) {
      final msg = record.message;
      
      if (msg is SessionMessage) {
        print('SessionMessage (ORIGINAL):');
        print('  totalTimerTime: ${msg.totalTimerTime}');
        print('  totalElapsedTime: ${msg.totalElapsedTime}');
        print('  totalDistance: ${msg.totalDistance}');
      }
    }
  }
}
