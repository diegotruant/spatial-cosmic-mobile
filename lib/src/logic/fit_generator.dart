import 'dart:io';
import 'dart:math';
import 'package:fit_tool/fit_tool.dart';
import 'package:spatial_cosmic_mobile/src/logic/zwo_parser.dart';
import 'package:path_provider/path_provider.dart';

class FitGenerator {
  /// Generates a .fit file from a Workout object and returns its File path.
  static Future<File> generateWorkoutFit(WorkoutWorkout workout, int ftp) async {
    final bytes = toBytes(workout, ftp);
    
    // Save to temporary directory
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/${workout.title.replaceAll(' ', '_')}.fit');
    await file.writeAsBytes(bytes);
    
    return file;
  }

  /// Helper to generate the binary FIT data directly
  static List<int> toBytes(WorkoutWorkout workout, int ftp) {
    final builder = FitFileBuilder();
    
    // 1. File ID
    builder.add(FileIdMessage()
      ..type = FileType.workout
      ..manufacturer = Manufacturer.development.value
      ..product = 1
      ..timeCreated = DateTime.now().millisecondsSinceEpoch ~/ 1000
      ..serialNumber = 12345678);

    // 2. Workout Message
    builder.add(WorkoutMessage()
      ..workoutName = workout.title
      ..numValidSteps = workout.blocks.length);

    // 3. Steps
    int stepIndex = 0;
    for (var block in workout.blocks) {
      if (block is SteadyState) {
        builder.add(WorkoutStepMessage()
          ..messageIndex = stepIndex++
          ..durationValue = block.duration
          ..durationType = WorkoutStepDuration.time
          ..targetType = WorkoutStepTarget.power
          ..customTargetValueLow = (block.power * ftp * 0.95).round()
          ..customTargetValueHigh = (block.power * ftp * 1.05).round());
      } else if (block is IntervalsT) {
        for (int r = 0; r < block.repeat; r++) {
          builder.add(WorkoutStepMessage()
            ..messageIndex = stepIndex++
            ..durationValue = block.onDuration
            ..durationType = WorkoutStepDuration.time
            ..targetType = WorkoutStepTarget.power
            ..customTargetValueLow = (block.onPower * ftp * 0.95).round()
            ..customTargetValueHigh = (block.onPower * ftp * 1.05).round());

          builder.add(WorkoutStepMessage()
            ..messageIndex = stepIndex++
            ..durationValue = block.offDuration
            ..durationType = WorkoutStepDuration.time
            ..targetType = WorkoutStepTarget.power
            ..customTargetValueLow = (block.offPower * ftp * 0.95).round()
            ..customTargetValueHigh = (block.offPower * ftp * 1.05).round());
        }
      }
    }
    
    return builder.build().toBytes();
  }

  /// Generates a .fit file from a Supabase assignment (JSON structure)
  static Future<File> generateFromAssignment(Map<String, dynamic> assignment, int ftp) async {
    // robust parsing via ZwoParser
    final workout = ZwoParser.parseJson(assignment);
    return generateWorkoutFit(workout, ftp);
  }

  /// Generates a .fit file from recorded activity data
  static Future<File> generateActivityFit({
    required List<num> powerHistory,
    required List<int> hrHistory,
    required List<int> cadenceHistory,
    required List<double> speedHistory,
    required double avgPower,
    required int maxHr,
    required int durationSeconds,
    required double totalDistance,
    required int totalCalories,
    required DateTime startTime,
    String? workoutTitle,
  }) async {
    final builder = FitFileBuilder();

    // 1. File ID
    final fileIdMessage = FileIdMessage()
      ..type = FileType.activity
      ..manufacturer = Manufacturer.development.value
      ..product = 1
      ..timeCreated = startTime.millisecondsSinceEpoch ~/ 1000
      ..serialNumber = 12345678;
    builder.add(fileIdMessage);

    // 2. Activity / Session (Simplified for now)
    int maxLength = [
      powerHistory.length,
      hrHistory.length,
      cadenceHistory.length,
      speedHistory.length
    ].reduce(max);

    for (int i = 0; i < maxLength; i++) {
        final record = RecordMessage()
          ..timestamp = (startTime.millisecondsSinceEpoch ~/ 1000) + i
          ..power = i < powerHistory.length ? powerHistory[i].toInt() : 0
          ..heartRate = i < hrHistory.length ? hrHistory[i] : 0
          ..cadence = i < cadenceHistory.length ? cadenceHistory[i] : 0
          ..speed = i < speedHistory.length ? speedHistory[i] : 0.0;
        builder.add(record);
    }

    final fitFile = builder.build();
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/activity_${startTime.millisecondsSinceEpoch}_${(workoutTitle ?? "Workout").replaceAll(" ", "_")}.fit');
    await file.writeAsBytes(fitFile.toBytes());

    return file;
  }
}
