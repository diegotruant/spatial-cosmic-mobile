import 'dart:io';
import 'package:fit_tool/fit_tool.dart';
import 'dart:math' as math;

void main() async {
  final file = File('../cycling-coach-platform/1770398355836.fit');
  if (!file.existsSync()) {
    print('File not found');
    return;
  }
  
  final bytes = await file.readAsBytes();
  final fitFile = FitFile.fromBytes(bytes);
  
  print('=== POWER ANALYSIS ===\n');
  
  // Extract all power values from records
  List<int> powers = [];
  for (final record in fitFile.records) {
    if (record.message is RecordMessage) {
      final m = record.message as RecordMessage;
      if (m.power != null && m.power! > 0) {
        powers.add(m.power!);
      }
    }
  }
  
  if (powers.isEmpty) {
    print('No power data found in records!');
    return;
  }
  
  // Calculate statistics
  int sum = powers.fold(0, (a, b) => a + b);
  double avgPower = sum / powers.length;
  int maxPower = powers.fold(0, (a, b) => a > b ? a : b);
  int minPower = powers.fold(99999, (a, b) => a < b ? a : b);
  
  print('Total Records with Power: ${powers.length}');
  print('Average Power (calculated): ${avgPower.toStringAsFixed(1)}W');
  print('Max Power: ${maxPower}W');
  print('Min Power: ${minPower}W');
  print('');
  
  // Calculate Normalized Power (NP)
  // NP = (average of (30s rolling avg)^4)^(1/4)
  List<double> thirtySecRollingAvg = [];
  for (int i = 29; i < powers.length; i++) {
    double sum30 = 0;
    for (int j = i - 29; j <= i; j++) {
      sum30 += powers[j];
    }
    thirtySecRollingAvg.add(sum30 / 30);
  }
  
  if (thirtySecRollingAvg.isNotEmpty) {
    double sumOfFourthPower = 0;
    for (var avg in thirtySecRollingAvg) {
      sumOfFourthPower += math.pow(avg, 4);
    }
    double np = math.pow(sumOfFourthPower / thirtySecRollingAvg.length, 1/4).toDouble();
    print('Normalized Power (calculated): ${np.toStringAsFixed(1)}W');
  }
  print('');
  
  // Check what's in Session message
  for (final record in fitFile.records) {
    if (record.message is SessionMessage) {
      final s = record.message as SessionMessage;
      print('SessionMessage avgPower: ${s.avgPower}W');
      print('SessionMessage maxPower: ${s.maxPower}W');
      print('SessionMessage normalizedPower: ${s.normalizedPower}W');
      print('');
      
      print('COMPARISON:');
      print('  Calculated Avg: ${avgPower.toStringAsFixed(1)}W');
      print('  Session Avg:    ${s.avgPower}W');
      print('  Difference:     ${(avgPower - (s.avgPower ?? 0)).toStringAsFixed(1)}W');
    }
  }
}

