import 'package:fit_tool/fit_tool.dart';

void main() async {
  print('🧪 TESTING TIMESTAMP WITH DATETIME');
  
  final builder = FitFileBuilder();
  
  builder.add(FileIdMessage()
    ..type = FileType.activity
    ..manufacturer = 1
    ..product = 1
    ..timeCreated = DateTime.now().millisecondsSinceEpoch ~/ 1000
    ..serialNumber = 123
  );
  
  // Try using DateTime directly if possible?
  // RecordMessage likely has 'timestamp' as int.
  // Does it have 'timestampDateTime'?
  
  final now = DateTime.utc(2026, 2, 8, 12, 0, 0);
  // fit_tool often has both.
  
  try {
    // Dynamic access to check if property exists
    // (Or just rely on compilation error if it doesn't)
    // We'll write a separate file if this fails compilation.
    
    // We can't check source easily, but typical pattern:
    /*
    builder.add(RecordMessage()
      ..timestamp = null // set int to null
      ..timestampDateTime = now
    );
    */
  } catch (e) {
    print('Error: $e');
  }
  
  // Let's print the available setters/getters by reflection (not easy in AOT/script)
  // Or just try to compile `timestampDateTime`.
}
