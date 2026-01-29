import 'dart:math';
import '../models/metabolic_profile.dart'; // Using the existing Full Model

class AntigravityEngine {
  /// Modello Scientifico Generalizzato (Mader/Heck/Olbrecht)
  /// Strutturato come Motore Predittivo Predittivo (non clinico)
  static MetabolicProfile calculateProfile({
    required double weight,
    required double height, // in cm
    required int age,
    required String gender,
    required double bodyFatPercentage,
    required Somatotype somatotype,
    required double pMax,      // Sprint massimale (Watt)
    required double mmp3,      // Test 3 minuti (Watt)
    required double mmp6,      // Test 6 minuti (Watt)
    required double mmp15,     // Test 15 minuti (Watt)
  }) {
    // 1. BASE METABOLISM (BMR, TDEE)
    final bmr = _calculateBMR(weight, height, age, gender);
    final tdee = bmr * 1.55; // Multiplier standard per atleta (Moderately Active)

    // 2. PERFORMANCE MODEL (Masse e Potenze)
    final double ffm = weight * (1 - (bodyFatPercentage / 100)); 
    final double activeMuscleMass = ffm * 0.31; 

    // Critical Power (CP) Model
    const double t6 = 360.0;
    const double t15 = 900.0;
    final double work6 = mmp6 * t6;
    final double work15 = mmp15 * t15;
    final double cp = (work15 - work6) / (t15 - t6);
    final double wPrimeWork = work6 - (cp * t6);

    // thresholds
    double cpToMlssRatio = 0.88; 
    if (somatotype == Somatotype.ectomorph) cpToMlssRatio = 0.92;
    if (somatotype == Somatotype.endomorph) cpToMlssRatio = 0.85;
    final double mlss = cp * cpToMlssRatio;

    // 3. performance model estimators
    final vlaMax = _estimateVLaMax(pMax, activeMuscleMass, mlss, mmp3);
    final vo2max = _estimateVO2max(mmp3, wPrimeWork, weight);
    final fatMax = _estimateFatMax(mlss, vlaMax);

    // 4. SUBSTRATE CURVE GENERATOR
    final clampVlaMax = vlaMax.clamp(0.2, 1.2);
    final mapAerobic = mmp3 - (wPrimeWork / 180.0);
    final zones = _calculateZones(mlss, fatMax, mapAerobic);
    final combustionCurve = _calculateCombustionCurve(mapAerobic, fatMax, clampVlaMax);

    // 5. CONFIDENCE & VALIDATION LAYER
    final confidence = _calculateConfidence(pMax, mmp3, mmp6, mmp15);
    final inputMetadata = {
      'pMax': 'manual',
      'mmp3': 'manual',
      'mmp6': 'manual',
      'mmp15': 'manual',
      'protocol': 'Flow Test v1',
    };

    return MetabolicProfile(
      vlamax: clampVlaMax,
      map: mapAerobic,
      vo2max: vo2max,
      mlss: mlss,
      wPrime: wPrimeWork,
      fatMax: fatMax,
      confidenceScore: confidence,
      inputSources: inputMetadata,
      bmr: bmr,
      tdee: tdee,
      metabolic: MetabolicStats(
        estimatedFtp: mlss,
        fatMaxWatt: fatMax,
        carbRateAtFtp: 50 + (clampVlaMax * 45),
      ),
      zones: zones,
      combustionCurve: combustionCurve,
    );
  }

  // --- PRIVATE MODULES ---

  static double _calculateBMR(double w, double h, int age, String gender) {
    if (gender.toLowerCase() == 'female') {
      return 447.593 + (9.247 * w) + (3.098 * h) - (4.330 * age);
    }
    return 88.362 + (13.397 * w) + (4.799 * h) - (5.677 * age);
  }

  static double _estimateVLaMax(double pMax, double muscleMass, double mlss, double mmp3) {
    double vlaMax = (pMax / muscleMass) * 0.013;
    final double aerobicFraction = mlss / (mmp3 * 0.94);
    vlaMax += (0.4 * (1.1 - aerobicFraction));
    return vlaMax;
  }

