import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spatial_cosmic_mobile/src/services/secure_storage_service.dart';
import 'package:spatial_cosmic_mobile/src/services/log_service.dart';
import 'package:spatial_cosmic_mobile/src/config/app_config.dart';

class OuraService extends ChangeNotifier {
  static const String _baseUrl = 'https://api.ouraring.com/v2';
  /// Only needed for the authorize URL (public). Token exchange is done on our backend.
  static String get _clientId => AppConfig.ouraClientId.isNotEmpty
      ? AppConfig.ouraClientId
      : 'eb322057-c43d-4ccb-aa7b-2573792b4191';
  static String get _redirectUri => AppConfig.ouraRedirectUri;

  String? _accessToken;
  String? _lastHandledAuthCode;
  String _lastLog = "Nessun log.";
  String? _currentUserId;
  SupabaseClient get _supabase => Supabase.instance.client;
  
  String get lastLog => _lastLog;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool get hasToken => _accessToken != null && _accessToken!.isNotEmpty;

  OuraService() {
    // We can't access Supabase.instance here safely if we aren't absolutely sure about the timing
    // Instead, we will initialize in a post-boot phase or lazily.
    // For now, let's just make it not crash.
    _loadToken();
    
    // Clear Oura token when user changes
    // Using a microtask to ensure we don't access Supabase during construction
    Future.microtask(() {
      _currentUserId = _supabase.auth.currentUser?.id;
      _supabase.auth.onAuthStateChange.listen((data) async {
        final newUserId = data.session?.user.id;
        
        if (newUserId != null && _currentUserId != null && newUserId != _currentUserId) {
          LogService.i('[OuraService] User changed, clearing Oura token');
          await SecureStorage.delete('oura_token');
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
    });
  }

  Future<void> _loadToken() async {
    _accessToken = await SecureStorage.read('oura_token');
    notifyListeners();
  }

  Future<void> setAccessToken(String token) async {
    _accessToken = token;
    await SecureStorage.write('oura_token', token);
    notifyListeners();
  }

  Future<void> initiateOAuth() async {
    // Oura official authorize endpoint (v2 path can return 404)
    final Uri url = Uri.https(
      'cloud.ouraring.com',
      '/oauth/authorize',
      {
        'client_id': _clientId,
        'response_type': 'code',
        'redirect_uri': _redirectUri,
      },
    );

    try {
      final can = await canLaunchUrl(url);
      if (can) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _lastLog = "Impossibile aprire il browser. Controlla i permessi.";
        notifyListeners();
      }
    } catch (e) {
      LogService.e('OuraService: initiateOAuth error: $e');
      _lastLog = "Errore apertura browser: $e";
      notifyListeners();
    }
  }

  Future<void> handleCallback(Uri uri) async {
    // Check if the URI is for Oura
    if (!uri.toString().contains('oura')) {
      LogService.d('OuraService: Not an Oura URI, skipping.');
      return;
    }

    final code = uri.queryParameters['code'];
    if (code == null) {
      LogService.w('OuraService: No code found in URI.');
      _lastLog = "Errore: Codice mancante nell'URL di callback.";
      return;
    }

    // Oura authorization codes are single-use. Some devices emit duplicate deep-link events.
    if (_lastHandledAuthCode == code) {
      LogService.w('OuraService: Duplicate auth code received, skipping.');
      return;
    }
    _lastHandledAuthCode = code;

    LogService.i('OuraService: Received Authorization Code: $code');
    _isLoading = true;
    notifyListeners();

    try {
      final session = _supabase.auth.currentSession;
      if (session == null) {
        _lastLog = "Accedi con il tuo account per collegare Oura.";
        return;
      }

      LogService.i('OuraService: Exchanging code via backend...');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${session.accessToken}',
        'apikey': AppConfig.supabaseAnonKey,
      };
      final redirectUriFromCallback = uri.queryParameters['redirect_uri']?.trim();
      final redirectUri = (redirectUriFromCallback != null && redirectUriFromCallback.isNotEmpty)
          ? redirectUriFromCallback
          : AppConfig.ouraRedirectUri;
      final payload = jsonEncode({
        'code': code,
        'redirect_uri': redirectUri,
      });

      var exchangeUrl = AppConfig.ouraExchangeUrl.trim();
      var response = await http.post(
        Uri.parse(exchangeUrl),
        headers: headers,
        body: payload,
      );

      // Backward compatibility: some deployments use /oura-auth as function name
      if (response.statusCode == 404 && exchangeUrl.contains('/oura-exchange')) {
        final legacyUrl = exchangeUrl.replaceFirst('/oura-exchange', '/oura-auth');
        LogService.w('OuraService: /oura-exchange not found, retrying $legacyUrl');
        exchangeUrl = legacyUrl;
        response = await http.post(
          Uri.parse(exchangeUrl),
          headers: headers,
          body: payload,
        );
      }

      _lastLog = "Status: ${response.statusCode} | URL: $exchangeUrl";

      LogService.i('OuraService: Exchange response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['access_token'] as String?;
        if (token != null && token.isNotEmpty) {
          LogService.i('OuraService: Token received successfully.');
          await setAccessToken(token);
        } else {
          _lastLog += " | Risposta senza token";
        }
      } else {
        final body = response.body;
        _lastLog += " | Body: $body";
        final decoded = jsonDecode(body) as Map<String, dynamic>?;
        final msg = decoded?['error'] ?? body;
        LogService.e('OuraService: Token exchange failed: $msg (Status: ${response.statusCode})');
        // Allow retry with a new OAuth cycle if the previous single-use code failed.
        _lastHandledAuthCode = null;
      }
    } catch (e) {
      LogService.e('OuraService: OAuth Exception: $e');
      _lastLog = "Eccezione OAuth: $e";
      _lastHandledAuthCode = null;
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
