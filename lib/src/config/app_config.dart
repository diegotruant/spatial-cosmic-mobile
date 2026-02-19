import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class AppConfig {
  static const bool _isProduction = bool.fromEnvironment('dart.vm.product');

  static String get supabaseUrl {
    const fromEnv = String.fromEnvironment('SUPABASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    return dotenv.env['SUPABASE_URL'] ?? '';
  }

  static String get supabaseAnonKey {
    const fromEnv = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (fromEnv.isNotEmpty) return fromEnv;
    return dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  }

  static bool get isValid {
    return supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  }

  static String get stravaClientId {
    const fromEnv = String.fromEnvironment('STRAVA_CLIENT_ID');
    if (fromEnv.isNotEmpty) return fromEnv;
    return dotenv.env['STRAVA_CLIENT_ID'] ?? '69269';
  }

  static String get stravaClientSecret {
    const fromEnv = String.fromEnvironment('STRAVA_CLIENT_SECRET');
    if (fromEnv.isNotEmpty) return fromEnv;
    return dotenv.env['STRAVA_CLIENT_SECRET'] ?? '7c3a310d1aca2a143a6de74e0b0ba7625e028df7';
  }
  
  static String get stravaRedirectUri {
    const fromEnv = String.fromEnvironment('STRAVA_REDIRECT_URI');
    if (fromEnv.isNotEmpty) return fromEnv;
    return dotenv.env['STRAVA_REDIRECT_URI'] ?? 'https://xdqvjqqwywuguuhsehxm.supabase.co/functions/v1/strava-auth';
  }

  static String get analysisServiceUrl {
    const fromEnv = String.fromEnvironment('ANALYSIS_SERVICE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    return dotenv.env['ANALYSIS_SERVICE_URL'] ?? 'https://spatial-analysis-service.onrender.com';
  }

  /// Load configuration. 
  /// In release mode, we expect secrets to be passed via --dart-define.
  /// In debug mode, we try to load .env file if available (but it's not in assets anymore!)
  /// Note: Since .env is removed from assets, dotenv.load() will fail in release builds 
  /// or if the file isn't found. We handle this gracefully.
  static Future<void> load() async {
    if (!kReleaseMode) {
      try {
        await dotenv.load(fileName: ".env");
        debugPrint("Loaded .env file for development");
      } catch (e) {
        debugPrint("Note: .env file not found or not loadable. Using --dart-define variables.");
      }
    }
  }
}
