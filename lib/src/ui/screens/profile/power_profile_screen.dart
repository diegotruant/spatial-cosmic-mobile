import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

import '../../../services/athlete_profile_service.dart';
import '../../../services/settings_service.dart';
import '../../../models/metabolic_profile.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';

class PowerProfileScreen extends StatelessWidget {
  const PowerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Power Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer2<AthleteProfileService, SettingsService>(
        builder: (context, profile, settings, child) {
          final mp = profile.metabolicProfile;
          if (mp == null || mp.pdcCurve.isEmpty) {
            return const Center(
              child: Text(
                'Nessun dato di potenza disponibile.\nEsegui un test o attendi l\'analisi.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          final weight = settings.weight.toDouble() > 0 ? settings.weight.toDouble() : 70.0;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                SizedBox(
                  height: 350,
                  child: _buildRadarChart(context, mp.pdcCurve, weight),
                ),
                const SizedBox(height: 40),
                _buildMetricsList(mp.pdcCurve, weight),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRadarChart(BuildContext context, List<PDCPoint> curve, double weight) {
    // 1. Definisci i punti e i relativi massimi popolari (W/kg)
    final pointsConfig = [
      {'label': '5s', 'duration': 5, 'max': 24.0},
      {'label': '30s', 'duration': 30, 'max': 11.5},
      {'label': '1m', 'duration': 60, 'max': 10.5},
      {'label': '5m', 'duration': 300, 'max': 7.2},
      {'label': '10m', 'duration': 600, 'max': 6.5},
      {'label': '20m', 'duration': 1200, 'max': 5.8},
      {'label': '60m', 'duration': 3600, 'max': 5.0},
    ];

    List<RadarDataSet> dataSets = [
      RadarDataSet(
        fillColor: Colors.blueAccent.withOpacity(0.2),
        borderColor: Colors.blueAccent,
        entryRadius: 3,
        dataEntries: pointsConfig.map((config) {
          final duration = config['duration'] as int;
          final maxWkg = config['max'] as double;
          
          final wkg = _getWkgAt(curve, duration, weight);
          // Normalizza da 0 a 100
          double normalized = (wkg / maxWkg) * 100.0;
          if (normalized > 100) normalized = 100;
          
          return RadarEntry(value: normalized);
        }).toList(),
      )
    ];

    return RadarChart(
      RadarChartData(
        titlePositionMultiplier: 1.2,
        tickCount: 5,
        ticksTextStyle: const TextStyle(color: Colors.transparent),
        gridBorderData: const BorderSide(color: Colors.white12, width: 1.5),
        radarBorderData: const BorderSide(color: Colors.transparent),
        tickBorderData: const BorderSide(color: Colors.white12, width: 1),
        radarShape: RadarShape.polygon,
        radarBackgroundColor: Colors.transparent,
        dataSets: dataSets,
        getTitle: (index, angle) {
          final config = pointsConfig[index];
          return RadarChartTitle(
            text: config['label'] as String,
            angle: 0,
          );
        },
        titleTextStyle: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
      ),
      swapAnimationDuration: const Duration(milliseconds: 150),
      swapAnimationCurve: Curves.linear,
    );
  }

  Widget _buildMetricsList(List<PDCPoint> curve, double weight) {
    final pointsConfig = [
      {'label': 'Sprint (5s)', 'duration': 5},
      {'label': 'Anaerobico (1m)', 'duration': 60},
      {'label': 'VO2 Max (5m)', 'duration': 300},
      {'label': 'Soglia (20m)', 'duration': 1200},
      {'label': 'Resistenza (60m)', 'duration': 3600},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dettaglio Profilo',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...pointsConfig.map((config) {
          final duration = config['duration'] as int;
          final label = config['label'] as String;
          final watts = _getWattsAt(curve, duration);
          final wkg = watts / weight;
          
          return GlassCard(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            borderRadius: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 15)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${watts.round()} W', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('${wkg.toStringAsFixed(2)} W/kg', style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  double _getWattsAt(List<PDCPoint> curve, int duration) {
    if (curve.isEmpty) return 0.0;
    
    // Find exact
    PDCPoint? exact;
    try {
      exact = curve.lastWhere((p) => p.duration == duration);
    } catch (_) {
      exact = null;
    }
    if (exact != null) return exact.watts;

    // Sort a copy
    final sorted = List<PDCPoint>.from(curve)..sort((a, b) => a.duration.compareTo(b.duration));
    
    PDCPoint? prev;
    PDCPoint? next;
    
    for (var p in sorted) {
      if (p.duration < duration) {
        prev = p;
      } else if (p.duration > duration) {
        next = p;
        break;
      }
    }
    
    if (prev != null && next != null) {
      final logD = math.log(duration);
      final logPrev = math.log(prev.duration);
      final logNext = math.log(next.duration);
      final ratio = (logD - logPrev) / (logNext - logPrev);
      return prev.watts + (next.watts - prev.watts) * ratio;
    }
    
    if (prev != null) return prev.watts;
    if (next != null) return next.watts;
    return 0.0;
  }

  double _getWkgAt(List<PDCPoint> curve, int duration, double weight) {
    if (weight <= 0) return 0.0;
    return _getWattsAt(curve, duration) / weight;
  }
}
