import 'dart:io';
import 'package:fit_tool/fit_tool.dart';

void main() async {
  print('🧪 TESTING TIMESTAMP SCALE FACTOR');
  
  final builder = FitFileBuilder();
  
  // Test 1: Timestamp = 1
  builder.add(FileIdMessage()
    ..type = FileType.activity
    ..manufacturer = 1
    ..product = 1
    ..timeCreated = 123456
    ..serialNumber = 123
  );
  
  builder.add(RecordMessage()
    ..timestamp = 1 // 1 second?
  );
  
  final bytes = builder.build().toBytes();
  final fitFile = FitFile.fromBytes(bytes);
  
  for (final record in fitFile.records) {
    if (record.message is RecordMessage) {
      final msg = record.message as RecordMessage;
      print('Input: 1');
      print('Read back: ${msg.timestamp}');
      
      if (msg.timestamp == 1000) {
        print('✅ CONFIRMED: fit_tool scales timestamp by 1000 (Seconds -> Milliseconds)');
      } else {
        print('❌ Value is: ${msg.timestamp}');
      }
    }
  }
}
