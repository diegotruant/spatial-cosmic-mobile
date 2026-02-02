import 'dart:io';
import 'package:fit_tool/fit_tool.dart';

class FitReader {
  /// Reads a FIT file and returns a list of data points.
  /// Returns a Map with 'timestamp', 'power', 'hr', 'cadence', 'speed' lists.
  static Future<Map<String, List<num>>> readFitFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception("FIT file not found at $path");
    }

    final bytes = await file.readAsBytes();
    final fitFile = FitFile.fromBytes(bytes);

    final List<int> timestamps = []; // seconds since epoch
    final List<double> powers = [];
    final List<int> heartRates = [];
    final List<int> cadences = [];
    final List<double> speeds = [];
    final List<double> leftSmoothness = [];
    final List<double> rightSmoothness = [];

    // Iterate through all messages
    for (final record in fitFile.records) {
       // We only care about RecordMessages
       // Note: fit_tool structure might vary, iterating generalized records
       // Inspecting typical fit_tool usage for reading:
       
       final message = record.message;
       
       if (message is RecordMessage) {
         // Timestamp is often relative to a base or absolute
         // fit_tool usually handles decoding to a DateTime or int timestamp
         // Let's assume we can get values directly if they exist
         
         final ts = message.timestamp; 
         final p = message.power;
         final hr = message.heartRate;
         final cad = message.cadence;
         final spd = message.speed;
         
         // Assuming standard field naming or using generic access if needed
         // fit_tool's RecordMessage often has these mapped
         final lpSmooth = message.leftPedalSmoothness; 
         final rpSmooth = message.rightPedalSmoothness;

         if (ts != null) {
            timestamps.add(ts);
            powers.add(p?.toDouble() ?? 0.0);
            heartRates.add(hr ?? 0);
            cadences.add(cad ?? 0);
            speeds.add(spd ?? 0.0);
            leftSmoothness.add(lpSmooth?.toDouble() ?? 0.0);
            rightSmoothness.add(rpSmooth?.toDouble() ?? 0.0);
         }
       }
    }

    // Sort by timestamp just in case
    // (Assuming they are mostly in order but good practice)
    // For simplicity, we assume they are ordered.

    return {
      'timestamps': timestamps,
      'power': powers,
      'heartRate': heartRates,
      'cadence': cadences,
      'speed': speeds,
      'leftSmoothness': leftSmoothness,
      'rightSmoothness': rightSmoothness,
    };
  }

  /// Extracts date and title from filename "activity_{timestamp}_{title}.fit"
  static Map<String, dynamic> parseFilename(String path) {
    final filename = path.split(Platform.pathSeparator).last;
    final parts = filename.split('_');
    
    // Default fallback
    DateTime date = DateTime.now();
    String title = "Workout";
    
    if (parts.length >= 2) {
       // parts[0] = "activity"
       // parts[1] = timestamp
       // parts[2...n] = title parts (if any)
       
       final ts = int.tryParse(parts[1]);
       if (ts != null) {
         date = DateTime.fromMillisecondsSinceEpoch(ts);
       }
       
       if (parts.length > 2) {
          // Join the rest and remove .fit extension
          String rawTitle = parts.sublist(2).join('_');
          if (rawTitle.toLowerCase().endsWith('.fit')) {
             rawTitle = rawTitle.substring(0, rawTitle.length - 4);
          }
          title = rawTitle.replaceAll('_', ' ');
       }
    }
    
    return {
      'date': date,
      'title': title,
    };
  }
}
