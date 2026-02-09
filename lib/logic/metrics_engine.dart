import 'dart:math';

class MetricsEngine {
  /// Calculate Work in kJ
  static double workKj(List<int> powerSamples) {
    if (powerSamples.isEmpty) return 0.0;
    // 1 watt = 1 joule/sec. Sum of watts (1 sec each) = total joules.
    // kJ = total joules / 1000.
    final totalJoules = powerSamples.reduce((a, b) => a + b);
    return totalJoules / 1000.0;
  }

  /// Calculate Normalized Power (rolling 30s)
  static double normalizedPower(List<int> powerSamples) {
    if (powerSamples.isEmpty) return 0.0;
    
    final rolling = <double>[];
    
    // Need at least 30 seconds for the first rolling average
    // If less than 30s, just return average power (standard behavior for short durations)
    if (powerSamples.length < 30) {
      return powerSamples.reduce((a, b) => a + b) / powerSamples.length;
    }

    for (int i = 30; i <= powerSamples.length; i++) {
      final window = powerSamples.sublist(i - 30, i);
      final avg30 = window.reduce((a, b) => a + b) / 30.0;
      rolling.add(pow(avg30, 4).toDouble());
    }

    if (rolling.isEmpty) return 0.0;

    final mean = rolling.reduce((a, b) => a + b) / rolling.length;
    return pow(mean, 0.25).toDouble();
  }

  static double average(List<int> samples) {
    if (samples.isEmpty) return 0.0;
    return samples.reduce((a, b) => a + b) / samples.length;
  }

  static int max(List<int> samples) {
    if (samples.isEmpty) return 0;
    return samples.reduce((curr, next) => curr > next ? curr : next);
  }
}
