import 'dart:io';
import 'package:fit_tool/fit_tool.dart';

void main() async {
  final file = File('../cycling-coach-platform/1770398355836.fit');
  if (!file.existsSync()) {
    print('File not found: ${file.path}');
    return;
  }
  
  final bytes = await file.readAsBytes();
  print('File size: ${bytes.length} bytes');
  
  final fitFile = FitFile.fromBytes(bytes);
  
  print('\n=== FIT FILE ANALYSIS ===\n');
  
  // Analyze all messages
  for (final record in fitFile.records) {
    final msg = record.message;
    
    if (msg is FileIdMessage) {
      print('FileIdMessage:');
      print('  type: ${msg.type}');
      print('  manufacturer: ${msg.manufacturer}');
      print('  product: ${msg.product}');
      print('  timeCreated: ${msg.timeCreated}');
      print('  serialNumber: ${msg.serialNumber}');
      print('');
    }
    
    if (msg is SessionMessage) {
      print('SessionMessage:');
      print('  timestamp: ${msg.timestamp}');
      print('  startTime: ${msg.startTime}');
      print('  totalTimerTime: ${msg.totalTimerTime} (RAW VALUE)');
      print('  totalElapsedTime: ${msg.totalElapsedTime} (RAW VALUE)');
      print('  totalDistance: ${msg.totalDistance} (RAW VALUE)');
      print('  sport: ${msg.sport}');
      print('  subSport: ${msg.subSport}');
      print('  avgPower: ${msg.avgPower}');
      print('  avgSpeed: ${msg.avgSpeed}');
      print('  avgHeartRate: ${msg.avgHeartRate}');
      print('');
      
      // Calculate expected values
      if (msg.totalTimerTime != null) {
        print('  >>> If totalTimerTime=${msg.totalTimerTime} is in SECONDS:');
        print('      Duration would be: ${(msg.totalTimerTime! / 60).toStringAsFixed(2)} minutes');
        print('  >>> If totalTimerTime=${msg.totalTimerTime} is in MILLISECONDS:');
        print('      Duration would be: ${(msg.totalTimerTime! / 1000 / 60).toStringAsFixed(2)} minutes');
      }
      print('');
    }
    
    if (msg is LapMessage) {
      print('LapMessage:');
      print('  timestamp: ${msg.timestamp}');
      print('  startTime: ${msg.startTime}');
      print('  totalTimerTime: ${msg.totalTimerTime} (RAW VALUE)');
      print('  totalElapsedTime: ${msg.totalElapsedTime} (RAW VALUE)');
      print('  totalDistance: ${msg.totalDistance} (RAW VALUE)');
      print('');
    }
    
    if (msg is ActivityMessage) {
      print('ActivityMessage:');
      print('  timestamp: ${msg.timestamp}');
      print('  totalTimerTime: ${msg.totalTimerTime} (RAW VALUE)');
      print('  numSessions: ${msg.numSessions}');
      print('  type: ${msg.type}');
      print('');
    }
  }
  
  // Count records
  int recordCount = 0;
  for (final record in fitFile.records) {
    if (record.message is RecordMessage) {
      recordCount++;
    }
  }
  print('Total RecordMessages: $recordCount');
  print('Expected duration if 1 record/second: ~${(recordCount / 60).toStringAsFixed(2)} minutes');
}
