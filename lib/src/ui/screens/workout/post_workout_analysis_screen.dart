import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../widgets/glass_card.dart';
import '../../../logic/fit_reader.dart';
import '../../../logic/analysis_engine.dart';
import '../../../services/settings_service.dart';
import '../../../l10n/app_localizations.dart';

class PostWorkoutAnalysisScreen extends StatefulWidget {
  final String fitFilePath;

  final String? workoutId;

  const PostWorkoutAnalysisScreen({super.key, required this.fitFilePath, this.workoutId});

  @override
  State<PostWorkoutAnalysisScreen> createState() => _PostWorkoutAnalysisScreenState();
}

class _PostWorkoutAnalysisScreenState extends State<PostWorkoutAnalysisScreen> {
  bool _isLoading = true;
  String? _error;
  int? _newFtp; // Detected FTP from test

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
    _analyzeWorkout();
  }

  Future<void> _analyzeWorkout() async {
    try {
      final data = await FitReader.readFitFile(widget.fitFilePath);
      
      final power = data['power']?.map((e) => e.toDouble()).toList() ?? [];
      final hr = data['heartRate']?.map((e) => e.toInt()).toList() ?? [];
      final cadence = data['cadence']?.map((e) => e.toInt()).toList() ?? [];
      final timestamps = data['timestamps']?.map((e) => e.toDouble()).toList() ?? [];

      if (power.isEmpty) throw Exception("No power data found");

      // Get User FTP
      if (!mounted) return;
      final ftp = context.read<SettingsService>().ftp.toDouble();

      // Computations
      final np = AnalysisEngine.calculateNP(power);
      final ifFactor = AnalysisEngine.calculateIF(np, ftp);
      final duration = power.length; // assuming 1hz
      final tss = AnalysisEngine.calculateTSS(np, ftp, duration);
      final peaks = AnalysisEngine.calculatePowerCurve(power);
      
      // Simple Calorie estimation (kJ -> kCal)
      final avgPower = power.reduce((a, b) => a + b) / power.length;
      final kCal = (avgPower * duration) / 4.184 / 0.24;

      // Test Protocol Logic
      int? calculatedFtp;
      if (widget.workoutId == 'ramp_test_01') {
          // Ramp Test: 75% of Best 1 Minute Power (MAP)
          if (peaks.containsKey('1m')) {
              calculatedFtp = (peaks['1m']! * 0.75).round();
          }
      } else if (widget.workoutId == 'ftp_test_20') {
          // 20 Min Test: 95% of Best 20 Minute Power
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
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: SafeArea(
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
              const SizedBox(height: 20), // Extra bottom padding
            ],
          ),
        ),
      ),
    );
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
