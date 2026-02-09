import 'dart:io';
import 'package:fit_tool/fit_tool.dart';

void main() async {
  print('🧪 TESTING LARGE TIMESTAMP (1.14 Billion)');
  
  final builder = FitFileBuilder();
  
  int testTime = 1140000000; // Approx 2026 in FIT Epoch
  
  builder.add(FileIdMessage()..type = FileType.activity..manufacturer = 1..product = 1..timeCreated = testTime..serialNumber = 1);
  
  builder.add(RecordMessage()..timestamp = testTime);
  
  final bytes = builder.build().toBytes();
  final fitFile = FitFile.fromBytes(bytes);
  
  for (final record in fitFile.records) {
    if (record.message is RecordMessage) {
      final msg = record.message as RecordMessage;
      print('Input: $testTime');
      print('Read back: ${msg.timestamp}');
      
      if (msg.timestamp == testTime * 1000) {
         print('✅ SCALED BY 1000: ${msg.timestamp}');
      } else if (msg.timestamp == testTime) {
         print('✅ RAW VALUE KEPT: ${msg.timestamp}');
      } else {
         print('❌ UNEXPECTED: ${msg.timestamp}');
         // Diff
         print('Diff: ${msg.timestamp! - (testTime * 1000)}');
      }
    }
  }
}
