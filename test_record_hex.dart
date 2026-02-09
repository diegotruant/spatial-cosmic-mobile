import 'dart:io';
import 'package:fit_tool/fit_tool.dart';
import 'dart:typed_data';

void main() async {
  print('🧪 TESTING RECORD MESSAGE ENCODING (HEX DUMP)');
  
  final builder = FitFileBuilder();
  
  // Test Value: 1000.0 meters.
  // If Scale 100 (Standard for distance): Should write 100000 (0x0186A0).
  // If Scale 1 (Bug): Should write 1000 (0x03E8).
  
  double testDist = 1000.0;
  
  builder.add(FileIdMessage()
    ..type = FileType.activity
    ..manufacturer = 1
    ..product = 1
    ..timeCreated = 123456
    ..serialNumber = 123
  );
  
  builder.add(RecordMessage()
    ..timestamp = 1000
    ..distance = testDist
  );
  
  final bytes = builder.build().toBytes();
  final byteList = Uint8List.fromList(bytes);
  
  bool found1000 = searchBytes(byteList, [0xE8, 0x03]); 
  bool found100k = searchBytes(byteList, [0xA0, 0x86, 0x01]); 
  
  print('Checking encoding of Record.distance = 1000.0:');
  if (found1000) print('  ✅ Found 0x03E8 (1000) -> Scale 1 used (BUG in RecordMessage)');
  if (found100k) print('  ✅ Found 0x186A0 (100000) -> Scale 100 used (CORRECT)');
  
  if (!found1000 && !found100k) {
    print('  ❌ Value not found!');
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
