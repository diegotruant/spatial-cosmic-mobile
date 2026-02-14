import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OuraService extends ChangeNotifier {
  static const String _baseUrl = 'https://api.ouraring.com/v2';
  static const String _clientId = 'eb322057-c43d-4ccb-aa7b-2573792b4191';
  static const String _clientSecret = 'QCl3XLjYJq5cvhcN1flGzY1YqYq526bYS_z4PeTJG4E';
  static const String _redirectUri = 'spatialcosmic://auth/oura';

  String? _accessToken;
  String _lastLog = "Nessun log.";
  String? _currentUserId;
  
  String get lastLog => _lastLog;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool get hasToken => _accessToken != null && _accessToken!.isNotEmpty;

  OuraService() {
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _loadToken();
    
    // Clear Oura token when user changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final newUserId = data.session?.user.id;
      
      if (newUserId != null && _currentUserId != null && newUserId != _currentUserId) {
        debugPrint('[OuraService] User changed, clearing Oura token');
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('oura_token');
        _accessToken = null;
        _currentUserId = newUserId;
        notifyListeners();
      } else if (newUserId != null) {
        _currentUserId = newUserId;
      } else {
        // User logged out
        _currentUserId = null;
        _accessToken = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('oura_token');
    notifyListeners();
  }

  Future<void> setAccessToken(String token) async {
    _accessToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('oura_token', token);
    notifyListeners();
  }

  Future<void> initiateOAuth() async {
    final Uri url = Uri.https(
      'cloud.ouraring.com',
      '/oauth/authorize',
      {
        'client_id': _clientId,
        'response_type': 'code',
        'redirect_uri': _redirectUri,
        'scope': 'email personal daily_readiness daily_sleep',
      },
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> handleCallback(Uri uri) async {
    debugPrint('OuraService: Analyzing URI: $uri');
    
    // Check if the URI is for Oura
    if (!uri.toString().contains('oura')) {
      debugPrint('OuraService: Not an Oura URI, skipping.');
      return;
    }

    final code = uri.queryParameters['code'];
    if (code == null) {
      debugPrint('OuraService: No code found in URI.');
      return;
    }

    debugPrint('OuraService: Received Authorization Code: $code');
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('OuraService: Exchanging code for token...');
      final response = await http.post(
        Uri.parse('https://api.ouraring.com/oauth/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'redirect_uri': _redirectUri,
        },
      );

      debugPrint('OuraService: Token response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'] as String;
        debugPrint('OuraService: Token received successfully.');
        await setAccessToken(token);
      } else {
        debugPrint('OuraService: Token exchange failed: ${response.body} (Status: ${response.statusCode})');
        // Ideally show a notification here, but we are in a service. 
        // We rely on the `hasToken` listeners to update UI.
      }
    } catch (e) {
      debugPrint('OuraService: OAuth Exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Debug function to print current token status
  void debugToken() {
    debugPrint('OuraService: Current Token: $_accessToken');
  }

  Future<Map<String, dynamic>?> fetchDailyReadiness() async {
    if (_accessToken == null) return null;

    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      // Look back 7 days to ensure we find some data
      final startDate = now.subtract(const Duration(days: 7)).toIso8601String().split('T')[0];
      final endDate = now.add(const Duration(days: 1)).toIso8601String().split('T')[0];

      // Fetch Daily Readiness
      final response = await http.get(
        Uri.parse('$_baseUrl/usercollection/daily_readiness?start_date=$startDate&end_date=$endDate'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _lastLog = "Readiness: 200 OK. Data: ${data.toString().substring(0, data.toString().length > 100 ? 100 : data.toString().length)}...";
        debugPrint('Oura Readiness Response: $data'); 
        
        if (data is Map<String, dynamic> && data.containsKey('data')) {
           final items = data['data'] as List;
           if (items.isNotEmpty) {
              return items.last as Map<String, dynamic>;
           } else {
             _lastLog += " (Empty List)";
           }
        } 
      } else {
        _lastLog = "Readiness Error: ${response.statusCode} - ${response.body}";
        debugPrint('Oura API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _lastLog = "Readiness Exception: $e";
      debugPrint('Oura Exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }
  
  Future<Map<String, dynamic>?> fetchDailySleep() async {
    if (_accessToken == null) return null;

    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      // Look back 7 days
      final startDate = now.subtract(const Duration(days: 7)).toIso8601String().split('T')[0];
      final endDate = now.add(const Duration(days: 1)).toIso8601String().split('T')[0];

      // Use 'sleep' endpoint instead of 'daily_sleep' to get HRV/RMSSD
      final response = await http.get(
        Uri.parse('$_baseUrl/usercollection/sleep?start_date=$startDate&end_date=$endDate'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['data'] as List;
        if (items.isNotEmpty) {
           // Sort by day/timestamp to get the latest?
           // Actually, API usually returns chronological.
           return items.last as Map<String, dynamic>;
        }
      } else {
         debugPrint('Oura Sleep Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Oura Sleep Exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  Future<void> refresh() async {
    // Just a trigger for listeners if needed, 
    // but usually the service just provides methods.
    notifyListeners();
  }
}
