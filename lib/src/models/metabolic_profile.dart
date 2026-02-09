import 'dart:convert';
import 'package:flutter/foundation.dart';

enum Somatotype {
  ectomorph, // Longilineo
  mesomorph, // Atletico
  endomorph, // Robusto
}

enum AthleteLevel {
  amateur,
  pro,
}

enum Gender {
  male,
  female,
}

class MetabolicProfile {
  final int? schemaVersion;
  final String? updatedAt;
  final double vlamax;
  final double map; // Maximum Aerobic Power in Watts
  final double vo2max; // Relative VO2max (ml/min/kg)
  final double? mlss; // Maximal Lactate Steady State (Power)
  final double? fatMax; // Picco Lipidico (Watt)
  final double? wPrime; // Anaerobic Work Capacity (J)
  final double? confidenceScore; // 0.0 to 1.0 reliability
  final Map<String, dynamic>? inputSources; // Metadata about inputs used
  final double? bmr; // Basal Metabolic Rate
  final double? tdee; // Total Daily Energy Expenditure
  final String? phenotypeLabel; // Fenotipo dal PDC (es. "All-Rounder")
  final double? hrMax; // Frequenza cardiaca massima
  final AdvancedParams? advancedParams; // Parametri avanzati dal PDC
  final MetabolicStats metabolic;
  final List<MetabolicZone> zones;
  final List<CombustionData> combustionCurve;
  final List<PDCPoint> pdcCurve;

  MetabolicProfile({
    this.schemaVersion,
    this.updatedAt,
    required this.vlamax,
    required this.map,
    required this.vo2max,
   this.mlss,
    this.fatMax,
    this.wPrime,
    this.confidenceScore,
    this.inputSources,
    this.bmr,
    this.tdee,
    this.phenotypeLabel,
    this.hrMax,
    this.advancedParams,
    required this.metabolic,
    required this.zones,
    required this.combustionCurve,
    this.pdcCurve = const [],
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'updatedAt': updatedAt,
    'vlamax': vlamax,
    'map': map,
    'vo2max': vo2max,
    'mlss': mlss,
    'fatMax': fatMax,
    'wPrime': wPrime,
    'confidenceScore': confidenceScore,
    'inputSources': inputSources,
    'bmr': bmr,
    'tdee': tdee,
    'phenotypeLabel': phenotypeLabel,
    'hrMax': hrMax,
    'advancedParams': advancedParams?.toJson(),
    'metabolic': metabolic.toJson(),
    'zones': zones.map((z) => z.toJson()).toList(),
    'combustionCurve': combustionCurve.map((c) => c.toJson()).toList(),
    'pdcCurve': pdcCurve.map((p) => p.toJson()).toList(),
  };

  factory MetabolicProfile.fromJson(Map<String, dynamic> json) {
    try {
      final version = json['schemaVersion'] is num ? (json['schemaVersion'] as num).toInt() : null;
      final updatedAt = json['updatedAt'] as String?;
      return MetabolicProfile(
        schemaVersion: version,
        updatedAt: updatedAt,
        vlamax: _safeDouble(json['vlamax']) ?? 0.0,
        map: _safeDouble(json['map'] ?? json['ftp']) ?? 0.0,
        vo2max: _safeDouble(json['vo2max']) ?? 0.0,
        mlss: _safeDouble(json['mlss']),
        fatMax: _safeDouble(json['fatMax']),
        wPrime: _safeDouble(json['wPrime']),
        confidenceScore: _safeDouble(json['confidenceScore']),
        inputSources: json['inputSources'] != null ? Map<String, dynamic>.from(json['inputSources']) : null,
        bmr: _safeDouble(json['bmr']),
        tdee: _safeDouble(json['tdee']),
        phenotypeLabel: json['phenotype_label'] as String? ?? json['phenotypeLabel'] as String?,
        hrMax: _safeDouble(json['hrMax'] ?? json['hr_max']),
        advancedParams: json['advanced_params'] != null 
            ? AdvancedParams.fromJson(Map<String, dynamic>.from(json['advanced_params']))
            : null,
        metabolic: json['metabolic'] != null 
            ? MetabolicStats.fromJson(Map<String, dynamic>.from(json['metabolic']))
            : MetabolicStats(estimatedFtp: 0, fatMaxWatt: 0, carbRateAtFtp: 0),
        zones: (json['zones'] as List?)?.map((z) => MetabolicZone.fromJson(Map<String, dynamic>.from(z))).toList() ?? [],
        combustionCurve: (json['combustionCurve'] as List?)?.map((c) => CombustionData.fromJson(Map<String, dynamic>.from(c))).toList() ?? [],
        pdcCurve: (json['pdc_curve'] as List?)?.map((p) => PDCPoint.fromJson(Map<String, dynamic>.from(p))).toList() ?? [],
      );
    } catch (e) {
      debugPrint("Severe error parsing MetabolicProfile: $e");
      // Return a skeleton profile instead of crashing
      return MetabolicProfile(
        schemaVersion: null,
        updatedAt: null,
        vlamax: 0, map: 0, vo2max: 0,
        metabolic: MetabolicStats(estimatedFtp: 0, fatMaxWatt: 0, carbRateAtFtp: 0),
        zones: [], combustionCurve: [], pdcCurve: []
      );
    }
  }

  String toJsonString() => jsonEncode(toJson());
  static MetabolicProfile fromJsonString(String jsonStr) => MetabolicProfile.fromJson(jsonDecode(jsonStr));
}

class AdvancedParams {
  final double ftpEstimated; // FTP dal PDC (advanced_params.ftp_estimated)
  final double criticalPower;
  final double vo2maxEstimated;
  final double? sprintPower; // W/kg
  final double? anaerobicCapacity; // kJ
  final double? pMax;
  final double? aerobicPower; // APR
  final double? tteVo2max; // Time to Exhaustion @ VO2max (minutes)

