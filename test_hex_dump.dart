import 'package:fit_tool/fit_tool.dart';
import 'dart:typed_data';

void main() async {
  print('🧪 TESTING BINARY OUTPUT (HEX DUMP)');
  
  final builder = FitFileBuilder();
  
  // Use unique value to find easily: 0x11223344 = 287454020
  // If Scale 1: 287454020
  // If Scale 1000: 287454020000 (0x42EDF09160) - doesn't fit in uint32? 
  // Wait, if Scale 1000, max value is 4.2e6 seconds (1000 hours). 287454020 is ~79000 hours.
  
  // Let's use a smaller value that fits in uint32 even if scaled.
  // Value: 1000 seconds.
  // If Scale 1: Writes 1000 (0x03E8).
  // If Scale 1000: Writes 1000000 (0x000F4240).
  
  double testValue = 1000.0;
  
  builder.add(FileIdMessage()
    ..type = FileType.activity
    ..manufacturer = 1
    ..product = 1
    ..timeCreated = 123456
    ..serialNumber = 123
  );
  
  builder.add(SessionMessage()
    ..totalTimerTime = testValue
  );
  
  final bytes = builder.build().toBytes();
  final byteList = Uint8List.fromList(bytes);
  
  print('Generated ${bytes.length} bytes.');
  
  // Search for 0x03E8 (1000)
  bool found1000 = searchBytes(byteList, [0xE8, 0x03]); // Little Endian
  
  // Search for 0x0F4240 (1000000) -> 40 42 0F 00
  bool found1M = searchBytes(byteList, [0x40, 0x42, 0x0F]); 
  
  print('Checking encoding of 1000.0:');
  if (found1000) print('  ✅ Found 0x03E8 (1000) -> Scale 1 used (BUG/DEFAULT)');
  if (found1M) print('  ✅ Found 0x0F4240 (1000000) -> Scale 1000 used (CORRECT)');
  
  if (!found1000 && !found1M) {
    print('  ❌ Value not found! Maybe different format?');
    // Dump all bytes
    // print(byteList);
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