  static double _estimateVO2max(double mmp3, double wPrime, double weight) {
    final double mapAerobic = mmp3 - (wPrime / 180.0); 
    const double efficiency = 0.225;
    return ((mapAerobic / efficiency) / 21.1) * 60 / weight;
  }

  static double _estimateFatMax(double mlss, double vlaMax) {
    return mlss * (0.8 - (vlaMax * 0.25));
  }

  static double _calculateConfidence(double pMax, double m3, double m6, double m15) {
    double score = 0.4; // Base score (predittivo)
    if (pMax > 0) score += 0.15;
    if (m3 > 0) score += 0.15;
    if (m15 > 0) score += 0.15;
    // Check consistency
    if (m3 > m6 && m6 > m15) score += 0.15;
    return score.clamp(0.1, 1.0);
  }

  static List<MetabolicZone> _calculateZones(double ftp, double fatMaxWatt, double map) {
    final z1Limit = (ftp * 0.55).round();
    final z2Limit = (fatMaxWatt + 15).round();
    final safeZ2 = max(z2Limit, z1Limit + 10);
    
    final z3Limit = (ftp * 0.88).round();
    final z4Limit = (ftp * 1.05).round();
    final z5Limit = map.round(); 

    return [
      MetabolicZone(
        name: 'Z1 - Recovery',
        range: '0 - ${z1Limit}W',
        minWatt: 0,
        maxWatt: z1Limit.toDouble(),
        target: 'Recupero',
        fuel: 'Grassi',
        color: 'text-slate-400',
      ),
      MetabolicZone(
        name: 'Z2 - Endurance',
        range: '${z1Limit + 1} - ${safeZ2}W',
        minWatt: (z1Limit + 1).toDouble(),
        maxWatt: safeZ2.toDouble(),
        target: 'Endurance',
        fuel: 'Grassi/Misto',
        color: 'text-emerald-500',
      ),
      MetabolicZone(
        name: 'Z3 - Tempo',
        range: '${safeZ2 + 1} - ${z3Limit}W',
        minWatt: (safeZ2 + 1).toDouble(),
        maxWatt: z3Limit.toDouble(),
        target: 'Tempo',
        fuel: 'Misto',
        color: 'text-blue-500',
      ),
      MetabolicZone(
        name: 'Z4 - Threshold',
        range: '${z3Limit + 1} - ${z4Limit}W',
        minWatt: (z3Limit + 1).toDouble(),
        maxWatt: z4Limit.toDouble(),
        target: 'Soglia',
        fuel: 'Carbo',
        color: 'text-orange-500',
      ),
      MetabolicZone(
        name: 'Z5 - VO2max',
        range: '${z4Limit + 1} - ${z5Limit}W',
        minWatt: (z4Limit + 1).toDouble(),
        maxWatt: z5Limit.toDouble(),
        target: 'VO2max',
        fuel: 'Carbo',
        color: 'text-red-500',
      ),
    ];
  }

  static List<CombustionData> _calculateCombustionCurve(double map, double fatMaxWatt, double vlamax) {
    final List<CombustionData> data = [];
    final double endWatt = map * 1.3;

    for (double w = 50; w <= endWatt; w += 10) {
      final double r = w / map;
      double fatOx = 100 * exp(-pow((w - fatMaxWatt) / (map * 0.4), 2)) - (r * 12);
      fatOx = max(0.0, fatOx);
      double carbOx = 100 / (1 + exp(-12 * (r - (0.98 - vlamax * 0.4))));
      carbOx = min(100.0, carbOx);

      data.add(CombustionData(
        watt: w,
        fatOxidation: double.parse(fatOx.toStringAsFixed(1)),
        carbOxidation: double.parse(carbOx.toStringAsFixed(1)),
      ));
    }
    return data;
  }
}
