import 'dart:io';
import 'package:fit_tool/fit_tool.dart';

void main() async {
  print('🔍 ANALYZING WORKING FIT FILE: Threshold_XCM_Steps.fit');
  print('=' * 60);

  final file = File('C:/Users/Diego Truant/Desktop/Threshold_XCM_Steps.fit');
  if (!file.existsSync()) {
    print('❌ File not found!');
    return;
  }

  final bytes = await file.readAsBytes();
  final fitFile = FitFile.fromBytes(bytes);

  // Analyze Session Messages
  for (final record in fitFile.records) {
    if (record.message is SessionMessage) {
      final msg = record.message as SessionMessage;
      print('📊 SessionMessage:');
      print('  totalTimerTime: ${msg.totalTimerTime} (isScaled: ${(msg.totalTimerTime ?? 0) > 100000})');
      print('  totalElapsedTime: ${msg.totalElapsedTime}');
      print('  totalDistance: ${msg.totalDistance}');
      print('  avgPower: ${msg.avgPower}');
      print('  normalizedPower: ${msg.normalizedPower}');
      print('  avgSpeed: ${msg.avgSpeed}');
      print('  maxSpeed: ${msg.maxSpeed}');
      print('');
    }
  }

  // Analyze Definition Message for scale knowledge?
  // fit_tool hides definitions unless we dig deep, but let's assume default profile.

  // Analyze Activity Message
  for (final record in fitFile.records) {
    if (record.message is ActivityMessage) {
      final msg = record.message as ActivityMessage;
      print('✅ ActivityMessage:');
      print('  totalTimerTime: ${msg.totalTimerTime}');
      print('  type: ${msg.type}');
      print('  event: ${msg.event}');
      print('  eventType: ${msg.eventType}');
      print('');
    }
  }

  // Analyze Lap Message
  for (final record in fitFile.records) {
    if (record.message is LapMessage) {
      final msg = record.message as LapMessage;
      print('✅ LapMessage:');
      print('  totalTimerTime: ${msg.totalTimerTime}');
      print('  totalDistance: ${msg.totalDistance}');
      print('  avgPower: ${msg.avgPower}');
      print('  normalizedPower: ${msg.normalizedPower}');
      print('');
    }
  }

  // Check first record
  for (final record in fitFile.records) {
    if (record.message is RecordMessage) {
      final msg = record.message as RecordMessage;
      print('First Record:');
      print('  distance: ${msg.distance}');
      print('  speed: ${msg.speed}');
      print('  power: ${msg.power}');
      break;
    }
  }
}
