import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../widgets/glass_card.dart';
import '../../../logic/fit_reader.dart';
import '../../../logic/analysis_engine.dart';
import '../../../services/settings_service.dart';
import '../../../services/sync_service.dart' as src;
import '../../../services/integration_service.dart';
import '../../../services/intervals_service.dart';
import '../../../l10n/app_localizations.dart';

class PostWorkoutAnalysisScreen extends StatefulWidget {
  final String fitFilePath;
  final String? workoutId;
  final bool isNewWorkout; // Flag to determine if we show Save/Discard controls

  const PostWorkoutAnalysisScreen({
    super.key, 
    required this.fitFilePath, 
    this.workoutId,
    this.isNewWorkout = false,
  });

  @override
  State<PostWorkoutAnalysisScreen> createState() => _PostWorkoutAnalysisScreenState();
}

class _PostWorkoutAnalysisScreenState extends State<PostWorkoutAnalysisScreen> {
  bool _isLoading = true;
  bool _isSaving = false; // For save button state
  String? _error;
  int? _newFtp; 

  // Data
  List<double> _power = [];
  List<int> _hr = [];
  List<int> _cadence = [];
  List<double> _timestamps = [];
  
  // Computed Metrics
  double _np = 0;
  double _tss = 0;
  double _if = 0;
  double _calories = 0;
  Map<String, double> _peaks = {};

  // Chart Toggles
  bool _showPower = true;
  bool _showHr = false;
  bool _showCadence = false;

  @override
  void initState() {
    super.initState();
    if (!File(widget.fitFilePath).existsSync()) {
       setState(() => _error = "File temporaneo non trovato: ${widget.fitFilePath}");
       _isLoading = false;
       return;
    }
    _analyzeWorkout();
  }

