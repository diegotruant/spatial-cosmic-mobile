
import 'dart:io';
import 'package:fit_tool/fit_tool.dart';

void main() async {
  final file = File('../cycling-coach-platform/1770398355836.fit');
  if (!file.existsSync()) return;
  final bytes = await file.readAsBytes();
  final fitFile = FitFile.fromBytes(bytes);
  
  final List<int> powers = [];
  final List<int> hrs = [];
  final List<int> cads = [];
  DateTime? startTime;

  for (final record in fitFile.records) {
    if (record.message is RecordMessage) {
      final m = record.message as RecordMessage;
      powers.add(m.power ?? 0);
      hrs.add(m.heartRate ?? 0);
      cads.add(m.cadence ?? 0);
      if (startTime == null && m.timestamp != null) {
        startTime = DateTime.fromMillisecondsSinceEpoch((m.timestamp! + 631065600) * 1000);
      }
    }
  }
  if (startTime == null) startTime = DateTime.now();

  final buffer = StringBuffer();
  buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
  buffer.writeln('<TrainingCenterDatabase xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2">');
  buffer.writeln('  <Activities>');
  buffer.writeln('    <Activity Sport="Cycling">');
  buffer.writeln('      <Id>${startTime.toIso8601String()}</Id>');
  buffer.writeln('      <Lap StartTime="${startTime.toIso8601String()}">');
  buffer.writeln('        <TotalTimeSeconds>${powers.length}</TotalTimeSeconds>');
  buffer.writeln('        <DistanceMeters>${(powers.length * 8.5).toInt()}</DistanceMeters>');
  buffer.writeln('        <Calories>800</Calories>');
  buffer.writeln('        <Intensity>Active</Intensity>');
  buffer.writeln('        <TriggerMethod>Manual</TriggerMethod>');
  buffer.writeln('        <Track>');

  for (int i = 0; i < powers.length; i++) {
    final t = startTime.add(Duration(seconds: i)).toUtc().toIso8601String();
    buffer.writeln('          <Trackpoint>');
    buffer.writeln('            <Time>$t</Time>');
    buffer.writeln('            <HeartRateBpm><Value>${hrs[i] > 0 ? hrs[i] : 130}</Value></HeartRateBpm>');
    buffer.writeln('            <Cadence>${cads[i]}</Cadence>');
    buffer.writeln('            <Extensions>');
    buffer.writeln('              <TPX xmlns="http://www.garmin.com/xmlschemas/ActivityExtension/v2">');
    buffer.writeln('                <Watts>${powers[i]}</Watts>');
    buffer.writeln('              </TPX>');
    buffer.writeln('            </Extensions>');
    buffer.writeln('          </Trackpoint>');
  }

  buffer.writeln('        </Track>');
  buffer.writeln('      </Lap>');
  buffer.writeln('    </Activity>');
  buffer.writeln('  </Activities>');
  buffer.writeln('</TrainingCenterDatabase>');

  await File('C:/Users/Diego Truant/Desktop/Allenamento_RECUPERATO_DEFINITIVO.tcx').writeAsString(buffer.toString());
  print('FILE TCX GENERATO SUL DESKTOP');
}
