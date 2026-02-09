import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../services/athlete_profile_service.dart';
import '../../../models/metabolic_profile.dart';
import '../../widgets/glass_card.dart';

/// METABOLIC LAB - Solo Visualizzazione Dati PDC
/// L'app NON calcola nulla, mostra solo i dati dal PDC (Supabase)
class MetabolicLabViewScreen extends StatefulWidget {
  const MetabolicLabViewScreen({super.key});

  @override
  State<MetabolicLabViewScreen> createState() => _MetabolicLabViewScreenState();
}

class _MetabolicLabViewScreenState extends State<MetabolicLabViewScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Auto-refresh all'apertura della schermata
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      // TODO: Implement loadFromSupabase method in AthleteProfileService
      // await context.read<AthleteProfileService>().loadFromSupabase();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Load from Supabase not yet implemented'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Errore ricaricamento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileService = context.watch<AthleteProfileService>();
    final metabolicProfile = profileService.metabolicProfile;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('METABOLIC LAB', style: TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 2)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.blueAccent, strokeWidth: 2),
                  )
                : const Icon(LucideIcons.refreshCw, color: Colors.blueAccent),
            onPressed: _isLoading ? null : _refreshData,
            tooltip: 'Ricarica dati da Supabase',
          ),
        ],
      ),
      body: metabolicProfile == null
          ? _buildNoDataView(context, profileService)
          : _buildDataView(context, metabolicProfile, profileService),
    );
  }

  Widget _buildNoDataView(BuildContext context, AthleteProfileService service) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GlassCard(
          padding: const EdgeInsets.all(32),
          borderRadius: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.flaskConical, color: Colors.white24, size: 64),
              const SizedBox(height: 24),
              const Text(
                'Nessun Profilo PDC',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Il tuo profilo metabolico verrà calcolato dal coach tramite il PDC Engine sul sito web.\n\nUna volta calcolato, apparirà automaticamente qui.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.6), height: 1.6),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _refreshData,
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('RICARICA DATI'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataView(BuildContext context, MetabolicProfile p, AthleteProfileService service) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Phenotype Card
       _buildPhenotypeCard(service),
        const SizedBox(height: 20),
        
        // Key Metrics
        _buildKeyMetrics(p),
        const SizedBox(height: 20),
        
        // Chart
        if (p.combustionCurve.isNotEmpty) _buildChartSection(p),
        const SizedBox(height: 20),
        
        // Info Footer
        GlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 12,
          child: Row(
            children: [
              const Icon(LucideIcons.info, color: Colors.blueAccent, size: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Dati calcolati dal PDC Engine (web). L\'app mobile visualizza solamente.',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhenotypeCard(AthleteProfileService service) {
    final phenotype = service.phenotypeLabel;
    
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 16,
      borderColor: Colors.blueAccent.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.target, color: Colors.blueAccent, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phenotype.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fenotipo Atleta',
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetrics(MetabolicProfile p) {
    return Column(
      children: [
        // FTP and MLSS Row
        Row(
          children: [
            Expanded(
              child: _buildMetricBox(
                label: 'FTP',
                value: '${p.advancedParams?.ftpEstimated.round() ?? p.map.round()} W',
                subtitle: '60 min power',
                color: Colors.yellowAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricBox(
                label: 'MLSS',
                value: '${p.mlss?.round() ?? p.metabolic.estimatedFtp.round()} W',
                subtitle: 'Soglia lattato',
                color: Colors.greenAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // MAP
        _buildMetricBox(
          label: 'MAP',
          value: '${p.map.round()} W',
          subtitle: 'VO2max Power',
          color: Colors.blueAccent,
          fullWidth: true,
        ),
        const SizedBox(height: 12),
        
        // VLamax and VO2max Row
        Row(
          children: [
            Expanded(
              child: _buildMetricBox(
                label: 'VLamax',
                value: '${p.vlamax.toStringAsFixed(2)}',
                subtitle: 'mmol/L/s',
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricBox(
                label: 'VO2max',
                value: '${p.vo2max.toStringAsFixed(1)}',
                subtitle: 'ml/min/kg',
                color: Colors.cyanAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricBox({
    required String label,
    required String value,
    required String subtitle,
    required Color color,
    bool fullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: fullWidth ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            subtitle.toUpperCase(),
            style: const TextStyle(
              color: Colors.white30,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(MetabolicProfile p) {
    final fatSpots = p.combustionCurve.map((c) => FlSpot(c.watt, c.fatOxidation)).toList();
    final carbSpots = p.combustionCurve.map((c) => FlSpot(c.watt, c.carbOxidation)).toList();

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade200),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, meta) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('${v.toInt()}W', style: const TextStyle(fontSize: 10)),
                ),
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: fatSpots,
              isCurved: true,
              color: Colors.orangeAccent,
              barWidth: 3,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.orangeAccent.withOpacity(0.2),
              ),
            ),
            LineChartBarData(
              spots: carbSpots,
              isCurved: true,
              color: Colors.blueAccent,
              barWidth: 3,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blueAccent.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