  AdvancedParams({
    required this.ftpEstimated,
    required this.criticalPower,
    required this.vo2maxEstimated,
    this.sprintPower,
    this.anaerobicCapacity,
    this.pMax,
    this.aerobicPower,
    this.tteVo2max,
  });

  Map<String, dynamic> toJson() => {
    'ftp_estimated': ftpEstimated,
    'critical_power': criticalPower,
    'vo2max_estimated': vo2maxEstimated,
    'sprint_power': sprintPower,
    'anaerobic_capacity': anaerobicCapacity,
    'p_max': pMax,
    'aerobic_power': aerobicPower,
    'tte_vo2max': tteVo2max,
  };

  factory AdvancedParams.fromJson(Map<String, dynamic> json) {
    return AdvancedParams(
      ftpEstimated: _safeDouble(json['ftp_estimated']) ?? 0.0,
      criticalPower: _safeDouble(json['critical_power']) ?? 0.0,
      vo2maxEstimated: _safeDouble(json['vo2max_estimated']) ?? 0.0,
      sprintPower: _safeDouble(json['sprint_power']),
      anaerobicCapacity: _safeDouble(json['anaerobic_capacity']),
      pMax: _safeDouble(json['p_max']),
      aerobicPower: _safeDouble(json['aerobic_power']),
      tteVo2max: _safeDouble(json['tte_vo2max']),
    );
  }
}

class MetabolicStats {
  final double estimatedFtp;
  final double fatMaxWatt;
  final double carbRateAtFtp; // g/hour or relative unit

  MetabolicStats({
    required this.estimatedFtp,
    required this.fatMaxWatt,
    required this.carbRateAtFtp,
  });

  Map<String, dynamic> toJson() => {
    'estimatedFtp': estimatedFtp,
    'fatMaxWatt': fatMaxWatt,
    'carbRateAtFtp': carbRateAtFtp,
  };

  factory MetabolicStats.fromJson(Map<String, dynamic> json) => MetabolicStats(
    estimatedFtp: _safeDouble(json['estimatedFtp'] ?? json['ftp']) ?? 0.0,
    fatMaxWatt: _safeDouble(json['fatMaxWatt']) ?? 0.0,
    carbRateAtFtp: _safeDouble(json['carbRateAtFtp']) ?? 0.0,
  );
}

class MetabolicZone {
  final String name;
  final String range;
  final String target;
  final String fuel;
  final String color; // Hex string or Tailwind class name mapping
  final double? minWatt;
  final double? maxWatt;

  MetabolicZone({
    required this.name,
    required this.range,
    required this.target,
    required this.fuel,
    required this.color,
    this.minWatt,
    this.maxWatt,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'range': range,
    'target': target,
    'fuel': fuel,
    'color': color,
    'minWatt': minWatt,
    'maxWatt': maxWatt,
  };

  factory MetabolicZone.fromJson(Map<String, dynamic> json) => MetabolicZone(
    name: json['name'] ?? 'Unknown',
    range: json['range'] ?? (json['minWatt'] != null ? '${json['minWatt']} - ${json['maxWatt']}W' : ''),
    target: json['target'] ?? json['description'] ?? '',
    fuel: json['fuel'] ?? '',
    color: json['color'] ?? 'text-slate-400',
    minWatt: _safeDouble(json['minWatt']),
    maxWatt: _safeDouble(json['maxWatt']),
  );
}

class CombustionData {
  final double watt;
  final double fatOxidation; // 0-100 (relative or g/h)
  final double carbOxidation; // 0-100 (relative or g/h)

  CombustionData({
    required this.watt,
    required this.fatOxidation,
    required this.carbOxidation,
  });

  Map<String, dynamic> toJson() => {
    'watt': watt,
    'fatOxidation': fatOxidation,
    'carbOxidation': carbOxidation,
  };

  factory CombustionData.fromJson(Map<String, dynamic> json) => CombustionData(
    watt: _safeDouble(json['watt']) ?? 0.0,
    fatOxidation: _safeDouble(json['fatOxidation']) ?? 0.0,
    carbOxidation: _safeDouble(json['carbOxidation']) ?? 0.0,
  );
}

class PDCPoint {
  final int durationSeconds;
  final double watt;

  PDCPoint({required this.durationSeconds, required this.watt});

  Map<String, dynamic> toJson() => {
    'duration_seconds': durationSeconds,
    'watt': watt,
  };

  factory PDCPoint.fromJson(Map<String, dynamic> json) => PDCPoint(
    durationSeconds: json['duration_seconds'] ?? 0,
    watt: _safeDouble(json['watt']) ?? 0.0,
  );
}

double? _safeDouble(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val);
  return null;
}
