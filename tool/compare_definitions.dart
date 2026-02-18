import 'dart:io';
import 'package:fit_tool/fit_tool.dart';

void main() async {
  print('🔍 COMPARING FIT DEFINITIONS');
  print('=' * 60);

  await analyzeFile('C:/Users/Diego Truant/Desktop/Threshold_XCM_Steps.fit', 'WORKING');
  await analyzeFile('C:/Users/Diego Truant/Desktop/Workout_NO_SCALE.fit', 'NON-WORKING (NO SCALE)');
}

Future<void> analyzeFile(String path, String label) async {
  print('\n📂 FILE: $label ($path)');
  
  final file = File(path);
  if (!file.existsSync()) {
    print('❌ File not found!');
    return;
  }
  
  final bytes = await file.readAsBytes();
  final fitFile = FitFile.fromBytes(bytes);

  for (final record in fitFile.records) {
    if (record.message is DefinitionMessage) {
      final def = record.message as DefinitionMessage;
      
      // Session Message is global ID 18
      if (def.globalId == 18) {
        print('  🔹 SessionMessage Definition (Global ID 18):');
        print('     Architecture: ${def.architecture}');
        print('     Fields: ${def.fieldDefinitions.length}');
        
        for (final field in def.fieldDefinitions) {
          // total_timer_time is field ID 7
          if (field.id == 7) {
            print('       🔸 total_timer_time (ID 7):');
            print('          BaseType: ${field.baseType}'); // e.g., uint32
            print('          Size: ${field.size}');
          }
           // total_distance is field ID 9
          if (field.id == 9) {
            print('       🔸 total_distance (ID 9):');
            print('          BaseType: ${field.baseType}');
            print('          Size: ${field.size}');
          }
        }
      }
      
      // Lap Message is global ID 19
      if (def.globalId == 19) {
         print('  🔹 LapMessage Definition (Global ID 19): found');
      }
    }
  }
}
