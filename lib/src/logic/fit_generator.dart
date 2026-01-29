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
      } else if (block is Ramp) {
        builder.add(WorkoutStepMessage()
          ..messageIndex = stepIndex++
          ..durationValue = block.duration
          ..durationType = WorkoutStepDuration.time
          ..targetType = WorkoutStepTarget.power
          ..customTargetValueLow = (block.powerLow * ftp).round()
          ..customTargetValueHigh = (block.powerHigh * ftp).round());
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
    required List<double> powerHistory,
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

    // ---------------------------------------------------------
    // FIT EPOCH CORRECTION
    // FIT Epoch is Dec 31, 1989 00:00:00 UTC.
    // ---------------------------------------------------------
    final fitEpoch = DateTime.utc(1989, 12, 31, 0, 0, 0).millisecondsSinceEpoch;
    int toFitTime(DateTime dt) => (dt.millisecondsSinceEpoch - fitEpoch) ~/ 1000;





    final startFitTime = toFitTime(startTime);
    final endFitTime = toFitTime(startTime.add(Duration(seconds: durationSeconds)));

    // 1. File ID
    builder.add(FileIdMessage()
      ..type = FileType.activity
      ..manufacturer = Manufacturer.development.value
      ..product = 1
      ..timeCreated = startFitTime
      ..serialNumber = 12345678
    );

    // 2. Event: Timer Start
    builder.add(EventMessage()
      ..timestamp = startFitTime
      ..event = Event.timer
      ..eventType = EventType.start
      ..eventGroup = 0
    );

    // 3. Records
    int maxLength = [powerHistory.length, hrHistory.length, cadenceHistory.length, speedHistory.length].fold<int>(0, (a, b) => a > b ? a : b);

    for (int i = 0; i < maxLength; i++) {
        final recTime = startTime.add(Duration(seconds: i));
        
        final record = RecordMessage()
          ..timestamp = toFitTime(recTime)
          ..power = i < powerHistory.length ? powerHistory[i].toInt() : 0
          ..heartRate = i < hrHistory.length ? hrHistory[i] : 0
          ..cadence = i < cadenceHistory.length ? cadenceHistory[i] : 0
          ..speed = i < speedHistory.length ? speedHistory[i] : 0.0;
        builder.add(record);
    }

    // 4. Event: Timer Stop
    builder.add(EventMessage()
      ..timestamp = endFitTime
      ..event = Event.timer
      ..eventType = EventType.stop
      ..eventGroup = 0
    );

    // Calculate Averages / Max
    int avgHr = 0;
    if (hrHistory.isNotEmpty) avgHr = (hrHistory.fold<int>(0, (a, b) => a + b) / hrHistory.length).round();

    int maxPower = 0;
    if (powerHistory.isNotEmpty) maxPower = powerHistory.fold<double>(0, (a, b) => a > b ? a : b).toInt();

    // 5. Session Message
    // IMPORTANT: startTime must match Timer Start. timestamp must match Timer Stop.
    final sessionMsg = SessionMessage()
      ..messageIndex = 0
      ..timestamp = endFitTime 
      ..startTime = startFitTime
      ..startPositionLat = null
      ..startPositionLong = null
      ..totalElapsedTime = durationSeconds.toDouble()
      ..totalTimerTime = durationSeconds.toDouble()
      ..totalDistance = totalDistance
      ..totalCalories = totalCalories
      ..avgSpeed = speedHistory.isNotEmpty ? (speedHistory.fold<double>(0, (a, b) => a + b) / speedHistory.length) : 0.0
      ..maxSpeed = speedHistory.isNotEmpty ? speedHistory.fold<double>(0, (a, b) => a > b ? a : b) : 0.0
      ..avgHeartRate = avgHr
      ..maxHeartRate = maxHr
      ..avgCadence = cadenceHistory.isNotEmpty ? (cadenceHistory.fold<int>(0, (a, b) => a + b) / cadenceHistory.length).toInt() : 0
      ..maxCadence = cadenceHistory.isNotEmpty ? cadenceHistory.fold<int>(0, (a, b) => a > b ? a : b) : 0
      ..avgPower = avgPower.toInt()
      ..maxPower = maxPower
      ..sport = Sport.cycling
      ..totalAscent = 0;
      // ..event and ..eventType not valid for SessionMessage
      // The presence of a SessionMessage implies the session summary.

    // Note: fit_tool SessionMessage might not have event/eventType if it follows the structure strictly.
    // checking known fields: session usually implies summary.
    builder.add(sessionMsg);

    // 6. Activity Message
    final activityMsg = ActivityMessage()
      ..timestamp = endFitTime
      ..totalTimerTime = durationSeconds.toDouble()
      ..numSessions = 1
      ..type = Activity.manual 
      ..event = Event.activity
      ..eventType = EventType.stop;
      
    builder.add(activityMsg);

    final fitFile = builder.build();
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/activity_${startTime.millisecondsSinceEpoch}_${(workoutTitle ?? "Workout").replaceAll(" ", "_")}.fit');
    await file.writeAsBytes(fitFile.toBytes());

    return file;
  }
}
