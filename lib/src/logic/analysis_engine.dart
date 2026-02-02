import 'dart:math';

class AnalysisEngine {
  
  /// Calculates Normalized Power (NP)
  /// Algorithm:
  /// 1. Calculate 30s rolling average power
  /// 2. Raise values to the 4th power
  /// 3. Take the average of these values
  /// 4. Take the 4th root of the average
  static double calculateNP(List<double> powerData) {
    if (powerData.isEmpty) return 0.0;
    
    // If less than 30s, just return avg power
    if (powerData.length < 30) {
      return powerData.reduce((a, b) => a + b) / powerData.length;
    }

    final List<double> rolling30s = [];
    
    for (int i = 0; i <= powerData.length - 30; i++) {
      double sum = 0;
      for (int j = 0; j < 30; j++) {
        sum += powerData[i + j];
      }
      rolling30s.add(sum / 30);
    }

    double sumPow4 = 0;
    for (final p in rolling30s) {
      sumPow4 += pow(p, 4);
    }
    
    final avgPow4 = sumPow4 / rolling30s.length;
    return pow(avgPow4, 0.25).toDouble();
  }

  /// Calculates Training Stress Score (TSS)
  /// TSS = (sec x NP x IF) / (FTP x 3600) x 100
  static double calculateTSS(double np, double ftp, int durationSeconds) {
    if (ftp == 0) return 0.0;
    final ifFactor = np / ftp;
    return (durationSeconds * np * ifFactor) / (ftp * 3600) * 100;
  }
  
  /// Calculates Intensity Factor (IF)
  static double calculateIF(double np, double ftp) {
    if (ftp == 0) return 0.0;
    return np / ftp;
  }

  /// Calculates Peak Power for a given duration (window size in seconds)
  static double calculatePeakPower(List<double> powerData, int durationSeconds) {
     if (powerData.length < durationSeconds) return 0.0;
     
     double maxSum = 0;
     double currentSum = 0;
     
     // Initial window
     for (int i = 0; i < durationSeconds; i++) {
       currentSum += powerData[i];
     }
     maxSum = currentSum;
     
     // Slide average
     for (int i = durationSeconds; i < powerData.length; i++) {
       currentSum += powerData[i] - powerData[i - durationSeconds];
       if (currentSum > maxSum) {
         maxSum = currentSum;
       }
     }
     
     return maxSum / durationSeconds;
  }
  
  /// Returns a map of standard peak powers: 5s, 1m, 5m, 20m + Metabolic buckets
  static Map<String, double> calculatePowerCurve(List<double> powerData) {
    return {
      '5s': calculatePeakPower(powerData, 5),
      '15s': calculatePeakPower(powerData, 15),
      '1m': calculatePeakPower(powerData, 60),
      '3m': calculatePeakPower(powerData, 180),
      '5m': calculatePeakPower(powerData, 300),
      '6m': calculatePeakPower(powerData, 360),
      '10m': calculatePeakPower(powerData, 600),
      '12m': calculatePeakPower(powerData, 720),
      '15m': calculatePeakPower(powerData, 900),
      '20m': calculatePeakPower(powerData, 1200),
      '60m': calculatePeakPower(powerData, 3600),
    };
  }

  /// Calculates W' Balance series based on Skiba's model
  /// W' bal = W' - Integral((W' - W' bal) / tau)
  /// Simplified version for post-analysis
  static List<double> calculateWBalanceSeries(List<double> powerData, double cp, double wPrime) {
    if (powerData.isEmpty) return [];
    
    List<double> wBal = [];
    double currentW = wPrime;
    
    // Recovery constant (tau) - simplified approximation
    // Tau = 546 * exp(-0.01 * (CP - P_recovery)) + 316
    // We'll use a standard tau for the series calculation
    
    for (int i = 0; i < powerData.length; i++) {
      final p = powerData[i];
      if (p > cp) {
        // Depletion
        currentW -= (p - cp);
      } else {
        // Recovery
        // Tau = 300s (approx 5 min) for 50% recovery
        const double tau = 300.0; 
        currentW += (wPrime - currentW) * (1 - exp(-1 / tau));
      }
      
      if (currentW > wPrime) currentW = wPrime;
      if (currentW < 0) currentW = 0;
      
      wBal.add(currentW);
    }
    
    return wBal;
  }

  /// Calculates Gear Ratio (Rapporti)
  /// Ratio = (Speed m/s) / (Cadence rev/s * WheelCircumference)
  static List<double> calculateGearRatioSeries(List<double> speedKmh, List<int> cadenceRpm, {double wheelCirc = 2.095}) {
    List<double> ratios = [];
    final length = min(speedKmh.length, cadenceRpm.length);
    
    for (int i = 0; i < length; i++) {
      final speedMs = speedKmh[i] / 3.6;
      final cadRs = cadenceRpm[i] / 60.0;
      
      if (cadRs > 0.5 && speedMs > 1.0) { // Filtering for pedaling and moving
        final ratio = speedMs / (cadRs * wheelCirc);
        ratios.add(double.parse(ratio.toStringAsFixed(2)));
      } else {
        ratios.add(0.0);
      }
    }
    return ratios;
  }

  /// Calculates combined Pedal Smoothness
  static double calculateAveragePedalSmoothness(List<double> left, List<double> right) {
    if (left.isEmpty && right.isEmpty) return 0.0;
    
    double sum = 0;
    int count = 0;
    
    final length = min(left.length, right.length);
    if (length == 0) {
       final data = left.isNotEmpty ? left : right;
       return data.reduce((a, b) => a + b) / data.length;
    }

    for (int i = 0; i < length; i++) {
      if (left[i] > 0 || right[i] > 0) {
        sum += (left[i] + right[i]) / 2.0;
        count++;
      }
    }
    
    return count > 0 ? sum / count : 0.0;
  }

  /// Applies a simple moving average smoothing
  static List<double> smoothData(List<double> data, int windowSize) {
    if (data.isEmpty || windowSize <= 1) return data;
    
    final List<double> smoothed = [];
    for (int i = 0; i < data.length; i++) {
      double sum = 0;
      int count = 0;
      
      // Center aligned or trailing? Let's use trailing for simplicity/live-feel, 
      // but for post-analysis center or trailing is fine. 
      // User asked for "smoothing di 3 secondi".
      
      for (int j = max(0, i - windowSize + 1); j <= i; j++) {
         sum += data[j];
         count++;
      }
      smoothed.add(sum / count);
    }
    return smoothed;
  }
}
