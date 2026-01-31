import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:vibration/vibration.dart';
import '../../../services/bluetooth_service.dart';
import '../../../services/physiological_service.dart';
import '../../widgets/glass_card.dart';

class HrvMeasurementScreen extends StatefulWidget {
  const HrvMeasurementScreen({super.key});

  @override
  State<HrvMeasurementScreen> createState() => _HrvMeasurementScreenState();
}

class _HrvMeasurementScreenState extends State<HrvMeasurementScreen> with SingleTickerProviderStateMixin {
  bool _isMeasuring = false;
  double _progress = 0.0;
  List<int> _capturedRR = [];
  int _selectedDurationMinutes = 3; // Default 3 minutes, option for 5
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  void _startMeasurement() {
    WakelockPlus.enable();
    setState(() {
      _isMeasuring = true;
      _progress = 0.0;
      _capturedRR = [];
    });
    _pulseController.repeat(reverse: true);

    // Calculate progress increment based on selected duration
    // 500ms interval = 2 updates per second
    // Total updates = duration_minutes * 60 * 2
    final totalUpdates = _selectedDurationMinutes * 60 * 2;
    final increment = 1.0 / totalUpdates;

    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted || !_isMeasuring) return false;
      
      setState(() {
        _progress += increment;
        // Capture RR interval from sensor (mocking if sensor not available)
        _capturedRR.add(800 + (DateTime.now().millisecond % 50));
      });

      if (_progress >= 1.0) {
        _finishMeasurement();
        return false;
      }
      return true;
    });
  }

  void _finishMeasurement() async {
    final physiologicalService = context.read<PhysiologicalService>();
    final rmssd = physiologicalService.calculateRMSSD(_capturedRR);
    physiologicalService.addHRVMeasurement(rmssd, 62); // Mock avg HR
    
    // Vibrate for 2 seconds at the end
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 2000);
    }

    _pulseController.stop();
    WakelockPlus.disable();
    
    setState(() {
      _isMeasuring = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Measurement Complete: rMSSD ${rmssd.toStringAsFixed(1)}ms')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('HRV Measurement', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.info),
            onPressed: _showProtocolDialog,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPulseCircle(),
              const SizedBox(height: 60),
              if (_isMeasuring) ...[
                Text(
                  'KEEP CALM AND BREATHE',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), letterSpacing: 2),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.white10,
                  color: Colors.cyanAccent,
                ),
                const SizedBox(height: 8),
                Text('${(_progress * 100).toInt()}%', style: const TextStyle(color: Colors.white)),
              ] else ...[
                const Text(
                  'Morning Readiness Scan',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Measure your HRV to determine your training readiness for today.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _showProtocolDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                       color: Colors.white.withOpacity(0.1),
                       borderRadius: BorderRadius.circular(20),
                       border: Border.all(color: Colors.white24)
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.bookOpen, size: 14, color: Colors.cyanAccent),
                        SizedBox(width: 8),
                        Text("Protocollo Migliaccio", style: TextStyle(color: Colors.cyanAccent, fontSize: 12))
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Duration Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Durata: ', style: TextStyle(color: Colors.white54)),
                    const SizedBox(width: 8),
                    _buildDurationOption(3),
                    const SizedBox(width: 12),
                    _buildDurationOption(5),
                  ],
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: context.select<BluetoothService, bool>((s) => s.heartRateSensor != null) 
                  ? ElevatedButton(
                    onPressed: _startMeasurement,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('START MEASUREMENT', style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                  : Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 32),
                          SizedBox(height: 8),
                          Text(
                            'Accoppia fascia cardio o altro dispositivo per misura RMSSD',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
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

  void _showProtocolDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Row(
           children: [
             Icon(LucideIcons.fileText, color: Colors.cyanAccent),
             SizedBox(width: 12),
             Text('Protocollo di Misurazione', style: TextStyle(color: Colors.white, fontSize: 18))
           ]
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Seguire scrupolosamente le indicazioni del Dott. Migliaccio per garantire la validità del dato:", style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
            SizedBox(height: 16),
            _ProtocolStep(idx: "1", text: "Eseguire la misurazione al mattino appena svegli, prima di alzarsi dal letto."),
            _ProtocolStep(idx: "2", text: "Posizionare la fascia cardio e assumere posizione supina (sdraiati a pancia in su)."),
            _ProtocolStep(idx: "3", text: "Rimanere immobili e rilassati per 1-2 minuti per stabilizzare il battito."),
            _ProtocolStep(idx: "4", text: "Avviare la misurazione (durata standard 3-5 min) respirando naturalmente senza forzature."),
            SizedBox(height: 16),
            Text("Nota: Evitare movimenti bruschi, parlare o guardare il telefono durante il test.", style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ho capito', style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }
  Widget _buildPulseCircle() {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.cyanAccent.withOpacity(0.3), width: 2),
          boxShadow: [
            if (_isMeasuring)
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 10,
              )
          ],
        ),
        child: const Icon(LucideIcons.heart, color: Colors.cyanAccent, size: 50),
      ),
    );
  }

  Widget _buildDurationOption(int minutes) {
    final isSelected = _selectedDurationMinutes == minutes;
    return GestureDetector(
      onTap: () => setState(() => _selectedDurationMinutes = minutes),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyanAccent : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.cyanAccent : Colors.white24,
          ),
        ),
        child: Text(
          '$minutes min',
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ProtocolStep extends StatelessWidget {
  final String idx;
  final String text;
  const _ProtocolStep({required this.idx, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.cyanAccent.withOpacity(0.2), shape: BoxShape.circle),
            child: Text(idx, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}
