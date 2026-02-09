import '../models/bike_sample.dart';

class FitPayloadGenerator {
  static Map<String, dynamic> generatePayload({
    required DateTime startTime,
    required List<BikeSample> samples,
    String sport = 'bike',
  }) {
    // 1. Prepare samples list
    final samplesJson = samples.map((s) {
      // timestamp to ISO 8601
      // RR from ms to seconds (float)
      final rrSeconds = s.rrMs.map((ms) => ms / 1000.0).toList();

      final sampleMap = <String, dynamic>{
        'timestamp': s.timestamp.toUtc().toIso8601String(),
        'rr': rrSeconds,
      };

      if (s.heartRate != null) sampleMap['hr'] = s.heartRate;
      if (s.power != null) sampleMap['power'] = s.power;
      if (s.cadence != null) sampleMap['cadence'] = s.cadence;
      if (s.speed != null) sampleMap['speed'] = s.speed;

      return sampleMap;
    }).toList();

    // 2. Build final payload
    return {
      'sport': sport,
      'start_time': startTime.toUtc().toIso8601String(),
      'samples': samplesJson,
    };
  }
}
