import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../services/athlete_profile_service.dart';
import '../../../services/settings_service.dart';
import '../../../models/metabolic_profile.dart';
import '../../widgets/glass_card.dart';

class MetabolicCalculatorScreen extends StatefulWidget {
  const MetabolicCalculatorScreen({super.key});

  @override
  State<MetabolicCalculatorScreen> createState() => _MetabolicCalculatorScreenState();
}

class _MetabolicCalculatorScreenState extends State<MetabolicCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();

  // Biometrics
  late TextEditingController _weightController;
  late TextEditingController _bodyFatController;
  String _somatotype = 'ectomorph';
  String _level = 'amateur';
  String _gender = 'male';

  // Performance
  late TextEditingController _pMaxController;
  late TextEditingController _mmp3Controller;
  late TextEditingController _mmp6Controller;
  late TextEditingController _mmp12Controller;

  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    final service = context.read<AthleteProfileService>();

    // Load defaults from service
    _weightController = TextEditingController(text: (service.weight ?? 75).toString());
    _bodyFatController = TextEditingController(text: (service.bodyFat ?? 12).toString());
    _somatotype = service.somatotype;
    _level = service.athleteLevel;
    _gender = service.gender;

    // Default performance values
    _pMaxController = TextEditingController(text: ''); 
    _mmp3Controller = TextEditingController(text: '');
    _mmp6Controller = TextEditingController(text: '');
    _mmp12Controller = TextEditingController(text: '');

    // Persistence: if a profile already exists, show it
    if (service.metabolicProfile != null) {
      _showResults = true;
      
      // Auto-scroll to results after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Scrollable.ensureVisible(context, alignment: 1.0, duration: const Duration(milliseconds: 500));
        }
      });
    }
  }
  
  @override
  void dispose() {
    _weightController.dispose();
    _bodyFatController.dispose();
    _pMaxController.dispose();
    _mmp3Controller.dispose();
    _mmp6Controller.dispose();
    _mmp12Controller.dispose();
    super.dispose();
  }

  void _runCalculation() {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      double parse(String text) {
        return double.parse(text.replaceAll(',', '.').trim());
      }

      final double weight = parse(_weightController.text);
      final double bf = parse(_bodyFatController.text);
      final double pMax = parse(_pMaxController.text);
      final double mmp3 = parse(_mmp3Controller.text);
      final double mmp6 = parse(_mmp6Controller.text);
      final double mmp12 = parse(_mmp12Controller.text);

      context.read<AthleteProfileService>().calculateMetabolicProfile(
        pMax: pMax,
        mmp3: mmp3,
        mmp6: mmp6,
        mmp15: mmp12,
        customWeight: weight,
        customBodyFat: bf,
        customSomatotype: _somatotype,
        customAthleteLevel: _level,
        customGender: _gender,
      );

      setState(() {
        _showResults = true;
      });
      
      // Auto scroll to results
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          Scrollable.ensureVisible(context, alignment: 1.0, duration: const Duration(milliseconds: 500));
        }
      });
      
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nei dati inseriti: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveAndApply() async {
    try {
      await context.read<AthleteProfileService>().applyMetabolicResult();
      
      // Auto-update FTP in SettingsService to reflect changes immediately
      final profile = context.read<AthleteProfileService>();
      if (profile.metabolicProfile != null) {
         final newFtp = profile.metabolicProfile!.metabolic.estimatedFtp.round();
         context.read<SettingsService>().setFtp(newFtp); // This updates Prefs + UI + DB
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Zone Metaboliche, Profilo e FTP salvati con successo!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore salvataggio: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<AthleteProfileService>();
    final results = service.metabolicProfile;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate 900
      appBar: AppBar(
        title: const Text('Metabolic Engine v4.0', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildInputSection(),
              const SizedBox(height: 32),
              
              if (_showResults && results != null) ...[
                const Divider(color: Colors.white10),
                const SizedBox(height: 24),
                _buildResultsHeader(),
                const SizedBox(height: 24),
                _buildKeyMetrics(results),
                const SizedBox(height: 24),
                _buildChartSection(results),
                const SizedBox(height: 24),
                _buildZonesTable(results),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveAndApply,
                    icon: const Icon(LucideIcons.save, size: 20),
                    label: const Text("SALVA E AGGIORNA ZONE"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigoAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      textStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.indigoAccent, borderRadius: BorderRadius.circular(16)),
          child: const Text("AG", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("ANALIZZATORE SOMATOTIPO", style: TextStyle(color: Colors.indigoAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const Text("Configurazione Test", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
          ],
        )
      ],
    );
  }

  Widget _buildInputSection() {
    return Column(
      children: [
        // Basic Biometrics Row
        Row(
          children: [
            Expanded(child: _buildTextField(_weightController, "Peso (kg)", LucideIcons.scale)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField(_bodyFatController, "Body Fat %", LucideIcons.percent)),
          ],
        ),
        const SizedBox(height: 12),
        // Dropdowns
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _somatotype,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              isExpanded: true,
              icon: const Icon(LucideIcons.chevronDown, color: Colors.white54),
              items: const [
                DropdownMenuItem(value: 'ectomorph', child: Text("Ectomorfo (Longilineo)")),
                DropdownMenuItem(value: 'mesomorph', child: Text("Mesomorfo (Atletico)")),
                DropdownMenuItem(value: 'endomorph', child: Text("Endomorfo (Robusto)")),
              ],
              onChanged: (v) => setState(() => _somatotype = v!),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _level,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    isExpanded: true,
                    icon: const Icon(LucideIcons.chevronDown, size: 16, color: Colors.white54),
                    items: const [
                      DropdownMenuItem(value: 'amateur', child: Text("AMATORE")),
                      DropdownMenuItem(value: 'pro', child: Text("PRO / ELITE")),
                    ],
                    onChanged: (v) => setState(() => _level = v!),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _gender,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    isExpanded: true,
                    icon: const Icon(LucideIcons.chevronDown, size: 16, color: Colors.white54),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text("UOMO")),
                      DropdownMenuItem(value: 'female', child: Text("DONNA")),
                    ],
                    onChanged: (v) => setState(() => _gender = v!),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        const Text("Dati Potenza (Test)", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        
        _buildTextField(_pMaxController, "Pmax (Sprint 1s) (W)", LucideIcons.zap, color: Colors.indigoAccent),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTextField(_mmp3Controller, "MMP 3 min (W)", LucideIcons.timer)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField(_mmp6Controller, "MMP 6 min (W)", LucideIcons.timer)),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField(_mmp12Controller, "MMP 15 min (W) [Test FLOW 1]", LucideIcons.timer),

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _runCalculation,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text("CALCOLA PROFILO", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
          ),
        )
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {Color? color}) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: TextStyle(color: color ?? Colors.white, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.normal),
          border: InputBorder.none,
          icon: Icon(icon, size: 18, color: color ?? Colors.white30),
        ),
        validator: (v) => v!.isEmpty ? 'Richiesto' : null,
      ),
    );
  }

  Widget _buildConfidenceIndicator(MetabolicProfile p) {
    final conf = p.confidenceScore ?? 0.5;
    final color = conf > 0.8 ? Colors.greenAccent : conf > 0.6 ? Colors.orangeAccent : Colors.redAccent;
    final label = conf > 0.8 ? "ALTA" : conf > 0.6 ? "MEDIA" : "LIMITATA";

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("AFFIDABILITÀ STIMA", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.black, letterSpacing: 1)),
              Text("$label (${(conf * 100).toInt()}%)", style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.black)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: conf,
              backgroundColor: Colors.white10,
              color: color,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Basata sulla completezza dei test MMP/Sprint inseriti.",
            style: TextStyle(color: Colors.white30, fontSize: 9, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildScientificDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: const Column(
        children: [
          Icon(LucideIcons.shieldCheck, color: Colors.white24, size: 24),
          SizedBox(height: 12),
          Text(
            "METODOLOGIA E RESPONSABILITÀ",
            style: TextStyle(color: Colors.white54, fontWeight: FontWeight.black, fontSize: 10, letterSpacing: 1),
          ),
          SizedBox(height: 8),
          Text(
            "Questo profilo è generato da un modello matematico predittivo. Le metriche sono STIME MODELLATE e non sostituiscono test clinici di laboratorio. L'uso dei dati è a scopo informativo per l'allenamento.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white30, fontSize: 10, height: 1.5),
          ),
          SizedBox(height: 12),
          Text(
            "\"Meglio un modello dichiarato che una falsa precisione.\"",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.indigoAccent, fontSize: 10, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader() {
    return const Center(
      child: Column(
        children: [
          Text("MODELLO PREDITTIVO v4.2", style: TextStyle(color: Colors.indigoAccent, fontSize: 10, fontWeight: FontWeight.black, letterSpacing: 2)),
          SizedBox(height: 4),
          Text("RISULTATI ANALISI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.5)),
        ],
      ),
    );
  }

  Widget _buildKeyMetrics(MetabolicProfile p) {
     return Column(
       children: [
         Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.indigoAccent, borderRadius: BorderRadius.circular(24)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("VLamax", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        const Icon(LucideIcons.database, color: Colors.white24, size: 12),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(p.vlamax.toStringAsFixed(3), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                    const Text("mmol/L/s [STIMA]", style: TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("VO2max", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        const Icon(LucideIcons.database, color: Colors.white24, size: 12),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(p.vo2max.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                    const Text("ml/min/kg [STIMA]", style: TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.indigoAccent.withOpacity(0.3), width: 1)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("BMR / TDEE", style: TextStyle(color: Colors.indigoAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text("${p.tdee?.round() ?? '---'} kcal", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                    Text("BMR: ${p.bmr?.round() ?? '---'} kcal", style: const TextStyle(color: Colors.white30, fontSize: 10)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // W' (APR) Box
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.orangeAccent.withOpacity(0.3), width: 1)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                   const Text("APR (W')", style: TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text("${((p.wPrime ?? 0) / 1000).toStringAsFixed(1)} kJ", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                    Text("${(p.wPrime ?? 0).toInt()} J", style: const TextStyle(color: Colors.white30, fontSize: 10)),
                  ],
                ),
              ),
            ),
          ],
        ),
       ],
     );
  }

  Widget _buildChartSection(MetabolicProfile p) {
    // Convert combustion curve to spots
    final fatSpots = p.combustionCurve.map((c) => FlSpot(c.watt, c.fatOxidation)).toList();
    final carbSpots = p.combustionCurve.map((c) => FlSpot(c.watt, c.carbOxidation)).toList();

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade200)),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 22, interval: 50, getTitlesWidget: (v, m) => Text("${v.toInt()}", style: const TextStyle(color: Colors.grey, fontSize: 10)))),
          ),
          borderData: FlBorderData(show: false),
          minX: 50,
          maxX: p.map * 1.1,
          minY: 0,
          maxY: 100,
          lineBarsData: [
            // Fat Line
            LineChartBarData(
              spots: fatSpots,
              isCurved: true,
              color: Colors.green,
              barWidth: 4,
              dotData: FlDotData(show: false),
            ),
            // Carb Line
            LineChartBarData(
              spots: carbSpots,
              isCurved: true,
              color: Colors.orange,
              barWidth: 4,
              dotData: FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZonesTable(MetabolicProfile p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: p.zones.map((z) {
          // Parse color string to Color?
          // The model has "text-emerald-600". We need to map custom.
          Color c = Colors.grey;
          if (z.color.contains('emerald') || z.color.contains('green')) c = Colors.green;
          if (z.color.contains('blue')) c = Colors.blue;
          if (z.color.contains('orange')) c = Colors.orange;
          if (z.color.contains('red')) c = Colors.red;

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(z.name.toUpperCase(), style: TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 13)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(z.range, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                ),
                Expanded(
                  flex: 1,
                  child: Text(z.fuel, textAlign: TextAlign.right, style: const TextStyle(color: Colors.grey, fontSize: 10, fontStyle: FontStyle.italic)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
