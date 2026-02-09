import 'dart:io';
import 'package:fit_tool/fit_tool.dart';

void main() async {
  print('🔍 COMPARING DEFINITIONS (DETAILED)');
  
  await analyze('C:/Users/Diego Truant/Desktop/Threshold_ReEncoded.fit', 'WORKING');
  await analyze('C:/Users/Diego Truant/Desktop/Workout_NO_SCALE.fit', 'FAILING');
}

Future<void> analyze(String path, String label) async {
  print('\n📂 $label ($path)');
  
  final file = File(path);
  if (!file.existsSync()) {
    print('  ❌ File not found');
    return;
  }
  
  final bytes = await file.readAsBytes();
  final fitFile = FitFile.fromBytes(bytes);
  
  for (final record in fitFile.records) {
    if (record.message is DefinitionMessage) {
      final def = record.message as DefinitionMessage;
      
      String? msgName;
      if (def.globalId == 18) msgName = 'Session';
      if (def.globalId == 20) msgName = 'Record';
      
      if (msgName != null) {
        print('  🔹 $msgName Definition (ID ${def.globalId}):');
        print('     Architecture: ${def.architecture}');
        print('     Fields: ${def.fieldDefinitions.length}');
        for (final field in def.fieldDefinitions) {
          print('       - ID ${field.id}: Size ${field.size}, BaseType ${field.baseType}');
        }
      }
    }
  }
}
