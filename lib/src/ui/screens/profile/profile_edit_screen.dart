import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/athlete_profile_service.dart';
import '../../widgets/glass_card.dart';
import 'package:intl/intl.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _leanMassController;
  
  DateTime? _selectedDob;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final profileService = context.read<AthleteProfileService>();
    final p = profileService.currentProfile;
    
    _weightController = TextEditingController(text: p.weight?.toString() ?? '');
    _heightController = TextEditingController(text: p.height?.toString() ?? '');
    _leanMassController = TextEditingController(text: p.leanMass?.toString() ?? '');
    _ftpController = TextEditingController(text: p.ftp?.toString() ?? '');
    _cpController = TextEditingController(text: p.cp?.toString() ?? '');
    _wPrimeController = TextEditingController(text: p.wPrime?.toString() ?? '');
    _selectedDob = p.dob;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _leanMassController.dispose();
    super.dispose();
  }

  String _formatDob(DateTime? date) {
    if (date == null) return 'Seleziona data';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(now.year - 30),
      firstDate: DateTime(1920),
      lastDate: now,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.blueAccent,
            surface: Color(0xFF1A1A2E),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDob = picked);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final double? weight = double.tryParse(_weightController.text);
      final double? height = double.tryParse(_heightController.text);
      final double? leanMass = double.tryParse(_leanMassController.text);

      await context.read<AthleteProfileService>().updateProfile(
        weight: weight,
        height: height,
        leanMass: leanMass,
        ftp: ftp,
        cp: cp,
        wPrime: wPrime,
        dob: _selectedDob,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profilo aggiornato con successo')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore aggiornamento: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Modifica Profilo', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Dati Biometrici",
                style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Questi dati sono fondamentali per il calcolo accurato del VLamax e delle zone di allenamento.",
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 20),
              
              _buildTextField(
                controller: _weightController,
                label: "Peso (kg)",
                icon: Icons.monitor_weight,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _heightController,
                label: "Altezza (cm)",
                icon: Icons.height,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _leanMassController,
                label: "Massa Magra (kg) - Opzionale",
                icon: Icons.fitness_center,
                keyboardType: TextInputType.number,
                helperText: "Lascia vuoto se non conosciuto. Verrà stimato dal peso.",
              ),
              const SizedBox(height: 16),
              
              // Date of Birth with DatePicker
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: InkWell(
                  onTap: _pickDate,
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.blueAccent),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Data di Nascita",
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDob(_selectedDob),
                              style: TextStyle(
                                color: _selectedDob != null ? Colors.white : Colors.white38,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.white38),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              const Text(
                "Parametri di Analisi",
                style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Configura la tua Critical Power (CP) e W' Prime per un calcolo accurato del W' Balance.",
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 20),
              
              _buildTextField(
                controller: _ftpController,
                label: "FTP (Watt)",
                icon: Icons.bolt,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _cpController,
                label: "Critical Power (Watt)",
                icon: Icons.speed,
                keyboardType: TextInputType.number,
                helperText: "Se non noto, usa lo stesso valore dell'FTP.",
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _wPrimeController,
                label: "W' Prime (Joules)",
                icon: Icons.battery_charging_full,
                keyboardType: TextInputType.number,
                helperText: "Tipicamente tra 10000 e 25000.",
              ),
              
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("SALVA MODIFICHE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? helperText,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          helperText: helperText,
          helperStyle: const TextStyle(color: Colors.white24),
          icon: Icon(icon, color: Colors.blueAccent),
          border: InputBorder.none,
        ),
        validator: (value) {
           // Basic validation
           if (label.contains("Peso") || label.contains("Altezza")) {
             if (value == null || value.isEmpty) return "Campo obbligatorio";
           }
           return null;
        },
      ),
    );
  }
}
