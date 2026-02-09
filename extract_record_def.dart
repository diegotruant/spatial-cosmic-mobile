import 'dart:io';
import 'package:fit_tool/fit_tool.dart';

void main() async {
  print('🔍 EXTRACTING RECORD MESSAGE DEFINITION');
  
  final file = File('C:/Users/Diego Truant/Desktop/Workout_RAW_WITH_LAP.fit');
  final bytes = await file.readAsBytes();
  final fitFile = FitFile.fromBytes(bytes);
  
  for (final record in fitFile.records) {
    if (record.message is DefinitionMessage) {
      final def = record.message as DefinitionMessage;
      
      // Record Message is global ID 20
      if (def.globalId == 20) {
        print('🔹 RecordMessage Definition found:');
        for (final field in def.fieldDefinitions) {
          if (field.id == 253) { // timestamp
            print('   - timestamp (ID 253):');
            print('     ${field.toString()}'); 
            // toString might not show scale, but let's see.
            // If fieldDefinition properties are accessible?
            // Only size and baseType usually.
          }
        }
      }
    }
  }
}
