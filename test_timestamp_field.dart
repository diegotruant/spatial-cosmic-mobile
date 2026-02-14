import 'package:fit_tool/fit_tool.dart';
import 'dart:typed_data';

void main() async {
  print('🧪 TESTING TIMESTAMP FIELD ENCODING');
  
  final builder = FitFileBuilder();
  
  // Test 1: Small timestamp
  int testTime = 1000;
  
  builder.add(FileIdMessage()
    ..type = FileType.activity
    ..manufacturer = 1
    ..product = 1
    ..timeCreated = 123456
    ..serialNumber = 123
  );
  
  builder.add(RecordMessage()
    ..timestamp = testTime
    ..distance = 0.0
  );
  
  final bytes = builder.build().toBytes();
  final byteList = Uint8List.fromList(bytes);
  
  // Search for 1000 (0xE8 0x03)
  bool found1000 = searchBytes(byteList, [0xE8, 0x03, 0x00, 0x00]);
  
  print('Input Timestamp: $testTime');
  if (found1000) {
     print('✅ Found 1000 in binary -> Raw encoding used.');
  } else {
     print('❌ Did NOT find 1000 in binary.');
     // Dump bytes around record?
  }
  
  // Read back
  final fitFile = FitFile.fromBytes(bytes);
  for (final record in fitFile.records) {
    if (record.message is RecordMessage) {
      final msg = record.message as RecordMessage;
      print('Read back Timestamp: ${msg.timestamp}');
      print('Type: ${msg.timestamp.runtimeType}');
    }
  }
}

bool searchBytes(Uint8List data, List<int> pattern) {
  for (int i = 0; i < data.length - pattern.length; i++) {
    bool match = true;
    for (int j = 0; j < pattern.length; j++) {
      if (data[i + j] != pattern[j]) {
        match = false;
        break;
      }
    }
    if (match) return true;
  }
  return false;
}
