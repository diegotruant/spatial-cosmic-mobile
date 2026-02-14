import 'package:fit_tool/fit_tool.dart';

void main() async {
  print('🧪 TESTING TIMESTAMP OFFSET');
  
  // 4294967296000 = (2^32) * 1000
  // Input 1 -> (2^32 + 0) * 1000 ??
  // Or Input 1 -> (2^32) * 1000 + 1000 ??
  // If Input 0 -> 4294967296000 ??
  
  final builder = FitFileBuilder();
  builder.add(FileIdMessage()..type = FileType.activity..manufacturer = 1..product = 1..timeCreated = 1..serialNumber = 1);
  
  builder.add(RecordMessage()..timestamp = 0);
  builder.add(RecordMessage()..timestamp = 1);
  builder.add(RecordMessage()..timestamp = 2);
  
  // Try negative?
  // builder.add(RecordMessage()..timestamp = -1);
  
  final bytes = builder.build().toBytes();
  final fitFile = FitFile.fromBytes(bytes);
  
  for (final record in fitFile.records) {
    if (record.message is RecordMessage) {
      final msg = record.message as RecordMessage;
      print('Timestamp Readback: ${msg.timestamp}');
    }
  }
}
