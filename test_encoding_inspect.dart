import 'dart:io';
import 'package:fit_tool/fit_tool.dart';

void main() async {
  print('🧪 TESTING FIT_TOOL DEFAULT SCALES (Inspection)');
  
  final builder = FitFileBuilder();
  
  builder.add(FileIdMessage()
    ..type = FileType.activity
    ..manufacturer = 1
    ..product = 1
    ..timeCreated = DateTime.now().millisecondsSinceEpoch ~/ 1000
    ..serialNumber = 123
  );
  
  builder.add(SessionMessage()
    ..totalTimerTime = 1000.0 
    ..totalDistance = 1000.0 
  );
  
  final fileBytes = builder.build().toBytes();
  final fitFile = FitFile.fromBytes(fileBytes);
  
  for (final record in fitFile.records) {
    if (record.message is DefinitionMessage) {
      final def = record.message as DefinitionMessage;
      if (def.globalId == 18) { // Session
        print('🔹 SessionMessage Definition found:');
        for (final field in def.fieldDefinitions) {
          if (field.id == 7) { 
            print('   - field_def (ID 7):');
            // Try to extract info from toString since we can't access fields directly
            print('     ${field.toString()}');
          }
           if (field.id == 9) { 
            print('   - field_def (ID 9):');
            print('     ${field.toString()}');
          }
        }
      }
    }
  }
}
