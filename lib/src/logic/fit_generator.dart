import 'dart:io';
import 'dart:math';
import 'package:fit_tool/fit_tool.dart';
import 'package:spatial_cosmic_mobile/src/logic/zwo_parser.dart';
import 'package:path_provider/path_provider.dart';
import '../services/native_fit_service.dart';

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

  /// Calculate Normalized Power (NP) from power data
  /// Algorithm: NP = (average of (30s rolling avg)^4)^(1/4)
  static int _calculateNormalizedPower(List<double> powerHistory) {
    if (powerHistory.length < 30) {
      // Not enough data for NP calculation, return average
      if (powerHistory.isEmpty) return 0;
      return (powerHistory.fold<double>(0, (a, b) => a + b) / powerHistory.length).round();
    }

    // Calculate 30-second rolling averages
    List<double> rollingAvgs = [];
    for (int i = 29; i < powerHistory.length; i++) {
      double sum = 0;
      for (int j = i - 29; j <= i; j++) {
        sum += powerHistory[j];
      }
      rollingAvgs.add(sum / 30);
    }

    // Raise each rolling average to the 4th power
    double sumOfFourthPower = 0;
    for (var avg in rollingAvgs) {
      sumOfFourthPower += pow(avg, 4);
    }

    // Take the 4th root of the average
    double np = pow(sumOfFourthPower / rollingAvgs.length, 1/4).toDouble();
    return np.round();
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
    List<Map<String, dynamic>>? rrHistory,  // Optional RR intervals
  }) async {
     // Prepare data for Native Service
     List<Map<String, dynamic>> workoutData = [];
     
     int maxLength = [
       powerHistory.length, 
       hrHistory.length, 
       cadenceHistory.length, 
       speedHistory.length
     ].fold<int>(0, (a, b) => a > b ? a : b);

     double cumulativeDistance = 0.0;
     
     for (int i = 0; i < maxLength; i++) {
        // Safe access to lists
        double p = i < powerHistory.length ? powerHistory[i] : 0.0;
        int hr = i < hrHistory.length ? hrHistory[i] : 0;
        int cad = i < cadenceHistory.length ? cadenceHistory[i] : 0;
        double s = i < speedHistory.length ? speedHistory[i] : 0.0; // km/h
        
        // Accumulate Distance (Speed is km/h, time is 1s)
        double distInThisSecond = (s / 3.6); // m/s
        cumulativeDistance += distInThisSecond;
        
        workoutData.add({
           'timestamp': startTime.add(Duration(seconds: i)).toIso8601String(),
           'power': p,
           'hr': hr,
           'cadence': cad,
           'speed': s / 3.6, // m/s for Native/FIT
           'distance': cumulativeDistance, // Accumulated meters
        });
     }

     try {
       final path = await NativeFitService.generateFitFile(
         workoutData: workoutData, 
         durationSeconds: durationSeconds, 
         totalDistanceMeters: totalDistance, // or cumulativeDistance? prefer passed total
         totalCalories: totalCalories.toDouble(), 
         startTime: startTime,
         rrIntervals: rrHistory,
       );
       return File(path);
     } catch (e) {
       print("Native FIT Generation failed: $e");
       // Fallback or rethrow? Rethrow for now to see error
       throw e;
     }
  }
}
