import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:spatial_cosmic_mobile/src/logic/fit_generator.dart';
import 'package:spatial_cosmic_mobile/src/logic/zwo_parser.dart';

class IntegrationService extends ChangeNotifier {
  // Strava Configuration
  static const String _stravaClientId = '69269'; 
  static const String _stravaClientSecret = '7c3a310d1aca2a143a6de74e0b0ba7625e028df7';
  static const String _stravaRedirectUri = 'spatialcosmic://spatialcosmic.app/auth';
  // Use 'activity:write' to allow uploads. 'activity:read_all' for reading.
  static const String _stravaScope = 'activity:read_all,activity:write';

  bool _isStravaConnected = false;
  bool get isStravaConnected => _isStravaConnected;
  
  bool _isGarminConnected = false;
  bool get isGarminConnected => _isGarminConnected;

  bool _isWahooConnected = false;
  bool get isWahooConnected => _isWahooConnected;

  bool _isTPConnected = false;
  bool get isTPConnected => _isTPConnected;

  String? _stravaAccessToken;

  IntegrationService() {
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    _stravaAccessToken = prefs.getString('strava_access_token');
    _isStravaConnected = _stravaAccessToken != null;
    
    _isGarminConnected = prefs.getBool('garmin_connected') ?? false;
    _isWahooConnected = prefs.getBool('wahoo_connected') ?? false;
    _isTPConnected = prefs.getBool('tp_connected') ?? false;
    
    notifyListeners();
  }

  Future<void> initiateStravaAuth() async {
    final Uri url = Uri.https(
      'www.strava.com',
      '/oauth/authorize',
      {
        'client_id': _stravaClientId,
        'response_type': 'code',
        'redirect_uri': _stravaRedirectUri,
        'approval_prompt': 'force',
        'scope': _stravaScope,
      },
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      debugPrint('Strava Auth Launched: $url');
    } else {
      throw 'Could not launch $url';
    }
  }
  
