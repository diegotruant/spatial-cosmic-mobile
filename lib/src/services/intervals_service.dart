import 'package:flutter/foundation.dart';
import 'package:spatial_cosmic_mobile/src/services/secure_storage_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class IntervalsService extends ChangeNotifier {
  String _apiKey = '';
  String _athleteId = '';
  bool _isConnected = false;
  bool _isLoading = false;

  String get apiKey => _apiKey;
  String get athleteId => _athleteId;
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;

  IntervalsService() {
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    _apiKey = await SecureStorage.read('intervals_api_key') ?? '';
    _athleteId = await SecureStorage.read('intervals_athlete_id') ?? '';
    _isConnected = _apiKey.isNotEmpty && _athleteId.isNotEmpty;
    notifyListeners();
  }

  Future<bool> connect(String id, String key) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Test the connection by fetching profile summary
      // Intervals.icu uses Basic Auth with username 'API_KEY' and password 'key'
      // OR you can use the API key directly in some endpoints.
      // Standard for Intervals.icu: use 'API_KEY' as the user and the actual key as password.
      final auth = base64Encode(utf8.encode('API_KEY:$key'));
      
      final response = await http.get(
        Uri.parse('https://intervals.icu/api/v1/athlete/$id'),
        headers: {
          'Authorization': 'Basic $auth',
        },
      );

      if (response.statusCode == 200) {
        await SecureStorage.write('intervals_api_key', key);
        await SecureStorage.write('intervals_athlete_id', id);
        
        _apiKey = key;
        _athleteId = id;
        _isConnected = true;
        return true;
      } else {
        debugPrint('Intervals Connection Failed: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Intervals Exception: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    await SecureStorage.delete('intervals_api_key');
    await SecureStorage.delete('intervals_athlete_id');
    
    _apiKey = '';
    _athleteId = '';
    _isConnected = false;
    notifyListeners();
  }

  Future<String> uploadActivity(File fitFile) async {
    // Retry loading credentials if not connected
    if (!_isConnected) {
      await _loadCredentials();
    }
    
    if (!_isConnected) {
       return "Non connesso (ID: ${_athleteId.isEmpty ? 'Mancante' : 'Presente'}, Key: ${_apiKey.isEmpty ? 'Mancante' : 'Presente'})";
    }
    
    try {
      final uri = Uri.parse('https://intervals.icu/api/v1/athlete/$_athleteId/activities');
      final auth = base64Encode(utf8.encode('API_KEY:$_apiKey'));
      
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Basic $auth'
        ..files.add(await http.MultipartFile.fromPath('file', fitFile.path));
        
      final response = await request.send();
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('Intervals Upload Success');
        return "Success";
      } else {
        final respStr = await response.stream.bytesToString();
        debugPrint('Intervals Upload Failed: ${response.statusCode} $respStr');
        return "Errore ${response.statusCode}: ${respStr.isEmpty ? 'Errore sconosciuto' : respStr}";
      }
    } catch (e) {
      debugPrint('Intervals Upload Exception: $e');
      return "Errore di connessione: $e";
    }
  }
}
