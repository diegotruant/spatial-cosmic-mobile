import 'package:fit_tool/fit_tool.dart';

void main() {
  final msg = RecordMessage();
  // Try to use timestampDateTime
  // Use explicit cast if necessary or just property access
  // msg.timestampDateTime = DateTime.now(); 
  
  // Checking via dynamic to avoid instant crash, but valid dart code
  try {
    (msg as dynamic).timestampDateTime = DateTime.now();
    print('✅ SUCCESS: timestampDateTime setter exists!');
  } catch (e) {
    print('❌ FAILURE: timestampDateTime setter missing. Error: $e');
  }
}