  Future<void> _analyzeWorkout() async {
    try {
      final data = await FitReader.readFitFile(widget.fitFilePath);
      
      final power = data['power']?.map((e) => e.toDouble()).toList() ?? [];
      final hr = data['heartRate']?.map((e) => e.toInt()).toList() ?? [];
      final cadence = data['cadence']?.map((e) => e.toInt()).toList() ?? [];
      final timestamps = data['timestamps']?.map((e) => e.toDouble()).toList() ?? [];
      
      // Prefer using Total Calories from FIT file if available in 'totalCalories' field
      // FitReader needs to support reading session messages for this. 
      // Assuming FitReader returns a flat map of record data for now.
      // If we upgraded FitReader to return Session info, we'd use that.
      // Fallback to calculation if not present.
      
      if (power.isEmpty) {
        // Handle empty file (e.g. 0 duration)
         setState(() {
           _isLoading = false;
         });
         return; 
      }

      // Get User FTP
      if (!mounted) return;
      final ftp = context.read<SettingsService>().ftp.toDouble();

      // Computations
      final np = AnalysisEngine.calculateNP(power);
      final ifFactor = AnalysisEngine.calculateIF(np, ftp);
      final duration = power.length; // assuming 1hz
      final tss = AnalysisEngine.calculateTSS(np, ftp, duration);
      final peaks = AnalysisEngine.calculatePowerCurve(power);
      
      // Calorie estimation
      // Use FIT 'total_calories' if we were parsing it. 
      // Since FitReader (custom) returns 'records' data primarily, we use our estimator or if we added it to the map.
      // Let's assume for now we stick to estimation unless we update FitReader.
      final avgPower = power.reduce((a, b) => a + b) / power.length;
      final kCal = (avgPower * duration) / 4.184 / 0.24;

      // Test Protocol Logic
      int? calculatedFtp;
      if (widget.workoutId == 'ramp_test_01') {
          if (peaks.containsKey('1m')) {
              calculatedFtp = (peaks['1m']! * 0.75).round();
          }
      } else if (widget.workoutId == 'ftp_test_20') {
          if (peaks.containsKey('20m')) {
              calculatedFtp = (peaks['20m']! * 0.95).round();
          }
      }

      setState(() {
        _power = power;
        _hr = hr;
        _cadence = cadence;
        _timestamps = timestamps;
        _np = np;
        _if = ifFactor;
        _tss = tss;
        _calories = kCal;
        _peaks = peaks;
        _newFtp = calculatedFtp;
        _isLoading = false;
      });
      
      if (calculatedFtp != null && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
             _showFtpResultDialog(calculatedFtp!);
          });
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: Center(child: Text('Errore analisi: $_error', style: const TextStyle(color: Colors.red))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('ANALISI WORKOUT', style: TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 1.5)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
             // If manual workflow, strict control? No, allow closing (defaults to discard? or just back?)
             // Better to force choice if it's new.
             if (widget.isNewWorkout) {
               _handleDiscard(context);
             } else {
               Navigator.of(context).pop();
             }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCards(),
                    const SizedBox(height: 24),
                    _buildChartSection(),
                    const SizedBox(height: 24),
                    _buildPowerCurveSection(),
                    const SizedBox(height: 100), // Space for bottom bar
                  ],
                ),
              ),
            ),
            if (widget.isNewWorkout) _buildSaveBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSaving ? null : () => _handleDiscard(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("SCARTA", style: TextStyle(color: Colors.redAccent)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSaving ? null : () => _handleSave(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving 
                   ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                   : const Text("SALVA UTENTE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave(BuildContext context) async {
    // Show filename dialog first
    final defaultName = widget.workoutId ?? 'workout_${DateTime.now().toIso8601String().split('T')[0]}';
    final customName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Nome Sessione', style: TextStyle(color: Colors.white)),
        content: TextFormField(
          initialValue: defaultName,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Inserisci nome sessione',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent),
            ),
          ),
          onFieldSubmitted: (value) => Navigator.pop(ctx, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () {
              // Get value from TextFormField - using default if empty
              Navigator.pop(ctx, defaultName);
            },
            child: const Text('Salva', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (customName == null || customName.isEmpty) return; // User cancelled

    setState(() => _isSaving = true);
    try {
      // Save and Sync with custom name
      final newPath = await context.read<src.SyncService>().saveAndSyncWorkout(
        widget.fitFilePath, 
        customName,
      );
      final newFile = File(newPath);

      // Trigger Exports
      final integrationService = context.read<IntegrationService>();
      final intervalsService = context.read<IntervalsService>();

      if (integrationService.isStravaConnected) {
         integrationService.uploadActivityToStrava(newFile).ignore();
      }
      if (intervalsService.isConnected) {
         intervalsService.uploadActivity(newFile).ignore();
      }

      if (mounted) {
        // Trigger Metabolic Recalculation if it was a metabolic test protocol
        final isMetabolicTest = widget.workoutId == 'pmax_slope_test' || 
                               widget.workoutId == 'flow_protocol_1' || 
                               widget.workoutId == 'flow_protocol_2';
        
        if (isMetabolicTest) {
          final profileService = context.read<src_profile.AthleteProfileService>();
          profileService.calculateMetabolicProfile(
            pMax: _peaks['5s'] ?? 0,
            mmp3: _peaks['3m'] ?? 0,
            mmp6: _peaks['6m'] ?? 0,
            mmp15: _peaks['15m'] ?? 0,
          );
          await profileService.applyMetabolicResult();
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text("Profilo Metabolico aggiornato automaticamente!"), backgroundColor: Colors.blueAccent)
             );
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Allenamento salvato con successo!"), backgroundColor: Colors.green));
        Navigator.of(context).popUntil((route) => route.isFirst); // Go to home
      }
    } catch (e) {
      if (mounted) {
         setState(() => _isSaving = false);
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Errore salvataggio: $e"), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _handleDiscard(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("Scarta Allenamento?", style: TextStyle(color: Colors.white)),
        content: const Text("Sei sicuro di voler eliminare questi dati? Questa azione è irreversibile.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Annulla")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("Elimina")
          ),
        ],
      ),
    );

    if (confirm == true) {
       try {
         final file = File(widget.fitFilePath);
         if (await file.exists()) {
           await file.delete();
         }
         if (context.mounted) {
           Navigator.of(context).popUntil((route) => route.isFirst);
         }
       } catch (e) {
         debugPrint("Error deleting temp file: $e");
       }
    }
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildMetricCard('TSS', _tss.toStringAsFixed(0), Colors.purpleAccent, LucideIcons.trophy)),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('IF', _if.toStringAsFixed(2), Colors.blueAccent, LucideIcons.activity)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMetricCard('NP', '${_np.toStringAsFixed(0)} W', Colors.orangeAccent, LucideIcons.zap)),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('CALORIE', _calories.toStringAsFixed(0), Colors.redAccent, LucideIcons.flame)),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, Color color, IconData icon) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          Icon(icon, color: color.withOpacity(0.5), size: 28),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('GRAFICO ANALISI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  _buildToggle('Pwr', Colors.orange, _showPower, () => setState(() => _showPower = !_showPower)),
                  const SizedBox(width: 8),
                  _buildToggle('HR', Colors.red, _showHr, () => setState(() => _showHr = !_showHr)),
                  const SizedBox(width: 8),
                  _buildToggle('Cad', Colors.blue, _showCadence, () => setState(() => _showCadence = !_showCadence)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  if (_showPower) _createLineData(_power, Colors.orangeAccent, 1.0),
                  if (_showHr) _createLineData(_hr.map((e) => e.toDouble()).toList(), Colors.redAccent, 0.5),
                  if (_showCadence) _createLineData(_cadence.map((e) => e.toDouble()).toList(), Colors.blueAccent, 0.5),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.toInt()}',
                          const TextStyle(color: Colors.white),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(String label, Color color, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: isActive ? color : Colors.white10),
        ),
        child: Text(label, style: TextStyle(color: isActive ? color : Colors.white54, fontSize: 10)),
      ),
    );
  }

  LineChartBarData _createLineData(List<double> data, Color color, double opacity) {
    // Smooth data (3s average) for chart
    final smoothed = AnalysisEngine.smoothData(data, 3);
    
    // Downsample if too many points to improve performance
    final step = (smoothed.length / 300).ceil(); // Max 300 points
    final List<FlSpot> spots = [];
    
    for (int i = 0; i < smoothed.length; i += step) {
      spots.add(FlSpot(i.toDouble(), smoothed[i]));
    }

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(show: true, color: color.withOpacity(0.1)),
    );
  }

  Widget _buildPowerCurveSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('POWER DURATION CURVE (PICCHI)', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildPeakCard('5 sec', _peaks['5s']?.toInt() ?? 0)),
            const SizedBox(width: 8),
            Expanded(child: _buildPeakCard('1 min', _peaks['1m']?.toInt() ?? 0)),
            const SizedBox(width: 8),
            Expanded(child: _buildPeakCard('5 min', _peaks['5m']?.toInt() ?? 0)),
            const SizedBox(width: 8),
            Expanded(child: _buildPeakCard('20 min', _peaks['20m']?.toInt() ?? 0)),
          ],
        ),
      ],
    );
  }
  
  void _showFtpResultDialog(int newFtp) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('RISULTATO TEST', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.trophy, color: Colors.yellowAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              "Nuova FTP Rilevata",
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            const SizedBox(height: 8),
            Text(
              "$newFtp W",
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              "Vuoi aggiornare il tuo profilo con questo nuovo valore?",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Ignora", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () {
               context.read<SettingsService>().setFtp(newFtp);
               Navigator.pop(ctx);
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text("FTP Aggiornata con successo!"), backgroundColor: Colors.green),
               );
            },
            child: const Text("Aggiorna FTP", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPeakCard(String label, int value) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      borderRadius: 12,
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
          const SizedBox(height: 8),
          Text('$value', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const Text('Watt', style: TextStyle(color: Colors.white30, fontSize: 8)),
        ],
      ),
    );
  }
}
