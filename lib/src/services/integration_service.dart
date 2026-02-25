import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:spatial_cosmic_mobile/src/logic/fit_generator.dart';
import 'package:spatial_cosmic_mobile/src/logic/zwo_parser.dart';
import 'package:spatial_cosmic_mobile/src/config/app_config.dart';
import 'package:spatial_cosmic_mobile/src/services/log_service.dart';
import 'package:spatial_cosmic_mobile/src/services/secure_storage_service.dart';

class IntegrationService extends ChangeNotifier {
  // Strava Configuration
  // Strava Configuration
  // Secrets are now loaded from .env via flutter_dotenv
  // static const String _stravaClientId = ... (Removed for security)
  
  // Use 'activity:write' to allow uploads. 'activity:read_all' for reading.
  static const String _stravaScope = 'read,activity:read_all,activity:write';

  bool _isStravaConnected = false;
  bool get isStravaConnected => _isStravaConnected;
  
  String? _stravaAccessToken;
  // String? _wahooAccessToken; // Removed

  String? _currentUserId;
  SupabaseClient get _supabase => Supabase.instance.client;

  IntegrationService() {
    // We can't access Supabase.instance here safely if we aren't absolutely sure about the timing
    // Instead, we will initialize in a post-boot phase or lazily.
    // For now, let's just make it not crash.
    _loadCredentials();
    _listenAuthChanges();
  }