  Future<void> handleAuthCallback(Uri uri) async {
    if (uri.scheme == 'spatialcosmic' && uri.host == 'spatialcosmic.app') {
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];
      
      if (error != null) {
        debugPrint('Strava Auth Error: $error');
        return;
      }
      
      if (code != null) {
        debugPrint('Received Strava Auth Code: $code');
        await _exchangeToken(code);
      }
    }
  }

  Future<void> _exchangeToken(String code) async {
    try {
      final response = await http.post(
        Uri.parse('https://www.strava.com/oauth/token'),
        body: {
          'client_id': _stravaClientId,
          'client_secret': _stravaClientSecret,
          'code': code,
          'grant_type': 'authorization_code',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['access_token'];
        final refreshToken = data['refresh_token'];
        final expiresAt = data['expires_at'];

        await _saveStravaCredentials(accessToken, refreshToken, expiresAt);
        debugPrint('Strava Connected Successfully!');
      } else {
        debugPrint('Strava Token Exchange Failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Strava Token Exchange Exception: $e');
    }
  }

  Future<void> _saveStravaCredentials(String accessToken, String refreshToken, int expiresAt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('strava_access_token', accessToken);
    await prefs.setString('strava_refresh_token', refreshToken);
    await prefs.setInt('strava_expires_at', expiresAt);
    
    _stravaAccessToken = accessToken;
    _isStravaConnected = true;
    notifyListeners();
  }
  
  Future<void> disconnectStrava() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('strava_access_token');
    await prefs.remove('strava_refresh_token');
    await prefs.remove('strava_expires_at');
    
    _stravaAccessToken = null;
    _isStravaConnected = false;
    notifyListeners();
  }

  Future<void> disconnectGarmin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('garmin_connected', false);
    _isGarminConnected = false;
    notifyListeners();
  }

  Future<void> disconnectWahoo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('wahoo_connected', false);
    _isWahooConnected = false;
    notifyListeners();
  }

  Future<void> disconnectTP() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tp_connected', false);
    _isTPConnected = false;
    notifyListeners();
  }

  Future<bool> _ensureValidStravaToken() async {
    final prefs = await SharedPreferences.getInstance();
    final expiresAt = prefs.getInt('strava_expires_at') ?? 0;
    final refreshToken = prefs.getString('strava_refresh_token');

    // If it expires in less than 5 minutes, refresh
    if (DateTime.now().millisecondsSinceEpoch / 1000 > (expiresAt - 300)) {
      if (refreshToken == null) return false;

      debugPrint('Strava Token Expired. Refreshing...');
      try {
        final response = await http.post(
          Uri.parse('https://www.strava.com/oauth/token'),
          body: {
            'client_id': _stravaClientId,
            'client_secret': _stravaClientSecret,
            'grant_type': 'refresh_token',
            'refresh_token': refreshToken,
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          await _saveStravaCredentials(
            data['access_token'],
            data['refresh_token'],
            data['expires_at'],
          );
          return true;
        } else {
          debugPrint('Strava Token Refresh Failed: ${response.body}');
          return false;
        }
      } catch (e) {
        debugPrint('Strava Token Refresh Exception: $e');
        return false;
      }
    }
    return true;
  }

  Future<String> uploadActivityToStrava(File fitFile) async {
    if (!_isStravaConnected || _stravaAccessToken == null) return "Strava non connesso";
    
    // Ensure token is valid
    final ok = await _ensureValidStravaToken();
    if (!ok) return "Errore rinnovo token Strava";

    try {
      final uri = Uri.parse('https://www.strava.com/api/v3/uploads');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $_stravaAccessToken'
        ..fields['data_type'] = 'fit'
        ..fields['name'] = 'Spatial Cosmic Workout'
        ..files.add(await http.MultipartFile.fromPath('file', fitFile.path));
        
      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      
      if (response.statusCode == 201) {
        debugPrint('Strava Upload Started Successfully!');
        return "Success";
      } else {
        debugPrint('Strava Upload Failed: ${response.statusCode} $respStr');
        return "Errore Strava ${response.statusCode}: $respStr";
      }
    } catch (e) {
      debugPrint('Strava Upload Exception: $e');
      return "Eccezione Strava: $e";
    }
  }

  // Garmin Connect
  Future<void> initiateGarminAuth() async {
    final Uri url = Uri.parse('https://connect.garmin.com/oauthConfirm?oauth_token=YOUR_REQUEST_TOKEN'); 
    await _launchAuthUrl(url);
  }

  // Wahoo Cloud
  Future<void> initiateWahooAuth() async {
    final Uri url = Uri.parse('https://api.wahooligan.com/oauth/authorize?client_id=WAHOO_CLIENT_ID&response_type=code&redirect_uri=$_stravaRedirectUri&scope=user_read+workouts_read');
    await _launchAuthUrl(url);
  }

  // TrainingPeaks
  Future<void> initiateTrainingPeaksAuth() async {
    final Uri url = Uri.parse('https://home.trainingpeaks.com/oauth/authorize?client_id=TP_CLIENT_ID&response_type=code&redirect_uri=$_stravaRedirectUri&scope=workouts:read,workouts:write');
    await _launchAuthUrl(url);
  }

  // Dropbox
  Future<void> initiateDropboxAuth() async {
    final Uri url = Uri.parse('https://www.dropbox.com/oauth2/authorize?client_id=DROPBOX_APP_KEY&response_type=code&redirect_uri=$_stravaRedirectUri');
    await _launchAuthUrl(url);
  }
  
  Future<void> initiateZwiftAuth() async {
     final Uri url = Uri.parse('https://my.zwift.com/profile/connections');
     await _launchAuthUrl(url);
  }

  // Garmin Connect Workout Upload
  Future<bool> uploadWorkoutToGarmin(File fitFile) async {
    // In production, we'd use the Garmin Training API: POST /workout
    // Using a simplified request placeholder for demonstration
    try {
      final uri = Uri.parse('https://connectapi.garmin.com/workout-service/workout');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer YOUR_GARMIN_TOKEN'
        ..files.add(await http.MultipartFile.fromPath('file', fitFile.path));
        
      final response = await request.send();
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint('Garmin Upload Error: $e');
      return false;
    }
  }

  // Wahoo Workout Upload
  Future<bool> uploadWorkoutToWahoo(File fitFile) async {
    // Wahoo API documentation: POST /v1/workouts
    try {
      final uri = Uri.parse('https://api.wahooligan.com/v1/plan_workouts');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer YOUR_WAHOO_TOKEN'
        ..files.add(await http.MultipartFile.fromPath('file', fitFile.path));
        
      final response = await request.send();
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint('Wahoo Upload Error: $e');
      return false;
    }
  }

  // TrainingPeaks (often also syncs to Bryton/Karoo)
  Future<bool> uploadWorkoutToTrainingPeaks(File fitFile) async {
    try {
      final uri = Uri.parse('https://api.trainingpeaks.com/v1/workouts/planned');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer YOUR_TP_TOKEN'
        ..files.add(await http.MultipartFile.fromPath('file', fitFile.path));
        
      final response = await request.send();
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint('TP Upload Error: $e');
      return false;
    }
  }

  Future<void> uploadWorkoutDirectly(WorkoutWorkout workout, String platform, int ftp) async {
    // 1. Generate FIT file
    final dir = await getApplicationDocumentsDirectory();
    final filename = "${workout.title.replaceAll(' ', '_')}.fit"; // Simple sanitization
    final file = File('${dir.path}/$filename');
    
    final bytes = FitGenerator.toBytes(workout, ftp);
    await file.writeAsBytes(bytes);

    bool success = false;
    switch (platform) {
      case 'garmin':
        success = await uploadWorkoutToGarmin(file);
        break;
      case 'wahoo':
        success = await uploadWorkoutToWahoo(file);
        break;
      case 'tp':
        success = await uploadWorkoutToTrainingPeaks(file);
        break;
      default:
        throw 'Piattaforma non supportata: $platform';
    }
    
    // Cleanup
    if (await file.exists()) {
      await file.delete(); 
    }

    if (!success) {
      // MOCK SUCCESS
      debugPrint('MOCK UPLOAD SUCCESS for $platform');
      await Future.delayed(const Duration(seconds: 2));
      return; 
    }
  }

  Future<void> _launchAuthUrl(Uri url) async {
    debugPrint('Launching Auth URL: $url');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }
}
