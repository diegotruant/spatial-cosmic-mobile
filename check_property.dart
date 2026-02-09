import 'dart:io';
import 'package:fit_tool/fit_tool.dart';

void main() {
  print('🧪 CHECKING RECORD MESSAGE PROPERTIES');
  
  final msg = RecordMessage();
  // Try to assign DateTime
  // msg.timestampDateTime = DateTime.now(); // Uncomment to test compilation
  
  // Since we can't reflect well in script, let's just print runtime Type of known fields
  print('msg.timestamp type: ${msg.timestamp.runtimeType}');
  
  // Check if we can assign null?
  msg.timestamp = null;
  print('msg.timestamp can be null.');
  
  // To check if 'timestamp' expects ms or s...
  // Usually fit_tool documentation says:
  // "Timestamps are milliseconds since UTC 00:00:00 Dec 31 1989." 
  // Wait. Milliseconds Since 1989?
  
  // If fit_tool expects MS Since 1989.
  // And I passed: 1.14 billion (Seconds Since 1989).
  // Then fit_tool saw 1.14 billion MS = 1.14 million seconds = 13 days.
  // So timestamps were 1990-01-13.
  
  // If check_timestamps read back "4.2 trillion".
  // This means fit_tool read back 4.2 trillion MS.
  
  // If I passed 1.
  // It read back 4.29 billion * 1000.
  
  // This strongly suggests fit_tool expects MS Since 1989!
  // BUT the readback value is garbage.
  
  // Let's try passing MS Since 1989?
  // 1.14 billion SECONDS * 1000 = 1.14 trillion MS.
  
  // If I pass 1.14e12 to `timestamp`.
  // Will it fit in int?
  // 1.14e12 fits in 64-bit int. Dart int is 64-bit.
  // But FIT `timestamp` is uint32 (max 4.29 billion).
  // 1.14 trillion DOES NOT FIT in uint32.
  
  // So `fit_tool` MUST do scaling logic internally.
  // If I pass `DateTime`, it might handle it.
}
