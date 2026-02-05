import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../logic/metabolic_calculator.dart';
import '../models/metabolic_profile.dart';
import 'package:http/http.dart' as http;

enum AthleteType { sprinter, allRounder, timeTrialist, climber, unknown }

class AthleteProfile {
  final double? vlamax; // mmol/L/s
  final double? vo2max; // ml/kg/min
  final double? ftp; // Watts
  final double? cp; // Critical Power
  final AthleteType type;
  final String description;
  final double? weight;
  final double? height;
  final DateTime? dob;
  final double? leanMass;
  final double? wPrime; // Joules

  AthleteProfile({
    this.vlamax,
    this.vo2max,
    this.ftp,
    this.cp,
    required this.type,
    required this.description,
    this.weight,
    this.height,
    this.dob,
    this.leanMass,
    this.wPrime,
  });
}



class AthleteProfileService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Power curve data (duration in seconds -> power in watts)
  final Map<int, double> powerCurve = {};

  // Dependency
  String? _athleteId;

  double? _ftp;
  double? _cp;
  double? _vo2max;
  double? _vlamax;
  
  double? _weight;
  double? _height;
  DateTime? _dob;
  double? _leanMass;
  DateTime? _certExpiryDate;
  double? _wPrime;
  
  // Metabolic v4.0 specific
  double? _bodyFat;
  String _somatotype = 'ectomorph'; // Default: ectomorph, stored as string
  String _athleteLevel = 'amateur'; // Default: amateur
  String _gender = 'male'; // Default: male
  String? _timeAvailable;
  String? _discipline;

  // Output profile
  MetabolicProfile? _lastCalculatedProfile;

  bool _isLoading = false;
  StreamSubscription<List<Map<String, dynamic>>>? _profileSubscription;
  String? _listeningAthleteId;
  String? _metabolicUpdatedAt;

  double? get ftp => _ftp;
  double? get cp => _cp;
  double? get vo2max => _vo2max;
  double? get vlamax => _vlamax;
  double? get weight => _weight;
  double? get height => _height;
  DateTime? get dob => _dob;
  double? get leanMass => _leanMass;
  DateTime? get certExpiryDate => _certExpiryDate;
  double? get wPrime => _wPrime;
  
  double? get bodyFat => _bodyFat;
  String get somatotype => _somatotype;
  String get athleteLevel => _athleteLevel;
  String get gender => _gender;
  String? get timeAvailable => _timeAvailable;
  String? get discipline => _discipline;
  
  MetabolicProfile? get metabolicProfile => _lastCalculatedProfile;
  
  bool get isLoading => _isLoading;

  AthleteProfileService();

  void updateAthleteId(String? id) {
    if (id != _athleteId) {
      _athleteId = id;
      if (_athleteId != null) {
        _startMetabolicProfileListener(_athleteId!);
        _loadFromSupabase();
      }
    }
  }

  void _startMetabolicProfileListener(String athleteId) {
    if (_listeningAthleteId == athleteId) return;
    _profileSubscription?.cancel();
    _listeningAthleteId = athleteId;

    _profileSubscription = _supabase
        .from('athletes')
        .stream(primaryKey: ['id'])
        .eq('id', athleteId)
        .listen((rows) {
      if (rows.isEmpty) return;
      final row = rows.first;
      final mpRaw = row['metabolic_profile'];
      String? updatedAt;
      if (mpRaw is Map && mpRaw['updatedAt'] is String) {
        updatedAt = mpRaw['updatedAt'] as String;
      }

      if (updatedAt != null && updatedAt != _metabolicUpdatedAt) {
        debugPrint('[AthleteProfile] metabolic_profile updatedAt changed: $updatedAt');
        _metabolicUpdatedAt = updatedAt;
        _loadFromSupabase();
      }
    });
  }

  Future<void> _loadFromSupabase() async {
    final targetId = _athleteId ?? _supabase.auth.currentUser?.id;
    if (targetId == null) return;
    _startMetabolicProfileListener(targetId);

    _isLoading = true;
    notifyListeners();

    try {
      final data = await _supabase
          .from('athletes')
          .select('ftp, cp, vo2max, vlamax, weight, height, dob, lean_mass, cert_expiry_date, body_fat, somatotype, athlete_level, gender, w_prime, metabolic_profile, extra_data, time_available, discipline')
          .eq('id', targetId)
          .maybeSingle();

      if (data != null) {
        // Valori "legacy" dalle colonne top-level
        // NB: se esiste un metabolic_profile valido usiamo SEMPRE quello come sorgente principale
        _ftp = _toDouble(data['ftp']);
        _cp = _toDouble(data['cp']);
        _vo2max = _toDouble(data['vo2max']);
        _vlamax = _toDouble(data['vlamax']);
        _wPrime = _toDouble(data['w_prime']);
        
        _weight = _toDouble(data['weight']);
        _height = _toDouble(data['height']);
        _leanMass = _toDouble(data['lean_mass']);
        if (data['dob'] != null) _dob = DateTime.tryParse(data['dob']);
        if (data['cert_expiry_date'] != null) _certExpiryDate = DateTime.tryParse(data['cert_expiry_date']);
        
        _bodyFat = _toDouble(data['body_fat']);
        if (data['somatotype'] != null) _somatotype = data['somatotype'];
        if (data['athlete_level'] != null) _athleteLevel = data['athlete_level'];
        if (data['gender'] != null) _gender = data['gender'];
        if (data['time_available'] != null) _timeAvailable = data['time_available'];
        if (data['discipline'] != null) _discipline = data['discipline'];
        
        // Sorgente principale per il profilo metabolico:
        // 1) colonna metabolic_profile (usata dal MetabolicEngine web)
        // 2) extra_data.metabolic_profile solo come fallback
        dynamic metabolicSource = data['metabolic_profile'];
        debugPrint('[AthleteProfile] Checking metabolic_profile. Column value is null: ${metabolicSource == null}');
        
        if (metabolicSource == null) {
          debugPrint('[AthleteProfile] metabolic_profile column is null, checking extra_data...');
          try {
            if (data['extra_data'] != null) {
              final extra = Map<String, dynamic>.from(data['extra_data']);
              if (extra['metabolic_profile'] != null) {
                metabolicSource = extra['metabolic_profile'];
                debugPrint('[AthleteProfile] Found metabolic_profile in extra_data');
              } else {
                debugPrint('[AthleteProfile] No metabolic_profile in extra_data either');
              }
            }
          } catch (e) {
            debugPrint('[AthleteProfile] Error checking extra_data: $e');
          }
        } else {
          debugPrint('[AthleteProfile] Found metabolic_profile in main column');
        }

        if (metabolicSource != null) {
          try {
            var mpRaw = metabolicSource;
            Map<String, dynamic>? mpMap;
            
            if (mpRaw is Map) {
              mpMap = Map<String, dynamic>.from(mpRaw);
              debugPrint('[AthleteProfile] metabolic_profile is already a Map');
            } else if (mpRaw is String) {
              mpMap = jsonDecode(mpRaw) as Map<String, dynamic>?;
              debugPrint('[AthleteProfile] metabolic_profile was a String, decoded to Map');
            } else {
              debugPrint('[AthleteProfile] metabolic_profile has unexpected type: ${mpRaw.runtimeType}');
            }

            if (mpMap != null) {
              debugPrint('[AthleteProfile] Parsing metabolic_profile JSON. Keys: ${mpMap.keys.toList()}');
              
              if (mpMap['updatedAt'] is String) {
                _metabolicUpdatedAt = mpMap['updatedAt'] as String;
                debugPrint('[AthleteProfile] updatedAt: $_metabolicUpdatedAt');
              }
              if (mpMap['schemaVersion'] == null) {
                debugPrint('[AthleteProfile] ⚠️ metabolic_profile senza schemaVersion - PROFILO VECCHIO!');
                debugPrint('[AthleteProfile] Questo profilo è stato salvato prima dell\'aggiornamento. Ricalcola dalla webapp.');
              }
              if (mpMap['updatedAt'] == null) {
                debugPrint('[AthleteProfile] ⚠️ metabolic_profile senza updatedAt - PROFILO VECCHIO!');
              }
              
              // Log raw values before parsing
              debugPrint('[AthleteProfile] Raw values - vlamax: ${mpMap['vlamax']}, vo2max: ${mpMap['vo2max']}');
              if (mpMap['metabolic'] != null) {
                final metabolicRaw = mpMap['metabolic'] as Map<String, dynamic>;
                debugPrint('[AthleteProfile] Raw metabolic.estimatedFtp: ${metabolicRaw['estimatedFtp']}');
              }
              
              final mp = MetabolicProfile.fromJson(mpMap);
              _lastCalculatedProfile = mp;
              
              // Allinea SEMPRE i valori chiave al profilo metabolico (stessa sorgente della webapp)
              final oldFtp = _ftp;
              final oldVlamax = _vlamax;
              
              _ftp = mp.metabolic.estimatedFtp;
              _vo2max = mp.vo2max;
              _vlamax = mp.vlamax;
              _wPrime = mp.wPrime ?? _wPrime;
              
              debugPrint('[AthleteProfile] ✅ Successfully loaded metabolic profile.');
              debugPrint('[AthleteProfile] FTP: $oldFtp → $_ftp (from metabolic.estimatedFtp: ${mp.metabolic.estimatedFtp})');
              debugPrint('[AthleteProfile] VLamax: $oldVlamax → $_vlamax');
              debugPrint('[AthleteProfile] VO2max: $_vo2max');
              debugPrint('[AthleteProfile] W\': $_wPrime');
              debugPrint('[AthleteProfile] Athlete type will be: ${_categorizeAthlete()}');
            } else {
              debugPrint('[AthleteProfile] ⚠️ mpMap is null after parsing');
            }
          } catch (e, stack) {
            debugPrint('[AthleteProfile] ❌ Error parsing metabolic_profile JSON: $e');
            debugPrint('[AthleteProfile] Stack trace: $stack');
          }
        } else {
          debugPrint('[AthleteProfile] ⚠️ No metabolic_profile found. Using legacy values: FTP=$_ftp, VLamax=$_vlamax');
          debugPrint('[AthleteProfile] Athlete type from legacy values: ${_categorizeAthlete()}');
        }
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading profile from Supabase: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }


  Future<void> updateProfile({
    double? weight,
    double? height,
    DateTime? dob,
    double? leanMass,
    DateTime? certExpiryDate,
    double? bodyFat,
    String? somatotype,
    String? athleteLevel,
    String? gender,
    double? wPrime,
    double? cp,
    double? ftp,
    double? vo2max,
    double? vlamax,
    String? timeAvailable,
    String? discipline,
  }) async {
    final targetId = _athleteId ?? _supabase.auth.currentUser?.id;
    if (targetId == null) return;
    
    final updates = <String, dynamic>{};
    if (weight != null) updates['weight'] = weight;
    if (height != null) updates['height'] = height;
    if (dob != null) updates['dob'] = dob.toIso8601String();
    if (leanMass != null) updates['lean_mass'] = leanMass;
    if (certExpiryDate != null) updates['cert_expiry_date'] = certExpiryDate.toIso8601String();
    if (wPrime != null) updates['w_prime'] = wPrime;
    if (cp != null) updates['cp'] = cp;
    if (ftp != null) updates['ftp'] = ftp.round();
    if (vo2max != null) updates['vo2max'] = vo2max;
    if (vlamax != null) updates['vlamax'] = vlamax;
    
    if (bodyFat != null) updates['body_fat'] = bodyFat;
    if (somatotype != null) updates['somatotype'] = somatotype;
    if (athleteLevel != null) updates['athlete_level'] = athleteLevel;
    if (gender != null) updates['gender'] = gender;
    if (timeAvailable != null) updates['time_available'] = timeAvailable;
    if (discipline != null) updates['discipline'] = discipline;
    
    if (updates.isEmpty) return;

    try {
      await _supabase.from('athletes').update(updates).eq('id', targetId);
      
      // Update local state
      if (weight != null) _weight = weight;
      if (height != null) _height = height;
      if (dob != null) _dob = dob;
      if (leanMass != null) _leanMass = leanMass;
      if (certExpiryDate != null) _certExpiryDate = certExpiryDate;
      
      if (bodyFat != null) _bodyFat = bodyFat;
      if (somatotype != null) _somatotype = somatotype;
      if (athleteLevel != null) _athleteLevel = athleteLevel;
      if (gender != null) _gender = gender;
      if (timeAvailable != null) _timeAvailable = timeAvailable;
      if (discipline != null) _discipline = discipline;
      if (wPrime != null) _wPrime = wPrime;
      if (cp != null) _cp = cp;
      if (ftp != null) _ftp = ftp;
      if (vo2max != null) _vo2max = vo2max;
      if (vlamax != null) _vlamax = vlamax;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  AthleteProfile get currentProfile {
    final type = _categorizeAthlete();
    return AthleteProfile(
      vlamax: _vlamax,
      vo2max: _vo2max,
      ftp: _ftp,
      type: type,
      description: _getDescription(type),
      weight: _weight,
      height: _height,
      dob: _dob,
      leanMass: _leanMass,
      wPrime: _wPrime,
      cp: _cp,
    );
  }

  /// Calculates VLamax based on a significant 15s sprint effort.
  /// Formula: VLamax = P_glyc / (t_test * k * M_body)
  /// P_glyc = P_12s - P_aerob - P_alac (P_alac is handled by ignoring first 3s)
  Future<void> calculateAndSaveVLamax(List<double> powerHistory, int currentFtp) async {
     if (powerHistory.isEmpty || _weight == null) return;
     
     // 1. Identify Peak 15s Power
     // We need at least 15 seconds of data
     if (powerHistory.length < 15) return;
     
     double max15sPower = 0;
     int max15sIndex = 0;
     
     // Simple moving average
     for (int i = 0; i <= powerHistory.length - 15; i++) {
       double sum = 0;
       for (int j = 0; j < 15; j++) {
         sum += powerHistory[i + j];
       }
       double avg = sum / 15.0;
       if (avg > max15sPower) {
         max15sPower = avg;
         max15sIndex = i;
       }
     }
     
     // 2. Check significance (e.g. > 150% FTP)
     // If the effort wasn't maximal, we shouldn't calculate physiological max parameters
     if (max15sPower < (currentFtp * 1.5)) {
       debugPrint("VLamax Calc: Peak 15s power ($max15sPower W) not significant enough (< 150% FTP). Skipping.");
       return;
     }

     debugPrint("VLamax Calc: Significant effort detected. Peak 15s: $max15sPower W");

     // 3. Extract the last 12 seconds of the 15s window (isolating glycolytic)
     // The 15s window starts at max15sIndex.
     // We skip the first 3s (Alactic phase).
     // Window indices: [0, 1, 2] -> Skip. [3..14] -> Use.
     
     double sumLast12 = 0;
     int count = 0;
     for (int k = 3; k < 15; k++) {
       sumLast12 += powerHistory[max15sIndex + k];
       count++;
     }
     double p12s = count > 0 ? sumLast12 / count : 0;
     
     if (p12s == 0) return;
     
     // 4. Calculate P_aerob
     // P_aerob = VO2max * 0.0115 (approx efficiency factor)
     // If VO2max is missing, we use a default or skip? Let's use current _vo2max (default 58 if not set)
     // Wait, the formula P_aerob = eta * VO2max provided by user:
     // "P_netta = P_media15s - (VO2max * 0.0115)" -> Note: User didn't specify units clearly here.
     // Usually VO2max is relative (ml/kg/min).
     // Let's assume the user meant absolute power contribution.
     // 1 L O2/min ~ 5 kcal/min ~ 350 Watts (gross). Net efficiency ~23% -> ~80 Watts/L.
     // If VO2max = 60 ml/kg/min * 75kg = 4500 ml/min = 4.5 L/min.
     // Aerobic Power ~ 4.5 * 80 = 360 Watts.
     
     // User formula: P_aerob = VO2max * 0.0115 (indicativo).
     // If VO2max is 60... 60 * 0.0115 = 0.69 Watts? No.
     // If VO2max is absolute (ml/min)? 4500 * 0.0115 = 51.75 Watts? No.
     
     // Let's look at the user example:
     // "P_netta = P_media15s - (VO2_max * 0.0115)"
     // If this subtraction yields Watts, and P_media is ~900W...
     // It's likely they meant VO2max in ml/min * constant? Or maybe VO2max relative * Weight?
     
     // Let's stick to standard principles if user formula is ambiguous, OR try to interpret.
     // Standard: P_aerob (W) during sprint is small.
     // Let's use: P_aerob = (VO2max_relative * Weight) / 1000 * 75 (approx Watts per L/min efficiency).
     // Or use user's formula P_aerob = eta * VO2max.
     
     // Let's try to interpret "0.0115".
     // If VO2max is 4000 (absolute).. 4000 * 0.0115 = 46W. Plausible for start of sprint?
     // If VO2max is 60 (relative)... 60 * 0.0115 = 0.69. Negligible.
     
     // Let's assume the user meant: P_aerob = (VO2max_relative * Weight) * 0.0115 doesn't make sense dimensionally.
     // Actually, let's use a robust estimation:
     // P_aerob contribution in 15s is ~10-15%.
     // Let's calculate P_aerob_max = (VO2max * Weight / 1000) * 75.
     // In first 15s, kinetics are slow. Maybe 20% of VO2max reached?
     // Let's conservatively subtract 10% of P12s as aerobic if we can't be sure.
     
     // BUT, the user gave: "P_netta = P_media15s - (VO2_max * 0.0115)"
     // Maybe they meant VO2max expressed in a different unit?
     // Let's use the USER'S SPECIFIC EXAMPLE to reverse engineer.
     // Example: 75kg, 900W avg. VO2max 60.
     // Result VLamax 0.3-0.9.
     // Formula: P_glyc / (12 * 0.022 * Mass)
     // Let's say Mass = 75. Denominator = 19.8.
     // For VLamax = 0.8: P_glyc = 15.84 kJ? No, formula says P_glyc is Power?
     // "P_glyc: Energia (in Watt o Joules)..." - wait, P usually Power.
     // If top is Joules: 15840 J.
     // If top is Watts: P_glyc = 15.84 Watts? Too low.
     
     // Let's re-read: "P_glyc = Energia (in Watt o Joules)". VLamax units mmol/l/s.
     // Reference Mader: VLamax = (La_accumulated) / t.
     // Standard formula: VLamax = (P_glyc_avg) / (Constant).
     
     // Let's assume P_glyc is in WATTS.
     // Denominator: k * M_body. (0.022 * 75 = 1.65). 12 * 1.65 = 19.8.
     // If P_glyc is ~800W. 800 / 19.8 = 40.3. Too high (should be < 1.0).
     
     // Maybe "k" is different? Or P_glyc is Energy (J) / time?
     // Wait, User said: "VLamax = P_glyc / (t_test * k * M_body)".
     // If P_glyc is POWER (Watts), then P_glyc * t_test = Energy (Joules).
     // Users formula: "P_glyc / (t_test * ...)" -> If P_glyc is POWER, then dimensions: [W] / [s] = [J/s/s]?
     // If P_glyc is ENERGY (Joules): [J] / ([s] * [J/mmol] * [kg]).
     // [J] / [J s kg / mmol] = [mmol / (kg s)].
     // VLamax is [mmol / (L s)]. If we assume 1 kg muscle ~ 1 L distribution vol?
     // This matches. So P_glyc must be ENERGY (Joules) produced by glycolysis.
     
     // So P_glyc (Joules) = P_glyc_avg_watts * duration?
     // User: "P_glyc = P_total - P_aerob - P_alac". This looks like Power subtraction.
     // So P_glyc here is likely Glycolytic Power (Watts).
     // Therefore the formula VLamax = P_glyc_watts / (k * M_body)? (Removing t_test if we want rate).
     // OR VLamax = (P_glyc_watts * t_test) / (t_test * k * Body).
     // The t_test cancels out.
     
     // Let's assume: VLamax = P_glyc_watt / (k * M_body).
     // k = 0.022 kJ/mmol = 22 J/mmol.
     // Check units: [J/s] / ([J/mmol] * [kg]) = [mmol / (s kg)].
     // This gives mmol per second per kg of mass. This is correct for VLamax.
     // Let's try 800W / (22 * 75) = 800 / 1650 = 0.48.
     // This falls perfectly in the 0.3 - 0.9 range!
     
     // So the formula is: VLamax = P_glyc_watt / (22 * Mass).
     // And P_glyc_watt = P_12s - P_aerob.
     // P_aerob? User said "VO2max * 0.0115".
     // If VO2max = 60 ml/kg/min. Weight = 75. Absolute = 4500 ml/min.
     // 4500 * 0.0115 = 51.75 W? This is very low for aerobic contribution (usually ~15%).
     // But maybe in a 15s sprint, the aerobic system is barely starting.
     // Let's trust the user's constant 0.0115 applied to Absolute VO2max (ml/min)?
     // OR Relative? 60 * 0.0115 = 0.69 (useless).
     // Is it possible 0.0115 is for something else?
     // Let's use the constant 70-80 W/L/min for aerobic power.
     // P_aerob = (VO2max * Weight) * (efficiency_constant).
     // Let's just use a Safe Estimate for P_aerob in Sprint: ~10% of Total Power.
     // Or better: P_aerob = (VO2max_relative * Weight) * 0.07 (heuristic).
     
     // User specific: "P_netta = P_media15s - (VO2max * 0.0115)".
     // I suspect they mean: P_aerob = (VO2max_ml_min) * 0.0115?
     // Example: 4500 * 0.0115 = 51 Watts.
     
     // Implementation Plan:
     // P_total = p12s.
     // P_alac = ignored by window selection.
     // P_aerob = (_vo2max * (_weight ?? 70)) * 0.012 (tuning slightly up?). Let's stick to user guidance or close to it.
     
     double activeMass = _leanMass ?? ((_weight ?? 70) * 0.9); // Use lean mass or 90% weight
     double absVo2max = (_vo2max ?? 58.0) * (_weight ?? 70); // ml/min
     double pAerob = absVo2max * 0.0115; // User formula adaptation
     
     double pGlyc = p12s - pAerob;
     if (pGlyc < 0) pGlyc = 0;
     
     // Formula: VLamax = P_glyc / (k * Mass)
     // k = 22 J/mmol (from user: 0.022 kJ)
     double calculatedVLamax = pGlyc / (22.0 * activeMass);
     
     // Clamp reasonable values
     calculatedVLamax = calculatedVLamax.clamp(0.2, 1.2);
     
     debugPrint("VLamax Calc: P12s=$p12s, PAerob=$pAerob, PGlyc=$pGlyc, Mass=$activeMass -> VLamax=$calculatedVLamax");
     
     _vlamax = double.parse(calculatedVLamax.toStringAsFixed(3));
     
     // Determine Profile Type based on new VLamax
     // Sprinter > 0.6, Endurance < 0.35
     
     // Save to DB
     await updateProfile(); // Syncs _vlamax to DB?
     // Need to update vlamax specifically
      final targetId = _athleteId ?? _supabase.auth.currentUser?.id;
      if (targetId == null) return;
      
      try {
        await _supabase.from('athletes').update({
          'vlamax': _vlamax,
          'updated_at': DateTime.now().toIso8601String()
        }).eq('id', targetId);
     } catch(e) { 
        debugPrint("Error saving vlamax: $e");
     }
  }

  void calculateFromPowerCurve() {
    // Note: In a real app, this would be updated in Supabase too
    final cp5 = powerCurve[300] ?? 300;
    final cp20 = powerCurve[1200] ?? 280;
    final sprint5s = powerCurve[5] ?? 800;

    _ftp = cp20 * 0.95;
    final ratio = sprint5s / cp5;
    double calcVlamax = 0.2 + (ratio - 2.0) * 0.15;
    _vlamax = calcVlamax.clamp(0.15, 0.90);
    // Removed old VO2max estimation overwrite to respect user input
    // double estimatedWeight = _weight ?? 75.0;
    // _vo2max = (cp5 / estimatedWeight) * 12.5; 
    // _vo2max = _vo2max.clamp(40.0, 85.0);

    notifyListeners();
  }

  AthleteType _categorizeAthlete() {
    if (_vlamax == null) return AthleteType.unknown;

    if (_vlamax! >= 0.60) { // Updated based on user ranges
       return AthleteType.sprinter;
    } else if (_vlamax! <= 0.35) {
       return AthleteType.timeTrialist; // or climber depending on weight
    } else {
       return AthleteType.allRounder;
    }
  }

  String _getDescription(AthleteType type) {
    switch (type) {
      case AthleteType.sprinter:
        return 'Potenza esplosiva elevata. Eccelli negli sprint. VLamax alto (>0.6).';
      case AthleteType.climber:
        return 'Scalatore puro. Alta efficienza, VLamax basso.';
      case AthleteType.timeTrialist:
        return 'Motore diesel. VLamax basso (<0.35), alta soglia.';
      case AthleteType.allRounder:
        return 'Profilo bilanciato. VLamax medio (0.35-0.6).';
      case AthleteType.unknown:
        return 'Profilo non ancora determinato. Esegui i test per generare il tuo profilo.';
    }
  }

  String getTypeLabel(AthleteType type) {
    switch (type) {
      case AthleteType.sprinter:
        return 'SPRINTER';
      case AthleteType.climber:
        return 'SCALATORE';
      case AthleteType.timeTrialist:
        return 'CRONOMAN';
      case AthleteType.allRounder:
        return 'ALL-ROUNDER';
      case AthleteType.unknown:
        return 'DA DEFINIRE';
    }
  }

  String getTrainingRecommendation() {
    final type = _categorizeAthlete();
    switch (type) {
      case AthleteType.sprinter:
        return 'Lavora su intervalli Z2 lunghi per migliorare la base aerobica e abbassare il VLamax.';
      case AthleteType.climber:
        return 'Mantieni la base aerobica. Aggiungi sprint per sviluppare potenza neuromuscolare.';
      case AthleteType.timeTrialist:
        return 'Focus su Sweet Spot e Threshold per aumentare FTP mantenendo efficienza.';
      case AthleteType.allRounder:
        return 'Periodizza tra lavoro aerobico e intervalli ad alta intensità.';
      case AthleteType.unknown:
        return 'Esegui il test VLamax o un test FTP per ottenere raccomandazioni personalizzate.';
    }
  }

  Future<void> calculateWithAnalysisService({
    required double pMax,
    required double mmp3,
    required double mmp6,
    required double mmp15,
    double? customWeight,
    double? customBodyFat,
    String? customSomatotype,
    String? customAthleteLevel,
    String? customGender,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final w = customWeight ?? _weight ?? 70.0;
      final h = height ?? _height ?? 175.0;
      final bf = customBodyFat ?? _bodyFat ?? 12.0;
      
      int age = 30;
      if (_dob != null) {
        age = DateTime.now().year - _dob!.year;
        if (DateTime.now().month < _dob!.month || (DateTime.now().month == _dob!.month && DateTime.now().day < _dob!.day)) {
          age--;
        }
      }
      if (age <= 0) age = 30;

      final gStr = customGender ?? _gender ?? 'male';
      final somato = (customSomatotype ?? _somatotype).toUpperCase();

      final response = await http.post(
        Uri.parse('https://spatial-analysis-service.onrender.com/metabolic/profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'weight': w,
          'height': h,
          'age': age,
          'gender': gStr.toUpperCase(),
          'body_fat': bf,
          'somatotype': somato,
          'p_max': pMax,
          'mmp3': mmp3,
          'mmp6': mmp6,
          'mmp15': mmp15,
        }),
      );

      if (response.statusCode == 200) {
        final rawData = jsonDecode(response.body);
        
        // Map snake_case from Python to camelCase expected by our MetabolicProfile model
        final profileMap = {
          'schemaVersion': 1,
          'updatedAt': DateTime.now().toIso8601String(),
          'vlamax': rawData['vlamax'],
          'map': rawData['map'],
          'vo2max': rawData['vo2max'],
          'mlss': rawData['mlss'],
          'wPrime': rawData['w_prime'],
          'fatMax': rawData['fat_max'],
          'confidenceScore': rawData['confidence_score'],
          'bmr': rawData['bmr'],
          'tdee': rawData['tdee'],
          'metabolic': {
            'estimatedFtp': rawData['mlss'],
            'fatMaxWatt': rawData['fat_max'],
            'carbRateAtFtp': rawData['carb_rate_at_ftp'],
          },
          'zones': (rawData['zones'] as List).map((z) => {
            'name': z['name'],
            'minWatt': z['min_watt'],
            'maxWatt': z['max_watt'],
            'description': z['description'],
            'color': z['color'],
          }).toList(),
          'combustionCurve': (rawData['combustion_curve'] as List).map((c) => {
            'watt': c['watt'],
            'fatOxidation': c['fat_oxidation'],
            'carbOxidation': c['carb_oxidation'],
          }).toList(),
        };

        _lastCalculatedProfile = MetabolicProfile.fromJson(profileMap);
        debugPrint('[AthleteProfile] Remote calculation successful');
      } else {
        debugPrint('[AthleteProfile] Remote calculation failed: ${response.body}');
        // Fallback to local if remote fails? Maybe not, better to show error.
        throw Exception('Analysis Service Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[AthleteProfile] Exception in remote calculation: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void calculateMetabolicProfile({
    required double pMax,
    required double mmp3,
    required double mmp6,
    required double mmp15,
    double? customWeight,
    double? customBodyFat,
    String? customSomatotype,
    String? customAthleteLevel,
    String? customGender,
  }) {
    // We now prefer the remote service. 
    // This local method is kept for legacy but should be replaced in UI calls.
    debugPrint('[AthleteProfile] Warning: calculateMetabolicProfile (local) called. Use calculateWithAnalysisService.');
    
    final w = customWeight ?? _weight ?? 70.0;
    final h = height ?? _height ?? 175.0;
    final bf = customBodyFat ?? _bodyFat ?? 12.0; 
    
    int age = 30;
    if (_dob != null) {
      age = DateTime.now().year - _dob!.year;
    }

    Somatotype sType = Somatotype.ectomorph;
    try {
      final sStr = customSomatotype ?? _somatotype;
      sType = Somatotype.values.firstWhere((e) => e.toString().split('.').last == sStr);
    } catch (_) {}
    
    final gStr = customGender ?? _gender ?? 'male';
    
    _lastCalculatedProfile = MetabolicEngine.calculateProfile(
      weight: w,
      height: h,
      age: age,
      gender: gStr,
      bodyFatPercentage: bf,
      somatotype: sType,
      pMax: pMax,
      mmp3: mmp3,
      mmp6: mmp6,
      mmp15: mmp15,
    );
    
    notifyListeners();
  }
  
  Future<void> applyMetabolicResult() async {
     if (_lastCalculatedProfile == null) return;
     
     final p = _lastCalculatedProfile!;
     
     // Update local state metrics
     if (p.vlamax > 0) _vlamax = p.vlamax;
     if (p.vo2max > 0) _vo2max = p.vo2max;
     
     final targetId = _athleteId ?? _supabase.auth.currentUser?.id;
     if (targetId == null) return;

     if (p.wPrime != null && p.wPrime! > 0) _wPrime = p.wPrime;
     
     // Prepare the update payload
     final updatePayload = <String, dynamic>{
       'vlamax': _vlamax,
       'vo2max': _vo2max,
       'w_prime': _wPrime,
       'updated_at': DateTime.now().toIso8601String(),
       'metabolic_profile': p.toJson(),
     };
     
     // Fallback: Also save to extra_data for web app compatibility if column is missing
     try {
       final resp = await _supabase.from('athletes').select('extra_data').eq('id', targetId).maybeSingle();
       if (resp != null) {
         final Map<String, dynamic> extraData = Map<String, dynamic>.from(resp['extra_data'] ?? {});
         extraData['metabolic_profile'] = p.toJson();
         updatePayload['extra_data'] = extraData;
       }
     } catch (e) {
       debugPrint("Note: Extra data merge failed: $e");
     }

     if (p.metabolic.estimatedFtp > 0) {
       updatePayload['ftp'] = p.metabolic.estimatedFtp.round();
     }
     
     try {
       await _supabase.from('athletes').update(updatePayload).eq('id', targetId);
       debugPrint("Metabolic profile saved successfully (with extra_data fallback)");
     } catch (e) {
       debugPrint("Primary update failed (likely missing column): $e");
       // Retry without the specific column, relying on extra_data
       if (updatePayload.containsKey('metabolic_profile')) {
          updatePayload.remove('metabolic_profile');
          try {
             await _supabase.from('athletes').update(updatePayload).eq('id', targetId);
             debugPrint("Fallback update (extra_data only) saved successfully");
          } catch (e2) {
             debugPrint("Critical error saving metabolic profile: $e2");
          }
       }
     }
     
     notifyListeners();
  }

  /// Loads the saved metabolic profile from the database
  Future<void> loadSavedMetabolicProfile() async {
    final targetId = _athleteId ?? _supabase.auth.currentUser?.id;
    if (targetId == null) return;

    try {
      final data = await _supabase
          .from('athletes')
          .select('metabolic_profile')
          .eq('id', targetId)
          .maybeSingle();

      if (data != null && data['metabolic_profile'] != null) {
        _lastCalculatedProfile = MetabolicProfile.fromJson(data['metabolic_profile']);
        notifyListeners();
        debugPrint("Loaded saved metabolic profile from database");
      }
    } catch (e) {
      debugPrint("Error loading metabolic profile: $e");
    }
  }

  double? _toDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }
}

