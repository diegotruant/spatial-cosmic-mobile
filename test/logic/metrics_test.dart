import 'package:flutter_test/flutter_test.dart';
import 'package:spatial_cosmic_mobile/logic/metrics_engine.dart';

void main() {
  group('MetricsEngine', () {
    test('calculate Work (kJ) correctly', () {
      // 100 watts for 10 seconds = 1000 Joules = 1 kJ
      final samples = List.generate(10, (index) => 100);
      final work = MetricsEngine.workKj(samples);
      expect(work, 1.0);
    });

    test('Normalized Power matches Average Power for constant effort', () {
      // Constant 200W for 1 minute
      final samples = List.generate(60, (index) => 200);
      final np = MetricsEngine.normalizedPower(samples);
      
      // For constant power, NP == Avg Power
      expect(np, 200.0);
    });

    test('Normalized Power is higher than Average for variable effort', () {
      // 30s at 100W, 30s at 300W
      // Avg = 200W
      // NP should be higher because of the weighting on higher powers
      final samples = [
        ...List.generate(30, (i) => 100),
        ...List.generate(30, (i) => 300),
      ];
      
      final avg = samples.reduce((a,b) => a+b) / samples.length; // 200
      final np = MetricsEngine.normalizedPower(samples);
      
      expect(avg, 200.0);
      expect(np, greaterThan(200.0));
      
      // Rough calc check:
      // Rolling 30s:
      // First window (0-30): all 100W. Avg=100.
      // Transition windows...
      // Last window (30-60): all 300W. Avg=300.
      // NP weights the 300W much more heavily (pow 4).
    });

    test('Normalized Power returns Average for short durations (<30s)', () {
      final samples = List.generate(10, (index) => 150);
      final np = MetricsEngine.normalizedPower(samples);
      expect(np, 150.0);
    });
    
    test('Handles empty lists gracefully', () {
      expect(MetricsEngine.workKj([]), 0.0);
      expect(MetricsEngine.normalizedPower([]), 0.0);
    });
  });
}
