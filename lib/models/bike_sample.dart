class BikeSample {
  final DateTime timestamp;       // UTC
  final int? heartRate;           // bpm
  final List<int> rrMs;           // RR raw in ms
  final int? power;               // watt
  final int? cadence;             // rpm
  final double? speed;            // m/s

  BikeSample({
    required this.timestamp,
    this.heartRate,
    this.rrMs = const [],
    this.power,
    this.cadence,
    this.speed,
  });

  @override
  String toString() {
    return 'BikeSample(ts: $timestamp, hr: $heartRate, pwr: $power, rr: ${rrMs.length})';
  }
}
