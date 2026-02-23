import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class AppConfig {
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

  static String get ouraClientId {
    const fromEnv = String.fromEnvironment('OURA_CLIENT_ID');
    if (fromEnv.isNotEmpty) return fromEnv;
    return dotenv.env['OURA_CLIENT_ID'] ?? '';
  }

  static String get ouraRedirectUri {
    const fromEnv = String.fromEnvironment('OURA_REDIRECT_URI');
    if (fromEnv.isNotEmpty) return fromEnv;
    return dotenv.env['OURA_REDIRECT_URI'] ?? 'https://cycling-coach-platform.vercel.app/api/oauth/oura-callback';
  }

  /// Supabase Edge Function: exchange Oura code for tokens (secret stays in Supabase).
  static String get ouraExchangeUrl {
    const fromEnv = String.fromEnvironment('OURA_EXCHANGE_URL');
    if (fromEnv.isNotEmpty) return fromEnv.trim();
    final base = dotenv.env['OURA_EXCHANGE_URL'];
    if (base != null && base.isNotEmpty) return base.trim();
    final baseUrl = supabaseUrl.replaceAll(RegExp(r'/+$'), '');
    if (baseUrl.isEmpty) return 'https://xdqvjqqwywuguuhsehxm.supabase.co/functions/v1/oura-exchange';
    return '$baseUrl/functions/v1/oura-exchange';
  }

  /// Load configuration. 
  /// We always try loading `.env` from app assets first.
  /// `String.fromEnvironment` values still take priority in getters, so
  /// `--dart-define` keeps working for production pipelines.
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: ".env");
      if (!kReleaseMode) {
        debugPrint("Loaded .env file");
      }
    } catch (e) {
      if (!kReleaseMode) {
        debugPrint("Note: .env file not found or not loadable. Using --dart-define variables.");
      }
    }
  }
}
