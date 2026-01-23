import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AthleteType { sprinter, allRounder, timeTrialist, climber, unknown }

class AthleteProfile {
  final double? vlamax; // mmol/L/s
  final double? vo2max; // ml/kg/min
  final double? ftp; // Watts
  final AthleteType type;
  final String description;
  final double? weight;
  final double? height;
  final DateTime? dob;
  final double? leanMass;

  AthleteProfile({
    this.vlamax,
    this.vo2max,
    this.ftp,
    required this.type,
    required this.description,
    this.weight,
    this.height,
    this.dob,
    this.leanMass,
  });
}

class AthleteProfileService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Power curve data (duration in seconds -> power in watts)
  final Map<int, double> powerCurve = {};

  double? _ftp;
  double? _vo2max;
  double? _vlamax;
  
  double? _weight;
  double? _height;
  DateTime? _dob;
  double? _leanMass;
  DateTime? _certExpiryDate;

  bool _isLoading = false;

  double? get ftp => _ftp;
  double? get vo2max => _vo2max;
  double? get vlamax => _vlamax;
  double? get weight => _weight;
  double? get height => _height;
  DateTime? get dob => _dob;
  double? get leanMass => _leanMass;
  DateTime? get certExpiryDate => _certExpiryDate;
  
  bool get isLoading => _isLoading;

  AthleteProfileService() {
    _loadFromSupabase();
  }

  Future<void> _loadFromSupabase() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final data = await _supabase
          .from('athletes')
          .select('ftp, vo2max, vlamax, weight, height, dob, lean_mass, cert_expiry_date')
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        if (data['ftp'] != null) _ftp = (data['ftp'] as num).toDouble();
        if (data['vo2max'] != null) _vo2max = (data['vo2max'] as num).toDouble();
        if (data['vlamax'] != null) _vlamax = (data['vlamax'] as num).toDouble();
        
        if (data['weight'] != null) _weight = (data['weight'] as num).toDouble();
        if (data['height'] != null) _height = (data['height'] as num).toDouble();
        if (data['lean_mass'] != null) _leanMass = (data['lean_mass'] as num).toDouble();
        if (data['dob'] != null) _dob = DateTime.tryParse(data['dob']);
        if (data['cert_expiry_date'] != null) _certExpiryDate = DateTime.tryParse(data['cert_expiry_date']);
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading profile from Supabase: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    double? weight,
    double? height,
    DateTime? dob,
    double? leanMass,
    DateTime? certExpiryDate,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    
    final updates = <String, dynamic>{};
    if (weight != null) updates['weight'] = weight;
    if (height != null) updates['height'] = height;
    if (dob != null) updates['dob'] = dob.toIso8601String();
    if (leanMass != null) updates['lean_mass'] = leanMass;
    if (certExpiryDate != null) updates['cert_expiry_date'] = certExpiryDate.toIso8601String();
    
    if (updates.isEmpty) return;

    try {
      await _supabase.from('athletes').update(updates).eq('id', user.id);
      
      // Update local state
      if (weight != null) _weight = weight;
      if (height != null) _height = height;
      if (dob != null) _dob = dob;
      if (leanMass != null) _leanMass = leanMass;
      if (certExpiryDate != null) _certExpiryDate = certExpiryDate;
      
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
     try {
       await _supabase.from('athletes').update({
         'vlamax': _vlamax,
         'updated_at': DateTime.now().toIso8601String()
       }).eq('id', _supabase.auth.currentUser!.id);
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
}
