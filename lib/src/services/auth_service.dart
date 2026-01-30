import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  User? _currentUser;
  String? _athleteId;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  String? get athleteId => _athleteId;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthService() {
    _currentUser = _supabase.auth.currentUser;
    if (_currentUser != null) {
      _fetchAthleteId();
    }
    
    _supabase.auth.onAuthStateChange.listen((data) {
      final previousUser = _currentUser;
      _currentUser = data.session?.user;
      
      if (_currentUser != null && previousUser?.id != _currentUser!.id) {
        _fetchAthleteId();
      } else if (_currentUser == null) {
        _athleteId = null;
        notifyListeners();
      }
    });
  }

  Future<void> _fetchAthleteId() async {
    if (_currentUser?.email == null) return;
    
    try {
      // Try to find athlete by email (Link to Coach-created profile)
      final data = await _supabase
          .from('athletes')
          .select('id')
          .ilike('email', _currentUser!.email!)
          .maybeSingle();

      if (data != null) {
        _athleteId = data['id'];
        debugPrint("AuthService: Linked to existing athlete profile: $_athleteId");
      } else {
        // Fallback: Use Auth ID (Profile might be created later or via trigger)
        _athleteId = _currentUser!.id;
        debugPrint("AuthService: No existing profile found. Using Auth ID: $_athleteId");
      }
      notifyListeners();
    } catch (e) {
      debugPrint("AuthService Error fetching athlete ID: $e");
      // Fallback on error
      _athleteId = _currentUser?.id;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      await _supabase.auth.signInWithPassword(email: email, password: password);
      // Auth state change listener will trigger ID fetch
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      await _supabase.auth.signUp(email: email, password: password);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    // Clear integration tokens on logout to prevent persistence across accounts
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('strava_access_token');
    await prefs.remove('strava_refresh_token');
    await prefs.remove('strava_expires_at');
    await prefs.remove('garmin_connected');
    await prefs.remove('wahoo_connected');
    await prefs.remove('tp_connected');
    await prefs.remove('oura_access_token');
    await prefs.remove('intervals_api_key');
    await prefs.remove('intervals_athlete_id');

    await _supabase.auth.signOut();
    _athleteId = null;
    notifyListeners();
  }
}
