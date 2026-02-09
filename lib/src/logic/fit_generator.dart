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
    List<Map<String, dynamic>>? rrHistory,  // Optional RR intervals for HRV
  }) async {
    final builder = FitFileBuilder();

    // ---------------------------------------------------------
    // FIT EPOCH CORRECTION
    // FIT Epoch is Dec 31, 1989 00:00:00 UTC.
    // ---------------------------------------------------------
    final fitEpoch = DateTime.utc(1989, 12, 31, 0, 0, 0).millisecondsSinceEpoch;
    int toFitTime(DateTime dt) => (dt.millisecondsSinceEpoch - fitEpoch) ~/ 1000;





    // Normalize startTime to exact second (remove milliseconds for timestamp precision)
    final normalizedStart = DateTime.fromMillisecondsSinceEpoch(
      (startTime.millisecondsSinceEpoch ~/ 1000) * 1000
    );
    final startFitTime = toFitTime(normalizedStart);
    final endFitTime = toFitTime(normalizedStart.add(Duration(seconds: durationSeconds)));

    // 1. File ID
    builder.add(FileIdMessage()
      ..type = FileType.activity
      ..manufacturer = 1 // Garmin - highest compatibility
      ..product = 1
      ..timeCreated = startFitTime
      ..serialNumber = 12345678
    );

    // 1b. Device Info
    builder.add(DeviceInfoMessage()
      ..timestamp = startFitTime
      ..serialNumber = 12345678
      ..manufacturer = 1
      ..product = 1
      ..softwareVersion = 100
      ..deviceIndex = 0
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
    double cumulativeDistance = 0.0;

    for (int i = 0; i < maxLength; i++) {
        final recTime = normalizedStart.add(Duration(seconds: i));
        
        // Accumulate distance for each record (Speed is km/h, time is 1s)
        double currentSpeedKmh = i < speedHistory.length ? speedHistory[i] : 0.0;
        double distInThisSecond = (currentSpeedKmh / 3.6); // m/s
        cumulativeDistance += distInThisSecond;

        // Validate and clamp all values to FIT protocol ranges
        final record = RecordMessage()
          ..timestamp = toFitTime(recTime)
          ..distance = cumulativeDistance // meters (fit_tool handles encoding)
          ..power = (i < powerHistory.length ? powerHistory[i].toInt() : 0).clamp(0, 65535)
          ..heartRate = (i < hrHistory.length ? hrHistory[i] : 0).clamp(0, 255)
          ..cadence = (i < cadenceHistory.length ? cadenceHistory[i] : 0).clamp(0, 255)
          ..speed = (currentSpeedKmh / 3.6).clamp(0.0, 100.0); // m/s (fit_tool handles encoding)
        builder.add(record);
        
        // Add HRV Message if RR intervals available for this second
        // RR intervals are stored in standard HRV messages for compatibility
        // Strava ignores these optional messages, but they're parsed by our backend
        if (rrHistory != null && i < rrHistory.length) {
          final rrData = rrHistory[i];
          final rrList = rrData['rr'] as List?;
          
          if (rrList != null && rrList.isNotEmpty) {
            // Convert RR intervals to proper format (milliseconds as integers)
            final rrIntegers = rrList.map((rr) => rr is int ? rr : (rr as num).toInt()).toList();
            
            builder.add(HrvMessage()
              ..time = rrIntegers.map((rr) => rr.toDouble()).toList()
            );
          }
        }
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
    // 5. Lap Message (Strava prefers at least one lap)
    // IMPORTANT: fit_tool does NOT auto-apply scale factors. We multiply manually:
    // - time fields: x1000 (seconds → milliseconds for binary encoding)
    // - distance: x100 (meters → centimeters for binary encoding)
    // - speed: x1000 (m/s → mm/s for binary encoding)
    final normalizedPower = _calculateNormalizedPower(powerHistory);
    
    final lapMsg = LapMessage()
      ..messageIndex = 0
      ..timestamp = endFitTime
      ..startTime = startFitTime
      ..totalElapsedTime = durationSeconds.toDouble() * 1000.0   // Scale factor: x1000 (seconds → milliseconds)
      ..totalTimerTime = durationSeconds.toDouble() * 1000.0     // Scale factor: x1000 (seconds → milliseconds)
      ..totalDistance = cumulativeDistance * 100.0               // Scale factor: x100 (meters → centimeters)
      ..totalCalories = totalCalories
      ..avgSpeed = ((speedHistory.isNotEmpty ? (speedHistory.fold<double>(0, (a, b) => a + b) / speedHistory.length) : 0.0) / 3.6) * 1000.0  // Scale factor: x1000 (m/s → mm/s)
      ..maxSpeed = ((speedHistory.isNotEmpty ? speedHistory.fold<double>(0, (a, b) => a > b ? a : b) : 0.0) / 3.6) * 1000.0  // Scale factor: x1000 (m/s → mm/s)
      ..avgHeartRate = avgHr
      ..maxHeartRate = maxHr
      ..avgCadence = cadenceHistory.isNotEmpty ? (cadenceHistory.fold<int>(0, (a, b) => a + b) / cadenceHistory.length).toInt() : 0
      ..maxCadence = cadenceHistory.isNotEmpty ? cadenceHistory.fold<int>(0, (a, b) => a > b ? a : b) : 0
      ..avgPower = avgPower.toInt()
      ..maxPower = maxPower
      ..normalizedPower = normalizedPower  // Add NP for training analysis
      ..intensity = Intensity.active
      ..lapTrigger = LapTrigger.manual;
    builder.add(lapMsg);

    // 6. Session Message (OBBLIGATORIO per compatibilità Strava)
    // IMPORTANT: fit_tool does NOT auto-apply scale factors. We multiply manually:
    // - time fields: x1000 (seconds → milliseconds for binary encoding)
    // - distance: x100 (meters → centimeters for binary encoding)
    // - speed: x1000 (m/s → mm/s for binary encoding)
    final sessionMsg = SessionMessage()
      ..messageIndex = 0
      ..timestamp = endFitTime 
      ..startTime = startFitTime
      ..totalElapsedTime = durationSeconds.toDouble() * 1000.0   // Scale factor: x1000 (seconds → milliseconds)
      ..totalTimerTime = durationSeconds.toDouble() * 1000.0     // Scale factor: x1000 (seconds → milliseconds)
      ..totalDistance = cumulativeDistance * 100.0               // Scale factor: x100 (meters → centimeters)
      ..totalCalories = totalCalories
      ..avgSpeed = ((speedHistory.isNotEmpty ? (speedHistory.fold<double>(0, (a, b) => a + b) / speedHistory.length) : 0.0) / 3.6) * 1000.0  // Scale factor: x1000 (m/s → mm/s)
      ..maxSpeed = ((speedHistory.isNotEmpty ? speedHistory.fold<double>(0, (a, b) => a > b ? a : b) : 0.0) / 3.6) * 1000.0  // Scale factor: x1000 (m/s → mm/s)
      ..avgHeartRate = avgHr
      ..maxHeartRate = maxHr
      ..avgCadence = cadenceHistory.isNotEmpty ? (cadenceHistory.fold<int>(0, (a, b) => a + b) / cadenceHistory.length).toInt() : 0
      ..maxCadence = cadenceHistory.isNotEmpty ? cadenceHistory.fold<int>(0, (a, b) => a > b ? a : b) : 0
      ..avgPower = avgPower.toInt()
      ..maxPower = maxPower
      ..normalizedPower = normalizedPower  // Add NP for training analysis
      ..sport = Sport.cycling
      ..subSport = SubSport.indoorCycling
      ..firstLapIndex = 0
      ..numLaps = 1;
    builder.add(sessionMsg);

    // 7. Activity Message (OBBLIGATORIO per Strava)
    // IMPORTANT: fit_tool does NOT auto-apply scale factors
    // time fields: x1000 (seconds → milliseconds for binary encoding)
    final activityMsg = ActivityMessage()
      ..timestamp = endFitTime
      ..totalTimerTime = durationSeconds.toDouble() * 1000.0   // Scale factor: x1000 (seconds → milliseconds)
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
