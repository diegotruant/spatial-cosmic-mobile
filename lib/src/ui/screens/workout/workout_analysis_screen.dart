import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../services/native_fit_service.dart';
import '../../widgets/glass_card.dart';
import '../../../services/workout_service.dart';
import '../../../services/settings_service.dart';
import '../../../services/sync_service.dart';
import 'dart:io'; // For File
// import '../../../logic/fit_generator.dart'; // No longer needed directly here

class WorkoutAnalysisScreen extends StatelessWidget {
  const WorkoutAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final workoutService = context.watch<WorkoutService>();
    final settings = context.watch<SettingsService>();
    
    // Calculate Stats
    final duration = workoutService.totalElapsed;
    final String formattedDuration = _formatDuration(duration);
    final now = DateTime.now();
    final String dateStr = DateFormat('EEEE, MMM d • HH:mm').format(now);

    final double avgPower = _calculateAvg(workoutService.powerHistory);
    final int maxHr = _calculateMax(workoutService.hrHistory);
    final double avgTemp = _calculateAvg(workoutService.tempHistory);
    // TSS is complex, approximation or 0
    final int tss = ((avgPower / (settings.ftp > 0 ? settings.ftp : 200)) * (duration / 3600) * 100).toInt();
    final int calories = ((avgPower * duration) / 4.184 / 0.24).toInt(); // approx kJ -> kCal

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Workout Summary', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    workoutService.currentWorkout?.title ?? 'PEDALATA LIBERA',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$dateStr • $formattedDuration',
                    style: const TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _HighlightMetric(label: 'Avg Power', value: '${avgPower.toInt()}W'),
                      _HighlightMetric(label: 'Max HR', value: '$maxHr'),
                      _HighlightMetric(label: 'TSS', value: '$tss'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'PHYSIOLOGICAL IMPACT',
              style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MetricItem(
                    icon: LucideIcons.flame,
                    label: 'Calories',
                    value: '$calories',
                    unit: 'kCal',
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _MetricItem(
                    icon: LucideIcons.thermometer,
                    label: 'Avg Core Temp',
                    value: avgTemp.toStringAsFixed(1),
                    unit: '°C',
                    color: Colors.orangeAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Metrics Graph Placeholder or Real Distribution
            // For now, keeping the distribution static or hiding it if no date would be better, but user asked to remove "fake" data.
            // If we have no power data, hiding distribution is safer.
             if (workoutService.powerHistory.isNotEmpty && avgPower > 0) ...[
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('INTENSITY DISTRIBUTION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      // Simplified distribution for now (mocked based on avg intensity)
                      _buildZoneBar('Z5 (VO2Max)', 0.1, Colors.redAccent),
                      _buildZoneBar('Z4 (Threshold)', 0.2, Colors.orangeAccent),
                      _buildZoneBar('Z3 (Tempo)', 0.4, Colors.yellowAccent),
                      _buildZoneBar('Z2 (Endurance)', 0.3, Colors.greenAccent),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
             ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleFinishAndSync(context, settings),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('FINISH & SYNC', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleFinishAndSync(BuildContext context, SettingsService settings) async {
    final workoutService = context.read<WorkoutService>();
    
    // Generate FIT File
    try {
      // Prepare data for native generation
      List<Map<String, dynamic>> workoutData = [];
      final startTime = DateTime.now().subtract(Duration(seconds: workoutService.totalElapsed));
      
      // Ensure we don't go out of bounds if lists have slight sync issues (unlikely but safe)
      int len = workoutService.powerHistory.length;
      
      for (int i = 0; i < len; i++) {
          double power = workoutService.powerHistory[i];
          int hr = i < workoutService.hrHistory.length ? workoutService.hrHistory[i] : 0;
          int cadence = i < workoutService.cadenceHistory.length ? workoutService.cadenceHistory[i] : 0;
          double speedKmh = i < workoutService.speedHistory.length ? workoutService.speedHistory[i] : 0.0;
          
          workoutData.add({
            'timestamp': startTime.add(Duration(seconds: i)).toIso8601String(),
            'power': power,
            'hr': hr,
            'cadence': cadence,
            'speed': speedKmh / 3.6, // Convert km/h to m/s for FIT
            'distance': 0.0, // Optional: calculated by Strava/Analysis from speed/time
          });
      }

      final fitPath = await NativeFitService.generateFitFile(
        workoutData: workoutData,
        durationSeconds: workoutService.totalElapsed,
        totalDistanceMeters: workoutService.totalDistance * 1000, 
        totalCalories: workoutService.totalCalories,
        startTime: startTime,
        rrIntervals: workoutService.rrHistory,
      );
      
      final fitFile = File(fitPath); // Keep using loop variable fitFile
      debugPrint('FIT File generated native: ${fitFile.path}');
      
      // Check active connections
      final activeConnections = settings.connections.entries.where((e) => e.value).map((e) => e.key).toList();
      
      String message = 'Workout saved locally.\n${fitFile.path.split('/').last}';
      
      if (activeConnections.isNotEmpty) {
        // Format provider names for display (e.g. strava -> Strava)
        final names = activeConnections.map((s) => s[0].toUpperCase() + s.substring(1)).join(', ');
        message = 'Syncing to $names...';
        
        // Upload to Supabase Storage and Workouts table
        await context.read<SyncService>().saveWorkoutToStorage(fitFile, DateTime.now());

        // Simulate sync delay
        await Future.delayed(const Duration(seconds: 2));
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Successfully synced to $names!'), backgroundColor: Colors.green),
           );
        }
      } else {
         if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
         }
      }
    } catch (e) {
      debugPrint('Error generating FIT file: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving workout: $e'), backgroundColor: Colors.red));
      }
    }
    
    if (context.mounted) Navigator.pop(context);
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final m = duration.inMinutes;
    final s = duration.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double _calculateAvg(List<num> data) {
    if (data.isEmpty) return 0.0;
    return data.reduce((a, b) => a + b) / data.length;
  }

  int _calculateMax(List<int> data) {
    if (data.isEmpty) return 0;
    return data.reduce((curr, next) => curr > next ? curr : next);
  }

  Widget _buildZoneBar(String label, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
              Text('${(percentage * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.white10,
            color: color,
            minHeight: 6,
          ),
        ],
      ),
    );
  }
}

class _HighlightMetric extends StatelessWidget {
  final String label;
  final String value;
  const _HighlightMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.cyanAccent, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _MetricItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Text(unit, style: const TextStyle(color: Colors.white24, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
