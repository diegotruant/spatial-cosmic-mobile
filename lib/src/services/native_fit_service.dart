import 'package:flutter/services.dart';

class NativeFitService {
  static const platform = MethodChannel('com.spatialcosmic.app/fit_generator');

  /// Generates a FIT file using the native Android Garmin SDK.
  /// 
  /// [workoutData] is a list of maps, where each map contains:
  /// - 'timestamp': ISO8601 string
  /// - 'power': double
  /// - 'hr': int
  /// - 'cadence': int
  /// - 'speed': double (m/s)
  /// - 'distance': double (meters)
  /// 
  /// Returns the absolute path of the generated file.
  static Future<String> generateFitFile({
    required List<Map<String, dynamic>> workoutData,
    required int durationSeconds,
    required double totalDistanceMeters,
    required double totalCalories,
    required DateTime startTime,
    required int normalizedPower,
    List<Map<String, dynamic>>? rrIntervals, // Optional: List of {timestamp, rr: [int, int...]}
  }) async {
    try {
      final String result = await platform.invokeMethod('generateFitFile', {
        'data': workoutData,
        'startTime': startTime.toIso8601String(),
        'duration': durationSeconds,
        'totalDistance': totalDistanceMeters,
        'totalCalories': totalCalories,
        'normalizedPower': normalizedPower,
        'rrIntervals': rrIntervals ?? [],
      });
      return result;
    } on PlatformException catch (e) {
      throw Exception("Failed to generate FIT file: '${e.message}'.");
    }
  }
}
