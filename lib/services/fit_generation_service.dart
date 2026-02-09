import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/bike_sample.dart';
import '../logic/fit_payload_generator.dart';

class FitGenerationService {
  final String backendUrl;

  FitGenerationService({
    // Use production URL by default for Release builds
    // Or localhost for debug if needed, but for APK build usually Prod.
    this.backendUrl = 'https://spatial-analysis-service.onrender.com', 
  });

  /// Generates a FIT file by sending data to the Python backend.
  /// Returns the File object of the downloaded FIT file.
  Future<File> generateFitFile({
    required DateTime startTime,
    required List<BikeSample> samples,
    String sport = 'bike',
  }) async {
    final uri = Uri.parse('$backendUrl/generate_fit');
    
    // 1. Generate Payload
    final payload = FitPayloadGenerator.generatePayload(
      startTime: startTime,
      samples: samples,
      sport: sport,
    );

    try {
      // 2. Send Request
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        // 3. Save File
        final bytes = response.bodyBytes;
        final dir = await getApplicationDocumentsDirectory();
        
        // Ensure unique name
        final filename = 'activity_${startTime.millisecondsSinceEpoch}.fit';
        final file = File('${dir.path}/$filename');
        
        await file.writeAsBytes(bytes);
        return file;
      } else {
        throw Exception('Failed to generate FIT: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Error calling backend: $e');
    }
  }
}
