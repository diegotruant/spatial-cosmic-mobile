import 'dart:io';
import 'package:fit_tool/fit_tool.dart';

void main() async {
  print('🔍 COMPLETE ORIGINAL FIT FILE DUMP');
  print('=' * 60);
  
  final file = File('../cycling-coach-platform/1770398355836.fit');
  final bytes = await file.readAsBytes();
  final fitFile = FitFile.fromBytes(bytes);
  
  Map<String, int> messageCounts = {};
  
  for (final record in fitFile.records) {
    final msgType = record.message.runtimeType.toString();
    messageCounts[msgType] = (messageCounts[msgType] ?? 0) + 1;
    
    final msg = record.message;
    
    if (msg is FileIdMessage) {
      print('📄 FileIdMessage:');
      print('  type: ${msg.type}');
      print('  manufacturer: ${msg.manufacturer}');
      print('  product: ${msg.product}');
      print('  timeCreated: ${msg.timeCreated}');
      print('');
    }
    
    if (msg is SessionMessage) {
      print('📊 SessionMessage:');
      print('  totalTimerTime: ${msg.totalTimerTime}');
      print('  totalDistance: ${msg.totalDistance}');
      print('  avgPower: ${msg.avgPower}');
      print('');
    }
    
    if (msg is ActivityMessage) {
      print('🏃 ActivityMessage:');
      print('  totalTimerTime: ${msg.totalTimerTime}');
      print('  numSessions: ${msg.numSessions}');
      print('  type: ${msg.type}');
      print('');
    }
    
    if (msg is LapMessage) {
      print('🔄 LapMessage:');
      print('  totalTimerTime: ${msg.totalTimerTime}');
      print('  totalDistance: ${msg.totalDistance}');
      print('');
    }
  }
  
  print('=' * 60);
  print('MESSAGE TYPE SUMMARY:');
  messageCounts.forEach((type, count) {
    print('  $type: $count');
  });
  print('=' * 60);
}
