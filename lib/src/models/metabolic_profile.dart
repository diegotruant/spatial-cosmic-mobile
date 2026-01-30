import 'dart:convert';

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

  factory MetabolicProfile.fromJson(Map<String, dynamic> json) => MetabolicProfile(
    vlamax: (json['vlamax'] as num).toDouble(),
    map: (json['map'] as num).toDouble(),
    vo2max: (json['vo2max'] as num).toDouble(),
    mlss: json['mlss'] != null ? (json['mlss'] as num).toDouble() : null,
    fatMax: json['fatMax'] != null ? (json['fatMax'] as num).toDouble() : null,
    wPrime: json['wPrime'] != null ? (json['wPrime'] as num).toDouble() : null,
    confidenceScore: json['confidenceScore'] != null ? (json['confidenceScore'] as num).toDouble() : null,
    inputSources: json['inputSources'] != null ? Map<String, dynamic>.from(json['inputSources']) : null,
    bmr: json['bmr'] != null ? (json['bmr'] as num).toDouble() : null,
    tdee: json['tdee'] != null ? (json['tdee'] as num).toDouble() : null,
    metabolic: MetabolicStats.fromJson(json['metabolic']),
    zones: (json['zones'] as List).map((z) => MetabolicZone.fromJson(z)).toList(),
    combustionCurve: (json['combustionCurve'] as List).map((c) => CombustionData.fromJson(c)).toList(),
  );

  String toJsonString() => jsonEncode(toJson());
  static MetabolicProfile fromJsonString(String jsonStr) => MetabolicProfile.fromJson(jsonDecode(jsonStr));
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
    estimatedFtp: (json['estimatedFtp'] as num).toDouble(),
    fatMaxWatt: (json['fatMaxWatt'] as num).toDouble(),
    carbRateAtFtp: (json['carbRateAtFtp'] as num).toDouble(),
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
    watt: (json['watt'] as num).toDouble(),
    fatOxidation: (json['fatOxidation'] as num).toDouble(),
    carbOxidation: (json['carbOxidation'] as num).toDouble(),
  );
}
