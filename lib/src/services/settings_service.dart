import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsService extends ChangeNotifier {
  // Persistence
  SharedPreferences? _prefs;
  final SupabaseClient _supabase = Supabase.instance.client;

  // Athlete Profile
  String username = ''; // Default empty
  String sport = 'Cycling';
  int ftp = 285;
  int hrMax = 190;
  int hrThreshold = 158;
  int? weight; // Nullable
  int? bikeWeight; // Nullable
  bool useMetricUnits = true;
  
  // Coach Info
  String? coachName;
  String? coachEmail;

  // ERG/Trainer Settings
  int ergIncreasePercent = 5;
  int hrIncrease = 5;
  int slopeIncreasePercent = 1;
  int resistanceIncreasePercent = 3;
  
  // Connections status
  Map<String, bool> connections = {
    'strava': true,
    'intervalsIcu': false,
    'dropbox': false,
    'googleCalendar': false,
    'wahoo': false,
  };
  
  // Toggle Options
  bool autoExtendRecovery = false;
  bool powerSmoothing = false;
  bool shortPressNextInterval = false;
  bool powerMatch = false;
  bool doubleSidedPower = false;
  bool disableAutoStartStop = false;
  bool vibration = true;
  bool showPowerZones = true;
  bool liveWorkoutView = false;
  bool simSlopeMode = true;
  
  // Audio
  String intervalBeepType = 'Volume alto';
  final List<String> beepTypes = ['Volume alto', 'Volume medio', 'Volume basso', 'Silenzioso'];
  
  // Language
  String language = 'Italiano';
  final List<String> languages = [
    'English', 'Deutsch', 'Español', 'Français', 
    'Italiano', 'Polski', 'Русский', '日本語', '简体中文', '繁體中文'
  ];
  
  // Subscription
  String subscriptionStatus = 'Attivo';

  SettingsService() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Load local overrides
    ftp = _prefs?.getInt('ftp') ?? ftp;
    weight = _prefs?.getInt('weight');
    bikeWeight = _prefs?.getInt('bikeWeight');
    username = _prefs?.getString('username') ?? '';
    hrMax = _prefs?.getInt('hrMax') ?? hrMax;
    
    // Load Toggles & Options
    autoExtendRecovery = _prefs?.getBool('autoExtendRecovery') ?? autoExtendRecovery;
    powerSmoothing = _prefs?.getBool('powerSmoothing') ?? powerSmoothing;
    shortPressNextInterval = _prefs?.getBool('shortPressNextInterval') ?? shortPressNextInterval;
    powerMatch = _prefs?.getBool('powerMatch') ?? powerMatch;
    doubleSidedPower = _prefs?.getBool('doubleSidedPower') ?? doubleSidedPower;
    disableAutoStartStop = _prefs?.getBool('disableAutoStartStop') ?? disableAutoStartStop;
    vibration = _prefs?.getBool('vibration') ?? vibration;
    showPowerZones = _prefs?.getBool('showPowerZones') ?? showPowerZones;
    liveWorkoutView = _prefs?.getBool('liveWorkoutView') ?? liveWorkoutView;
    simSlopeMode = _prefs?.getBool('simSlopeMode') ?? simSlopeMode;
    
    // Load Numeric Settings
    hrThreshold = _prefs?.getInt('hrThreshold') ?? hrThreshold;
    ergIncreasePercent = _prefs?.getInt('ergIncreasePercent') ?? ergIncreasePercent;
    hrIncrease = _prefs?.getInt('hrIncrease') ?? hrIncrease;
    slopeIncreasePercent = _prefs?.getInt('slopeIncreasePercent') ?? slopeIncreasePercent;
    resistanceIncreasePercent = _prefs?.getInt('resistanceIncreasePercent') ?? resistanceIncreasePercent;
    
    // Load Strings
    intervalBeepType = _prefs?.getString('intervalBeepType') ?? intervalBeepType;
    language = _prefs?.getString('language') ?? language;
    
    // Load Connections
    connections.keys.forEach((key) {
      if (_prefs?.containsKey('conn_$key') == true) {
         connections[key] = _prefs!.getBool('conn_$key')!;
      }
    });

    // Try to load from Supabase if authenticated
    _loadFromSupabase();
    
    notifyListeners();
  }

  Future<void> _loadFromSupabase() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Load Athlete Data
      final data = await _supabase
          .from('athletes')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        if (data['ftp'] != null) ftp = (data['ftp'] as num).toInt();
        if (data['weight'] != null) weight = (data['weight'] as num).toInt();
        if (data['bike_weight'] != null) bikeWeight = (data['bike_weight'] as num).toInt();
        if (data['name'] != null) username = data['name'] as String;
        if (data['max_hr'] != null) hrMax = (data['max_hr'] as num).toInt();
        
        _prefs?.setInt('ftp', ftp);
        if (weight != null) _prefs?.setInt('weight', weight!);
        if (bikeWeight != null) _prefs?.setInt('bikeWeight', bikeWeight!);
        if (username.isNotEmpty) _prefs?.setString('username', username);
        _prefs?.setInt('hrMax', hrMax);
        
        notifyListeners();
      }

      // 2. Load Coach Info (via coach_athletes table)
      final coachConnection = await _supabase
          .from('coach_athletes')
          .select('coach_id')
          .eq('athlete_id', user.id)
          .maybeSingle();

      if (coachConnection != null && coachConnection['coach_id'] != null) {
        final coachId = coachConnection['coach_id'];
        final coachProfile = await _supabase
            .from('profiles')
            .select('display_name, email')
            .eq('id', coachId)
            .maybeSingle();
            
        if (coachProfile != null) {
          coachName = coachProfile['display_name'];
          coachEmail = coachProfile['email'];
          notifyListeners();
        }
      }

    } catch (e) {
      debugPrint('Error loading settings from Supabase: $e');
    }
  }

  Future<void> _updateSupabaseProfile(Map<String, dynamic> updates) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('athletes').upsert({
        'id': user.id,
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error updating Supabase profile: $e');
    }
  }
  
  // Setters with notification
  void setFtp(int value) {
    ftp = value;
    _prefs?.setInt('ftp', value);
    _updateSupabaseProfile({'ftp': value});
    notifyListeners();
  }
  
  void setHrMax(int value) {
    hrMax = value;
    _prefs?.setInt('hrMax', value);
    _updateSupabaseProfile({'max_hr': value});
    notifyListeners();
  }

  void setUsername(String value) {
    username = value;
    _prefs?.setString('username', value);
    _updateSupabaseProfile({'name': value});
    notifyListeners();
  }
  
  void setHrThreshold(int value) {
    hrThreshold = value;
    _prefs?.setInt('hrThreshold', value);
    notifyListeners();
  }
  
  void setErgIncrease(int value) {
    ergIncreasePercent = value;
    _prefs?.setInt('ergIncreasePercent', value);
    notifyListeners();
  }
  
  void setHrIncrease(int value) {
    hrIncrease = value;
    _prefs?.setInt('hrIncrease', value);
    notifyListeners();
  }
  
  void setSlopeIncrease(int value) {
    slopeIncreasePercent = value;
    _prefs?.setInt('slopeIncreasePercent', value);
    notifyListeners();
  }
  
  void setResistanceIncrease(int value) {
    resistanceIncreasePercent = value;
    _prefs?.setInt('resistanceIncreasePercent', value);
    notifyListeners();
  }
  
  void toggleAutoExtendRecovery() {
    autoExtendRecovery = !autoExtendRecovery;
    _prefs?.setBool('autoExtendRecovery', autoExtendRecovery);
    notifyListeners();
  }
  
  void togglePowerSmoothing() {
    powerSmoothing = !powerSmoothing;
    _prefs?.setBool('powerSmoothing', powerSmoothing);
    notifyListeners();
  }
  
  void toggleShortPressNextInterval() {
    shortPressNextInterval = !shortPressNextInterval;
    _prefs?.setBool('shortPressNextInterval', shortPressNextInterval);
    notifyListeners();
  }
  
  void togglePowerMatch() {
    powerMatch = !powerMatch;
    _prefs?.setBool('powerMatch', powerMatch);
    notifyListeners();
  }
  
  void toggleDoubleSidedPower() {
    doubleSidedPower = !doubleSidedPower;
    _prefs?.setBool('doubleSidedPower', doubleSidedPower);
    notifyListeners();
  }
  
  void toggleDisableAutoStartStop() {
    disableAutoStartStop = !disableAutoStartStop;
    _prefs?.setBool('disableAutoStartStop', disableAutoStartStop);
    notifyListeners();
  }
  
  void toggleVibration() {
    vibration = !vibration;
    _prefs?.setBool('vibration', vibration);
    notifyListeners();
  }
  
  void toggleShowPowerZones() {
    showPowerZones = !showPowerZones;
    _prefs?.setBool('showPowerZones', showPowerZones);
    notifyListeners();
  }
  
  void toggleLiveWorkoutView() {
    liveWorkoutView = !liveWorkoutView;
    _prefs?.setBool('liveWorkoutView', liveWorkoutView);
    notifyListeners();
  }
  
  void toggleSimSlopeMode() {
    simSlopeMode = !simSlopeMode;
    _prefs?.setBool('simSlopeMode', simSlopeMode);
    notifyListeners();
  }
  
  void setLanguage(String lang) {
    language = lang;
    _prefs?.setString('language', lang);
    notifyListeners();
  }
  
  void setBeepType(String type) {
    intervalBeepType = type;
    _prefs?.setString('intervalBeepType', type);
    notifyListeners();
  }
  
  void setWeight(int value) {
    weight = value;
    _prefs?.setInt('weight', value);
    notifyListeners();
  }
  
  void setBikeWeight(int value) {
    bikeWeight = value;
    _prefs?.setInt('bikeWeight', value);
    notifyListeners();
  }
  
  void toggleMetricUnits() {
    useMetricUnits = !useMetricUnits;
    // Note: useMetricUnits persistence wasn't in original list but good to add
    _prefs?.setBool('useMetricUnits', useMetricUnits);
    notifyListeners();
  }
  
  void toggleConnection(String key) {
    if (connections.containsKey(key)) {
      connections[key] = !connections[key]!;
      _prefs?.setBool('conn_$key', connections[key]!);
      notifyListeners();
    }
  }
}
