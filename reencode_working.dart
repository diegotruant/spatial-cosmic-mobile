import 'dart:io';
import 'package:fit_tool/fit_tool.dart';

void main() async {
  print('🔄 RE-ENCODING WORKING FILE');
  print('=' * 60);

  final inputFile = File('C:/Users/Diego Truant/Desktop/Threshold_XCM_Steps.fit');
  if (!inputFile.existsSync()) {
    print('❌ File not found!');
    return;
  }

  final bytes = await inputFile.readAsBytes();
  final fitFile = FitFile.fromBytes(bytes);
  
  final builder = FitFileBuilder();

  int msgCount = 0;
  for (final record in fitFile.records) {
    final msg = record.message;
    // definition messages are handled automatically by builder
    // generic Record (data) messages need to be added
    
    // We filter to standard messages to avoid issues with unknown developer fields for now,
    // unless we want to test exact replication.
    // Let's rely on fit_tool's ability to handle standard messages.
    
    // Note: builder.add() takes a Message.
    if (msg is DefinitionMessage) continue; // Skip definitions, builder generates them
    
    builder.add(msg);
    msgCount++;
    }
  
  print('Added $msgCount messages to builder.');
  
  final newFile = builder.build();
  const outputPath = 'C:/Users/Diego Truant/Desktop/Threshold_ReEncoded.fit';
  await File(outputPath).writeAsBytes(newFile.toBytes());
  
  print('✅ GENERATED: $outputPath');
  print('📤 PLEASE UPLOAD THIS TO STRAVA!');
  print('   If this FAILS, the issue is in fit_tool.');
  print('   If this WORKS, the issue is in how we construct our messages.');
}
