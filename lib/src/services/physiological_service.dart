import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum ReadinessStatus { green, yellow, red }

class PhysiologicalData {
  final DateTime timestamp;
  final double rmssd;
  final int averageHR;
  final int? ouraScore;
  final int rhr;
  final String? trafficLight;
  final double? deviation;
  final String? recommendation;

  PhysiologicalData({
    required this.timestamp,
    required this.rmssd,
    required this.averageHR,
    this.ouraScore,
    this.rhr = 0,
    this.trafficLight,
    this.deviation,
    this.recommendation,
  });
}

class HRVAnalysis {
  final ReadinessStatus status;
  final double deviation;
  final String recommendation;

  HRVAnalysis({
    required this.status,
    required this.deviation,
    required this.recommendation,
  });
}

class PhysiologicalService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final List<PhysiologicalData> _history = [];
  
  // Dependencies
  String? _athleteId;

  double _lastSevenDayAvg = 45.0;
  bool _isLoading = false;

  List<PhysiologicalData> get history => List.unmodifiable(_history);
  bool get isLoading => _isLoading;

  PhysiologicalService();

  void updateAthleteId(String? id) {
    if (id != _athleteId) {
      _athleteId = id;
      if (_athleteId != null) {
        fetchHistory();
      }
    }
  }

  Future<void> fetchHistory() async {
    final targetId = _athleteId ?? _supabase.auth.currentUser?.id;
    if (targetId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final data = await _supabase
          .from('diary_entries')
          .select()
          .eq('athlete_id', targetId)
          .order('date', ascending: false);
      // ... rest of logic
      
      _history.clear();
      for (final entry in data) {
         // ... existing parsing ...
        _history.add(PhysiologicalData(
          timestamp: DateTime.parse(entry['date']),
          rmssd: (entry['hrv'] as num?)?.toDouble() ?? 0.0,
          averageHR: 0,
          rhr: (entry['rhr'] as num?)?.toInt() ?? 0,
          ouraScore: (entry['readiness'] as num?)?.toInt(),
          trafficLight: entry['traffic_light'],
          deviation: (entry['deviation'] as num?)?.toDouble(),
          recommendation: entry['recommendation'],
        ));
      }

      if (_history.isNotEmpty) {
        final recent = _history.take(7).where((e) => e.rmssd > 0).map((e) => e.rmssd);
        if (recent.isNotEmpty) {
          _lastSevenDayAvg = recent.reduce((a, b) => a + b) / recent.length;
        }
      }
    } catch (e) {
      debugPrint('Error fetching physiological history: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Calculates rMSSD from a list of RR intervals (in milliseconds)
  double calculateRMSSD(List<int> rrIntervals) {
    if (rrIntervals.length < 2) return 0.0;
    
    double sumSquaredDiff = 0.0;
    for (int i = 0; i < rrIntervals.length - 1; i++) {
      double diff = (rrIntervals[i+1] - rrIntervals[i]).toDouble();
      sumSquaredDiff += diff * diff;
    }
    
    return sqrt(sumSquaredDiff / (rrIntervals.length - 1));
  }

  ReadinessStatus getStatus(double currentRMSSD, {int? ouraScore}) {
    return analyzeHRV(currentRMSSD, ouraScore: ouraScore).status;
  }

  HRVAnalysis analyzeHRV(double currentRMSSD, {int? ouraScore}) {
    // 1. If no score passed, check if we already have an Oura score for today in history
    if (ouraScore == null) {
      final now = DateTime.now();
      try {
        final todayData = _history.firstWhere(
          (e) => e.timestamp.year == now.year && 
                 e.timestamp.month == now.month && 
                 e.timestamp.day == now.day && 
                 e.ouraScore != null
        );
        ouraScore = todayData.ouraScore;
      } catch (_) {
        // No Oura data for today yet
      }
    }

    // 2. Prioritize Oura Critical Stress (Red/Yellow)
    if (ouraScore != null) {
      if (ouraScore < 60) {
        return HRVAnalysis(
          status: ReadinessStatus.red,
          deviation: 0, 
          recommendation: 'Readiness Oura Bassa ($ouraScore). Il tuo corpo è sotto stress critico (possibile febbre o sovrallenamento). Riposo assoluto consigliato.',
        );
      } else if (ouraScore < 70) { // Slightly adjusted threshold
        return HRVAnalysis(
          status: ReadinessStatus.yellow,
          deviation: 0,
          recommendation: 'Readiness Oura Moderata ($ouraScore). Procedi con cautela, riduci l\'intensità oggi.',
        );
      }
    }

    // 3. Baseline check
    if (_lastSevenDayAvg <= 0) {
      return HRVAnalysis(
        status: ReadinessStatus.green,
        deviation: 0,
        recommendation: 'Inizia a misurare per vedere il tuo stato.',
      );
    }

    // 4. Calculate Deviation
    final deviation = ((currentRMSSD - _lastSevenDayAvg) / _lastSevenDayAvg) * 100;
    
    // 5. Dynamic Thresholds
    // If Oura is good (>80) OR if we are in "Snapshot Mode" (no Oura, belt only),
    // we apply wider buffers for the morning measurement.
    bool hasOuraData = ouraScore != null;
    bool isOuraExcellent = hasOuraData && ouraScore >= 80;
    
    // For belt-only users (no Oura), we use the same lenient thresholds as Oura Excellent
    // because a manual measurement at wake-up is naturally more variable.
    bool useLenientThresholds = isOuraExcellent || !hasOuraData;

    double greenThreshold = useLenientThresholds ? -12.0 : -6.0;
    double yellowThreshold = useLenientThresholds ? -25.0 : -16.0;

    ReadinessStatus status;
    String recommendation;

    if (deviation >= greenThreshold) {
      status = ReadinessStatus.green;
      if (useLenientThresholds && deviation < -5) {
         recommendation = hasOuraData 
           ? 'Oura conferma ottimo recupero ($ouraScore). Il calo mattutino dell\'HRV è fisiologico. Allenamento confermato.'
           : 'Variazione mattutina nei parametri normali. Recupero parasimpatico ok. Allenamento confermato.';
      } else {
         recommendation = deviation > 5 
           ? 'Ottimo! HRV elevata. Finestra ottimale per allenamento intenso.'
           : 'Pronto per allenarsi. Sistema parasimpatico recuperato.';
      }
    } else if (deviation >= yellowThreshold) {
      status = ReadinessStatus.yellow;
      recommendation = isOuraExcellent 
        ? 'HRV mattutina bassa nonostante Oura Green ($ouraScore). Possibile stress acuto al risveglio. Allenamento moderato.'
        : 'HRV depressa (${deviation.toStringAsFixed(0)}%). Considera riduzione volume o intensità (90% del target).';
    } else {
      status = ReadinessStatus.red;
      recommendation = 'Sistema parasimpatico soppresso (${deviation.toStringAsFixed(0)}%). Recupero attivo o riposo completo consigliato.';
    }

    return HRVAnalysis(
      status: status,
      deviation: deviation,
      recommendation: recommendation,
    );
  }

  Future<void> addHRVMeasurement(double rmssd, int avgHR) async {
    final analysis = analyzeHRV(rmssd);
    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    
    final targetId = _athleteId ?? _supabase.auth.currentUser?.id;

    if (targetId != null) {
      try {
        debugPrint('Saving HRV to DB for $targetId: $dateStr, HRV: $rmssd, Status: ${analysis.status.name.toUpperCase()}');
        await _supabase.from('diary_entries').upsert({
          'id': '${targetId}_$dateStr',
          'athlete_id': targetId,
          'date': dateStr,
          'hrv': rmssd,
          'rhr': avgHR,
          'traffic_light': analysis.status.name.toUpperCase(),
          'deviation': analysis.deviation,
          'recommendation': analysis.recommendation,
          'updated_at': DateTime.now().toIso8601String(),
        });
        debugPrint('HRV Saved Successfully');
      } catch (e) {
        debugPrint('Error saving HRV measurement: $e');
      }
    } else {
        debugPrint('User/Athlete ID is null, cannot save HRV');
    }

    _history.insert(0, PhysiologicalData(
      timestamp: now,
      rmssd: rmssd,
      averageHR: avgHR,
      rhr: avgHR,
      trafficLight: analysis.status.name.toUpperCase(),
      deviation: analysis.deviation,
      recommendation: analysis.recommendation,
    ));

    // Stable Recursive Average (7-day weight)
    _lastSevenDayAvg = (_lastSevenDayAvg * 6 + rmssd) / 7;
    notifyListeners();
  }

  Future<String> updateFromOura(double rmssd, int score) async {
    final analysis = analyzeHRV(rmssd, ouraScore: score);
    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final targetId = _athleteId ?? _supabase.auth.currentUser?.id;

    String resultMsg = "Success";

    if (targetId != null) {
      try {
        debugPrint('Saving HRV for $targetId on $dateStr using RPC');

        // Use RPC to bypass potential RLS/Trigger issues ("text ->> unknown")
        await _supabase.rpc('upsert_diary_entry', params: {
          'p_id': '${targetId}_$dateStr',
          'p_athlete_id': targetId,
          'p_date': dateStr,
          'p_hrv': rmssd,
          'p_traffic_light': analysis.status.name.toUpperCase(),
        });

        resultMsg = "Success: Saved to Cloud";

      } catch (e) {
        debugPrint('Error saving Oura data: $e');
        if (e.toString().contains('42883') || e.toString().contains('text ->> unknown')) {
           resultMsg = "Saved Locally (Cloud Warning)";
           // Even with RPC? Should not get this now.
        } else {
           resultMsg = "Saved Locally (DB Error: $e)";
        }
      }
    } else {
        resultMsg = "Error: No Athlete ID found.";
    }
    
    // Local Update
    final todayEntryIndex = _history.indexWhere((e) => 
      e.timestamp.year == now.year && 
      e.timestamp.month == now.month && 
      e.timestamp.day == now.day
    );

    final newData = PhysiologicalData(
      timestamp: now,
      rmssd: rmssd,
      averageHR: 0,
      ouraScore: score,
      trafficLight: analysis.status.name.toUpperCase(),
      deviation: analysis.deviation,
      recommendation: analysis.recommendation,
    );

    if (todayEntryIndex != -1) {
      _history[todayEntryIndex] = newData;
    } else {
      _history.insert(0, newData);
    }

    _lastSevenDayAvg = (_lastSevenDayAvg * 6 + rmssd) / 7;
    notifyListeners();
    
    return resultMsg;
  }



  int calculateHRR(int hrEndWorkout, int hrOneMinAfter) {
    return hrEndWorkout - hrOneMinAfter;
  }
}
