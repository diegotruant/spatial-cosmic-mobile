import 'dart:io';
import 'package:fit_tool/fit_tool.dart';

void main() async {
  final file = File('../cycling-coach-platform/1770398355836.fit');
  if (!file.existsSync()) return;
  
  final bytes = await file.readAsBytes();
  print('File size: ${bytes.length} bytes\n');
  
  // Check raw hex for avgPower field in binary
  // This will help us understand if scale factor is applied
  
  final fitFile = FitFile.fromBytes(bytes);
  
  print('=== CHECKING ALL POWER FIELDS ===\n');
  
  for (final record in fitFile.records) {
    final msg = record.message;
    
    if (msg is SessionMessage) {
      print('SessionMessage:');
      print('  avgPower: ${msg.avgPower}');
      print('  maxPower: ${msg.maxPower}');
      print('  normalizedPower: ${msg.normalizedPower}');
      print('  totalWork: ${msg.totalWork}');
      print('');
      
      // Expected values
      print('EXPECTED (if scale factor = 1):');
      print('  avgPower should be: 197');
      print('  Strava shows: 94');
      print('  Ratio: ${197 / 94} (≈ 2.09)');
      print('');
      
      print('HYPOTHESIS:');
      print('  If Strava divides by 2 → we need to multiply by 2?');
      print('  197 * 2 = 394 (then Strava / 2 = 197) ❌ No');
      print('  If scale issue, 94 * 2 = 188W (close to 197)');
    }
    
    if (msg is LapMessage) {
      print('LapMessage:');
      print('  avgPower: ${msg.avgPower}');
      print('  maxPower: ${msg.maxPower}');
      print('  normalizedPower: ${msg.normalizedPower}');
      print('');
    }
  }
  
  // Sample a few record messages
  print('\n=== SAMPLE RECORD MESSAGES (first 5) ===\n');
  int count = 0;
  for (final record in fitFile.records) {
    if (record.message is RecordMessage && count < 5) {
      final r = record.message as RecordMessage;
      print('Record ${count + 1}: power=${r.power}W, speed=${r.speed}m/s, hr=${r.heartRate}');
      count++;
    }
  }
}