  void _listenAuthChanges() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final newUserId = data.session?.user.id;
      if (_currentUserId != newUserId) {
        _currentUserId = newUserId;
        _stravaAccessToken = null;
        _isStravaConnected = false;
        notifyListeners();
        Future.microtask(() async {
          await _loadCredentials();
          await syncFromSupabase();
        });
      }
    });
  }

  String _userKey(String key, String? userId) {
    if (userId == null || userId.isEmpty) return key;
    return '${key}_$userId';
  }

  Future<void> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final accessKey = _userKey('strava_access_token', userId);
    final refreshKey = _userKey('strava_refresh_token', userId);
    // Expires time is not strictly secret, but kept with tokens usually. SharedPreferences is fine for expires, but SecureStorage better for consistency?
    // Actually SecureStorage stores strings. Expires is int.
    // Let's keep expires in SharedPreferences for simplicity or convert to string.
    // Migration logic in main.dart might have moved it? No, I strictly moved tokens.
    // Let's keep expires in Prefs to avoid type issues for now, or parseInt.
    final expiresKey = _userKey('strava_expires_at', userId);

    _stravaAccessToken = await SecureStorage.read(accessKey);
    // Fallback logic handled in migration, removing legacy inline logic here to simplify.
    if (_stravaAccessToken == null && userId != null) {
      final legacyAccess = prefs.getString('strava_access_token');
      if (legacyAccess != null) {
        await prefs.setString(accessKey, legacyAccess);
        await prefs.remove('strava_access_token');
        final legacyRefresh = prefs.getString('strava_refresh_token');
        if (legacyRefresh != null) {
          await prefs.setString(refreshKey, legacyRefresh);
          await prefs.remove('strava_refresh_token');
        }
        final legacyExpires = prefs.getInt('strava_expires_at');
        if (legacyExpires != null) {
          await prefs.setInt(expiresKey, legacyExpires);
          await prefs.remove('strava_expires_at');
        }
        _stravaAccessToken = legacyAccess;
      }
    }
    _isStravaConnected = _stravaAccessToken != null;
    
    _isStravaConnected = _stravaAccessToken != null;
    
    // Wahoo and TP removed
    
    notifyListeners();
  }

  Future<void> initiateStravaAuth() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    final email = user.email ?? '';
    final userId = user.id;
    final state = email.isNotEmpty ? 'mobile:$userId:$email' : 'mobile:$userId';

    final Uri url = Uri.https(
      'www.strava.com',
      '/oauth/authorize',
      {
        'client_id': AppConfig.stravaClientId,
        'response_type': 'code',
        'redirect_uri': AppConfig.stravaRedirectUri,
        'approval_prompt': 'force',
        'scope': _stravaScope,
        'state': state,
      },
    );

    try {
      LogService.i('Launching Strava Auth URL: $url');
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
         LogService.e('Could not launch Strava URL');
      }
    } catch (e) {
      LogService.e('Exception launching Strava URL: $e');
    }
  }
  
  Future<void> handleAuthCallback(Uri uri) async {
    LogService.i('Handling Auth Callback: $uri');
    // Relaxed check: just look for success param or error
    final success = uri.queryParameters['success'] == 'true';
    final error = uri.queryParameters['error'];
    final provider = uri.queryParameters['provider']; 
    
    if (error != null) {
      LogService.e('Auth Error: $error');
      return;
    }
    
    if (success) {
      LogService.i('Success param found for $provider. Syncing...');
      await syncFromSupabase();
    }
  }

  Future<void> syncFromSupabase() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .from('athletes')
          .select('id, email, extra_data')
          .eq('id', user.id)
          .maybeSingle();

      Map<String, dynamic>? row = response;
      if (row == null && user.email != null) {
        row = await _supabase
            .from('athletes')
            .select('id, email, extra_data')
            .ilike('email', user.email!)
            .maybeSingle();
      }

      if (row != null && row['extra_data'] != null) {
        final extraData = Map<String, dynamic>.from(row['extra_data']);
        
        // Sync Strava
        Map<String, dynamic>? strava;
        if (extraData.containsKey('integrations') && extraData['integrations']['strava'] != null) {
          strava = Map<String, dynamic>.from(extraData['integrations']['strava']);
        } else if (extraData.containsKey('strava')) {
          strava = Map<String, dynamic>.from(extraData['strava']);
        }

        if (strava != null) {
          await _saveStravaCredentials(
            strava['accessToken'],
            strava['refreshToken'],
            strava['expiresAt'],
            syncToSupabase: false, 
          );
          LogService.i('Strava credentials synced from Supabase');
        }

        // Wahoo sync removed
      }
    } catch (e) {
      LogService.e('Sync from Supabase failed: $e');
    }
  }

  /// Token exchange is done server-side (Supabase Edge Function strava-auth).
  /// Client-side exchange with secret is removed for security.
  Future<void> _saveStravaCredentials(String accessToken, String refreshToken, int expiresAt, {bool syncToSupabase = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = _supabase.auth.currentUser?.id;
    await SecureStorage.write(_userKey('strava_access_token', userId), accessToken);
    await SecureStorage.write(_userKey('strava_refresh_token', userId), refreshToken);
    await prefs.setInt(_userKey('strava_expires_at', userId), expiresAt);
    
    _stravaAccessToken = accessToken;
    _isStravaConnected = true;
    notifyListeners();
    if (!syncToSupabase) return;

    // Sync to Supabase for Edge Functions (Option B)
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        // Fetch current extra_data to merge
        final response = await supabase
            .from('athletes')
            .select('id, email, extra_data')
            .eq('id', user.id)
            .maybeSingle();

        Map<String, dynamic>? row = response;
        if (row == null && user.email != null) {
          row = await supabase
              .from('athletes')
              .select('id, email, extra_data')
              .ilike('email', user.email!)
              .maybeSingle();
        }
            
        Map<String, dynamic> extraData = {};
        if (row != null && row['extra_data'] != null) {
          extraData = Map<String, dynamic>.from(row['extra_data']);
        }
        
        final stravaData = {
          'accessToken': accessToken,
          'refreshToken': refreshToken,
          'expiresAt': expiresAt,
          'updatedAt': DateTime.now().toIso8601String(),
        };

        // Save to both top-level (for legacy) and nested integrations (for web app)
        extraData['strava'] = stravaData;
        
        Map<String, dynamic> integrations = extraData.containsKey('integrations') 
            ? Map<String, dynamic>.from(extraData['integrations']) 
            : {};
        integrations['strava'] = stravaData;
        extraData['integrations'] = integrations;

        await supabase
            .from('athletes')
            .update({'extra_data': extraData})
            .eq('id', user.id);
        debugPrint('Strava tokens synced to Supabase (nested)');
      }
    } catch (e) {
      LogService.e('Supabase Sync Error: $e');
    }
  }
  
  Future<void> disconnectStrava() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final accessToken = await SecureStorage.read(_userKey('strava_access_token', userId));
    await SecureStorage.delete(_userKey('strava_access_token', userId));
    await SecureStorage.delete(_userKey('strava_refresh_token', userId));
    await prefs.remove(_userKey('strava_expires_at', userId));
    
    _stravaAccessToken = null;
    _isStravaConnected = false;
    notifyListeners();

    // Deauthorize from Strava (removes the athlete from the app on Strava side)
    try {
      if (accessToken != null && accessToken.isNotEmpty) {
        await http.post(
          Uri.parse('https://www.strava.com/oauth/deauthorize'),
          body: {'access_token': accessToken},
        );
      }
    } catch (e) {
      LogService.e('Strava deauthorize error: $e');
    }

    // Remove from Supabase
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        Map<String, dynamic>? row = await supabase
            .from('athletes')
            .select('id, email, extra_data')
            .eq('id', user.id)
            .maybeSingle();
        if (row == null && user.email != null) {
          row = await supabase
              .from('athletes')
              .select('id, email, extra_data')
              .ilike('email', user.email!)
              .maybeSingle();
        }
            
        if (row != null && row['extra_data'] != null) {
          Map<String, dynamic> extraData = Map<String, dynamic>.from(row['extra_data']);
          extraData.remove('strava');
          if (extraData.containsKey('integrations')) {
            final integrations = Map<String, dynamic>.from(extraData['integrations']);
            integrations.remove('strava');
            extraData['integrations'] = integrations;
          }
          await supabase
              .from('athletes')
              .update({'extra_data': extraData})
              .eq('id', user.id);
          debugPrint('Strava tokens removed from Supabase');
        }
      }
    } catch (e) {
      LogService.e('Supabase Disconnect Error: $e');
    }
  }

  // Dropbox
  Future<void> initiateDropboxAuth() async {
    final stravaRedirectUri = dotenv.env['STRAVA_REDIRECT_URI']!;
    final Uri url = Uri.parse('https://www.dropbox.com/oauth2/authorize?client_id=DROPBOX_APP_KEY&response_type=code&redirect_uri=$stravaRedirectUri');
    await _launchAuthUrl(url);
  }
  
  Future<bool> uploadActivityToStrava(File file, {String? activityName}) async {
    if (_stravaAccessToken == null) {
      debugPrint('Strava non connesso');
      return false;
    }
    
    try {
      final uri = Uri.parse('https://www.strava.com/api/v3/uploads');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $_stravaAccessToken'
        ..files.add(await http.MultipartFile.fromPath('file', file.path))
        ..fields['data_type'] = 'fit'
        ..fields['name'] = activityName ?? 'Spatial Cosmic Ride';
        
      final response = await request.send();
      if (response.statusCode == 201) {
        debugPrint('Strava Upload Success!');
        return true;
      } else {
        final respStr = await response.stream.bytesToString();
        debugPrint('Strava Upload Failed: ${response.statusCode} - $respStr');
        return false;
      }
    } catch (e) {
      debugPrint('Strava Upload Exception: $e');
      return false;
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
