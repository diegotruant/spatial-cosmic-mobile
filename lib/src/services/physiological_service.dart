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
  
  double _lastSevenDayAvg = 45.0;
  bool _isLoading = false;

  List<PhysiologicalData> get history => List.unmodifiable(_history);
  bool get isLoading => _isLoading;

  PhysiologicalService() {
    _init();
  }

  Future<void> _init() async {
    await fetchHistory();
  }

  Future<void> fetchHistory() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final data = await _supabase
          .from('diary_entries')
          .select()
          .eq('athlete_id', user.id)
          .order('date', ascending: false);

      _history.clear();
      for (final entry in data) {
        _history.add(PhysiologicalData(
          timestamp: DateTime.parse(entry['date']),
          rmssd: (entry['hrv'] as num?)?.toDouble() ?? 0.0,
          averageHR: 0, // Not explicitly stored in diary_entries yet
          rhr: (entry['rhr'] as num?)?.toInt() ?? 0,
          ouraScore: (entry['readiness'] as num?)?.toInt(), // Mapping readiness to ouraScore for now
          trafficLight: entry['traffic_light'],
          deviation: (entry['deviation'] as num?)?.toDouble(),
          recommendation: entry['recommendation'],
        ));
      }

      if (_history.isNotEmpty) {
        // Calculate rolling 7-day average from history
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
    if (ouraScore != null) {
      if (ouraScore < 60) {
        return HRVAnalysis(
          status: ReadinessStatus.red,
          deviation: 0, 
          recommendation: 'Readiness Oura Bassa ($ouraScore). Il tuo corpo è sotto stress (possibile febbre o sovrallenamento). Riposo assoluto consigliato.',
        );
      } else if (ouraScore < 75) {
        return HRVAnalysis(
          status: ReadinessStatus.yellow,
          deviation: 0,
          recommendation: 'Readiness Oura Moderata ($ouraScore). Procedi con cautela, riduci l\'intensità oggi.',
        );
      }
    }

    if (_lastSevenDayAvg <= 0) {
      return HRVAnalysis(
        status: ReadinessStatus.green,
        deviation: 0,
        recommendation: 'Inizia a misurare per vedere il tuo stato.',
      );
    }

    final deviation = ((currentRMSSD - _lastSevenDayAvg) / _lastSevenDayAvg) * 100;
    
    ReadinessStatus status;
    String recommendation;

    if (deviation >= -5) {
      status = ReadinessStatus.green;
      recommendation = deviation > 5 
        ? 'Ottimo! HRV elevata. Finestra ottimale per allenamento intenso.'
        : 'Pronto per allenarsi. Sistema parasimpatico recuperato.';
    } else if (deviation >= -15) {
      status = ReadinessStatus.yellow;
      recommendation = 'HRV leggermente depressa. Riduci volume 20% o intensità al 90%.';
    } else {
      status = ReadinessStatus.red;
      recommendation = 'Sistema parasimpatico soppresso. Recupero attivo o riposo completo.';
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
    final user = _supabase.auth.currentUser;

    if (user != null) {
      try {
        await _supabase.from('diary_entries').upsert({
          'id': '${user.id}_$dateStr',
          'athlete_id': user.id,
          'date': dateStr,
          'hrv': rmssd,
          'rhr': avgHR,
          'traffic_light': analysis.status.name.toUpperCase(),
          'deviation': analysis.deviation,
          'recommendation': analysis.recommendation,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Error saving HRV measurement: $e');
      }
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

    _lastSevenDayAvg = (_lastSevenDayAvg * 6 + rmssd) / 7;
    notifyListeners();
  }

  Future<void> updateFromOura(double rmssd, int score) async {
    final analysis = analyzeHRV(rmssd, ouraScore: score);
    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final user = _supabase.auth.currentUser;

    if (user != null) {
      try {
        await _supabase.from('diary_entries').upsert({
          'id': '${user.id}_$dateStr',
          'athlete_id': user.id,
          'date': dateStr,
          'hrv': rmssd,
          'readiness': score,
          'traffic_light': analysis.status.name.toUpperCase(),
          'deviation': analysis.deviation,
          'recommendation': analysis.recommendation,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Error saving Oura data: $e');
      }
    }

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
  }

  int calculateHRR(int hrEndWorkout, int hrOneMinAfter) {
    return hrEndWorkout - hrOneMinAfter;
  }
}
