import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../services/bluetooth_service.dart';
import '../../../services/physiological_service.dart';
import '../../widgets/glass_card.dart';

class HrvMeasurementScreen extends StatefulWidget {
  const HrvMeasurementScreen({super.key});

  @override
  State<HrvMeasurementScreen> createState() => _HrvMeasurementScreenState();
}

class _HrvMeasurementScreenState extends State<HrvMeasurementScreen> {
  bool _isMeasuring = false;
  double _progress = 0.0;
  List<int> _capturedRR = [];

  void _startMeasurement() {
    setState(() {
      _isMeasuring = true;
      _progress = 0.0;
      _capturedRR = [];
    });

    // Simulate a 30-second measurement for demonstration
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted || !_isMeasuring) return false;
      
      setState(() {
        _progress += 0.016; // Approx for 30s
        // Mocking RR intervals if sensor not available
        _capturedRR.add(800 + (DateTime.now().millisecond % 50));
      });

      if (_progress >= 1.0) {
        _finishMeasurement();
        return false;
      }
      return true;
    });
  }

  void _finishMeasurement() {
    final physiologicalService = context.read<PhysiologicalService>();
    final rmssd = physiologicalService.calculateRMSSD(_capturedRR);
    physiologicalService.addHRVMeasurement(rmssd, 62); // Mock avg HR
    
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

  Widget _buildPulseCircle() {
    return Container(
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
    );
  }
}
