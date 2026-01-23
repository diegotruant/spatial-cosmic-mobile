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
  
  /// Returns a map of standard peak powers: 5s, 1m, 5m, 20m
  static Map<String, double> calculatePowerCurve(List<double> powerData) {
    return {
      '5s': calculatePeakPower(powerData, 5),
      '1m': calculatePeakPower(powerData, 60),
      '5m': calculatePeakPower(powerData, 300),
      '20m': calculatePeakPower(powerData, 1200),
    };
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
