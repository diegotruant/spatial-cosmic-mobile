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
  final MetabolicStats metabolic;
  final List<MetabolicZone> zones;
  final List<CombustionData> combustionCurve;

  MetabolicProfile({
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
    required this.metabolic,
    required this.zones,
    required this.combustionCurve,
  });

  Map<String, dynamic> toJson() => {
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
    'metabolic': metabolic.toJson(),
    'zones': zones.map((z) => z.toJson()).toList(),
    'combustionCurve': combustionCurve.map((c) => c.toJson()).toList(),
  };

  factory MetabolicProfile.fromJson(Map<String, dynamic> json) {
    try {
      return MetabolicProfile(
        vlamax: _toDouble(json['vlamax']) ?? 0.0,
        map: _toDouble(json['map'] ?? json['ftp']) ?? 0.0,
        vo2max: _toDouble(json['vo2max']) ?? 0.0,
        mlss: _toDouble(json['mlss']),
        fatMax: _toDouble(json['fatMax']),
        wPrime: _toDouble(json['wPrime']),
        confidenceScore: _toDouble(json['confidenceScore']),
        inputSources: json['inputSources'] != null ? Map<String, dynamic>.from(json['inputSources']) : null,
        bmr: _toDouble(json['bmr']),
        tdee: _toDouble(json['tdee']),
        metabolic: json['metabolic'] != null 
            ? MetabolicStats.fromJson(Map<String, dynamic>.from(json['metabolic']))
            : MetabolicStats(estimatedFtp: 0, fatMaxWatt: 0, carbRateAtFtp: 0),
        zones: (json['zones'] as List?)?.map((z) => MetabolicZone.fromJson(Map<String, dynamic>.from(z))).toList() ?? [],
        combustionCurve: (json['combustionCurve'] as List?)?.map((c) => CombustionData.fromJson(Map<String, dynamic>.from(c))).toList() ?? [],
      );
    } catch (e) {
      debugPrint("Severe error parsing MetabolicProfile: $e");
      // Return a skeleton profile instead of crashing
      return MetabolicProfile(
        vlamax: 0, map: 0, vo2max: 0,
        metabolic: MetabolicStats(estimatedFtp: 0, fatMaxWatt: 0, carbRateAtFtp: 0),
        zones: [], combustionCurve: []
      );
    }
  }

  String toJsonString() => jsonEncode(toJson());
  static MetabolicProfile fromJsonString(String jsonStr) => MetabolicProfile.fromJson(jsonDecode(jsonStr));

  static double? _toDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
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
    estimatedFtp: (json['estimatedFtp'] ?? json['ftp'] ?? 0.0 as num).toDouble(),
    fatMaxWatt: (json['fatMaxWatt'] ?? 0.0 as num).toDouble(),
    carbRateAtFtp: (json['carbRateAtFtp'] ?? 0.0 as num).toDouble(),
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
    minWatt: json['minWatt'] != null ? (json['minWatt'] as num).toDouble() : null,
    maxWatt: json['maxWatt'] != null ? (json['maxWatt'] as num).toDouble() : null,
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
    watt: (json['watt'] ?? 0.0 as num).toDouble(),
    fatOxidation: (json['fatOxidation'] ?? 0.0 as num).toDouble(),
    carbOxidation: (json['carbOxidation'] ?? 0.0 as num).toDouble(),
  );
}
